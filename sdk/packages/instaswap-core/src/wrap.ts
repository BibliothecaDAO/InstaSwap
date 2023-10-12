import {
    AccountInterface,
    BigNumberish,
    cairo,
    Call,
    CallData,
    constants,
    Contract,
    InvokeFunctionResponse,
    num,
    Provider
} from 'starknet';
import ERC1155 from "./abi/erc1155-abi.json";
import Quoter from "./abi/quoter-abi.json";
import {AVNU_SQRT_RATIO, FeeAmount, MAX_SQRT_RATIO, MIN_SQRT_RATIO, SwapDirection} from './constants';
import {AVNUSwapParams, Config, LiquidityParams, SimpleSwapParams} from './types';
import {Decimal} from 'decimal.js-light';
import {getTickAtSqrtRatio } from './tickMath';

export class Wrap {

    public static ERC1155Address: string;
    public static WERC20Address: string;
    public static ERC20Address: string;
    public static EkuboPositionAddress: string;
    public static EkuboCoreAddress: string;

    public static ERC1155Contract: Contract;
    public static QuoterContract: Contract;

    public static SortedTokens:string[];
    public static ERC1155ApproveCall:Call;
    public static CancelERC1155ApproveCall:Call;

    private static account:AccountInterface;


    constructor(config:Config) {
        //default provider
        const provider         = config.provider ? config.provider : new Provider({ sequencer: { network: constants.NetworkName.SN_MAIN } });
        Wrap.ERC1155Contract   = new Contract(ERC1155, config.erc1155Address, provider);
        Wrap.QuoterContract    = new Contract(Quoter, config.quoterAddress, provider);

        //addresses
        Wrap.ERC1155Address       = config.erc1155Address;
        Wrap.WERC20Address        = config.werc20Address;
        Wrap.ERC20Address         = config.erc20Address;
        Wrap.EkuboPositionAddress = config.ekuboPositionAddress;
        Wrap.EkuboCoreAddress     = config.ekuboCoreAddress;


        Wrap.SortedTokens      = [Wrap.ERC20Address, Wrap.WERC20Address].sort((a, b) => a.localeCompare(b));

        Wrap.ERC1155ApproveCall = {
            contractAddress: Wrap.ERC1155Address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Address,
                approved: num.toCairoBool(true)
            })
        };

        Wrap.CancelERC1155ApproveCall =  {
            contractAddress: Wrap.ERC1155Address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Address,
                approved: num.toCairoBool(false)
            })
        };
        if ( config.account ){
            Wrap.account = config.account;
        }
        Decimal.set({ precision: 78 });
    }

    private static createDepositCall(contract:string,amount:BigNumberish):Call{
        return {
            contractAddress: contract,
            entrypoint: "deposit",
            calldata: CallData.compile({
                amount: cairo.uint256(amount)
            })
        }
    }


    private static createTransferCall(contract:string,recipient:string,amount:BigNumberish):Call{
        return {
            contractAddress: contract,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: recipient,
                amount: cairo.uint256(amount) // wrap token has 18 decimals
            })
        }
    }


    private static createClearCall(contract:string,token:string):Call{
        return {
            contractAddress: contract,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: token
            })
        }
    }

    private static createWERC20ApproveCall(spender:string,amount:BigNumberish):Call{
        return {
            contractAddress: Wrap.WERC20Address,
            entrypoint: "approve",
            calldata: CallData.compile({
                spender: spender,
                amount: cairo.uint256(amount)
            })
        }
    }

    private static checkAccount(){
        if (!Wrap.account){
            throw new Error("slippage should be between 0 and 1");
        }
    }



    public mayInitializePool = (fee: FeeAmount, initial_tick: { mag: BigNumberish, sign: boolean }):Promise<InvokeFunctionResponse> => {

        const mayInitializePool: Call = {
            contractAddress: Wrap.EkuboCoreAddress,
            entrypoint: "maybe_initialize_pool",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0],
                    token1: Wrap.SortedTokens[1],
                    fee: Wrap.getFeeX128(fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                initial_tick
            })
        }

        return Wrap.account.execute([mayInitializePool]);
    }




    public addLiquidity = async (params:LiquidityParams): Promise<InvokeFunctionResponse> =>{

        Wrap.checkAccount();
        const lowerSqrtRatioX128 = new Decimal(params.lowerPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        const upperSqrtRatioX128 = new Decimal(params.upperPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        const lowerTick = getTickAtSqrtRatio(BigInt(lowerSqrtRatioX128));
        const upperTick = getTickAtSqrtRatio(BigInt(upperSqrtRatioX128));
        if (lowerTick > upperTick) {
            throw new Error("lowerTick should be less than upperTick");
        }

        /**
         * create needed contract calls
         * mint_and_deposit
         */
        const mintAndDeposit: Call = {
            contractAddress: Wrap.EkuboPositionAddress,
            entrypoint: "mint_and_deposit",
            calldata: CallData.compile(
                {
                    pool_key: {
                        token0: Wrap.SortedTokens[0],
                        token1: Wrap.SortedTokens[1],
                        fee: Wrap.getFeeX128(params.fee),
                        tick_spacing: 200,
                        extension: 0,
                    },
                    bounds: {
                        lower: {
                            mag: 50000000n,
                            sign: lowerTick < 0,
                        },
                        upper: {
                            mag: 50000000n,
                            sign: upperTick < 0,
                        }
                    },
                    min_liquidity: 2000,
                }
            )
        }


        return Wrap.account.execute([
                    Wrap.ERC1155ApproveCall,
                    Wrap.createDepositCall(Wrap.WERC20Address,params.erc1155Amount),
                    Wrap.createTransferCall(Wrap.WERC20Address,Wrap.EkuboPositionAddress,
                        BigInt(params.erc1155Amount) * (BigInt(10) ** BigInt(18))),
                    Wrap.createTransferCall(Wrap.ERC20Address,Wrap.EkuboPositionAddress,BigInt(params.erc20Amount)),
                    mintAndDeposit,
                    Wrap.createClearCall(Wrap.EkuboPositionAddress,Wrap.WERC20Address),
                    Wrap.createClearCall(Wrap.EkuboPositionAddress,Wrap.ERC20Address),
                    Wrap.CancelERC1155ApproveCall
        ]);
    }

    public withdraw(id: number):Call[]{
        return [];
    }

    public  quoteSingle = async (fee: FeeAmount, specified_token: string, amount: bigint): Promise<number> => {

        try {

            return await Wrap.QuoterContract.quote_single({
                amount: {
                    mag: amount,
                    sign: false
                },
                specified_token: specified_token,
                pool_key: {
                    token0: Wrap.SortedTokens[0],
                    token1: Wrap.SortedTokens[1],
                    fee: Wrap.getFeeX128(fee),
                    tick_spacing: 200,
                    extension: 0,
                },
            });
        } catch (error: any) {
            let inputString = error.toString();
            const substringToFind = "0x3f532df6e73f94d604f4eb8c661635595c91adc1d387931451eacd418cfbd14";
            const substringStartIndex = inputString.indexOf(substringToFind);

            if (substringStartIndex !== -1) {
                const startIndex = substringStartIndex + substringToFind.length + 2; // Skip the substring and the following comma and whitespace
                const endIndex = inputString.indexOf(",", startIndex);
                return inputString.substring(startIndex, endIndex).trim();
            }

            return 0;
        }
    }




    public swapSimple = async (direction:SwapDirection,params:SimpleSwapParams): Promise<InvokeFunctionResponse> => {
        if (direction == SwapDirection.ERC1155_TO_ERC20){
            return await this.swapFromERC1155ToERC20(params);
        }
        return await this.swapFromERC20ToERC1155(params);
    }


    public swapFromERC1155ToERC20ByAVNU = async (params:AVNUSwapParams): Promise<InvokeFunctionResponse> => {

        if (params.slippage < 0 || params.slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }


        const werc20AmountIn = BigInt(params.erc1155AmountIn.toString()) * BigInt(10 ** 18);

        /**
         * swap
         */
        const multiRouteSwap: Call = {
            contractAddress: params.aggregatorAddress,
            entrypoint: "multi_route_swap",
            calldata: CallData.compile({
                token_from_address: Wrap.WERC20Address,
                token_from_amount: cairo.uint256(werc20AmountIn),
                token_to_address: Wrap.ERC20Address,
                token_to_amount: cairo.uint256(params.minERC20AmountOut), // this is useless in avnu contract
                token_to_min_amount: cairo.uint256(params.minERC20AmountOut),
                beneficiary: params.userAddress,
                integrator_fee_amount_bps: 0,
                integrator_fee_recipient: 0,
                routes: [
                    {
                        token_from: Wrap.WERC20Address,
                        token_to: Wrap.ERC20Address,
                        exchange_address: Wrap.EkuboCoreAddress,
                        percent: 100,
                        additional_swap_params: [
                            Wrap.SortedTokens[0],
                            Wrap.SortedTokens[1],
                            Wrap.getFeeX128(params.fee),  //fee for determin the pool_key
                            200, // tick_spacing for determin the pool_key
                            0, // extension for determin the pool_key
                            AVNU_SQRT_RATIO//sqrt_ratio_limit
                        ],
                    }
                ]
            })
        }
        return Wrap.account.execute( [
                    Wrap.ERC1155ApproveCall,
                    Wrap.createDepositCall(Wrap.WERC20Address,params.erc1155AmountIn),
                    Wrap.createWERC20ApproveCall(params.aggregatorAddress,werc20AmountIn),
                    multiRouteSwap
        ]);
    }


    public swapFromERC1155ToERC20 = async (params:SimpleSwapParams): Promise<InvokeFunctionResponse> => {

        if (params.slippage < 0 || params.slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }

        const werc20AmountIn = BigInt(params.amountIn.toString()) * BigInt(10 ** 18);


        const sqrt_ratio_limit = !(Wrap.ERC20Address > Wrap.WERC20Address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;

        // swap
        const simpleSwap: Call = {
            contractAddress: params.simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0],
                    token1: Wrap.SortedTokens[1],
                    fee: Wrap.getFeeX128(params.fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                swap_params: {
                    amount: {
                        mag: werc20AmountIn,
                        sign: false
                    },
                    is_token1: !(Wrap.ERC20Address > Wrap.WERC20Address),
                    sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                    skip_ahead: 4294967295,
                },
                recipient: params.userAddress,
                calculated_amount_threshold: 0,
            })
        }

        return Wrap.account.execute( [
            Wrap.ERC1155ApproveCall,
            Wrap.createDepositCall(Wrap.WERC20Address,params.amountIn),
            Wrap.createTransferCall(Wrap.WERC20Address,params.simpleSwapperAddress,
                BigInt(params.amountIn) * (BigInt(10 ** 18))),
            simpleSwap,
            Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[0]),
            Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[1]),
        ]);
    }


    public swapFromERC20ToERC1155 = async (params:SimpleSwapParams): Promise<InvokeFunctionResponse>=> {
        if (params.slippage < 0 || params.slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }

        // let isToken1 = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address);
        const sqrt_ratio_limit = (Wrap.ERC20Address > Wrap.WERC20Address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;
        // swap
        const simpleSwap: Call = {
            contractAddress: params.simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0],
                    token1: Wrap.SortedTokens[1],
                    fee: Wrap.getFeeX128(params.fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                swap_params: {
                    amount: {
                        mag: params.amountIn,
                        sign: false
                    },
                    is_token1: Wrap.ERC20Address > Wrap.WERC20Address,
                    sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                    skip_ahead: 4294967295,
                },
                recipient: params.userAddress,
                calculated_amount_threshold: 0,
            })
        };


        return Wrap.account.execute([
            Wrap.createTransferCall(Wrap.ERC20Address,params.simpleSwapperAddress,params.amountIn),
            simpleSwap,
            Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[0]),
            Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[1]),
        ]);
    }



    public static getFeeX128(fee: FeeAmount): bigint {
        return BigInt(fee) * (2n ** 128n) / (10n ** 6n);
    }

    public static getERC1155Balance = async (address: string, tokenId: BigNumberish): Promise<number> => {
        const tokenIdCairo = cairo.uint256(tokenId);
        return await Wrap.ERC1155Contract.balance_of(address, tokenIdCairo)
    }

    public static closestTick(tick: number): bigint {
        let t = 200n;
        let tick2 = BigInt(tick);
        return tick2 - (tick2 % t);
    }



}

