import {BigNumberish, cairo, Call, CallData, constants, Contract, num, Provider} from 'starknet'

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";
import ERC20 from "./abi/erc20-abi.json";
import EkuboPosition from "./abi/ekubo-position-abi.json";
import EkuboCore from "./abi/ekubo-core-abi.json";
import {FeeAmount, MAX_SQRT_RATIO, MIN_SQRT_RATIO, SwapDirection} from './constants';
import {TickMath} from './tickMath';
import {Decimal} from 'decimal.js-light';


type Config = {
    erc1155Address: string;
    werc20Address:string;
    erc20Address:string;
    ekuboPositionAddress:string;
    ekuboCoreAddress:string;
    provider?:Provider;
};


type LiquidityParams = {
    erc1155Amount: BigNumberish;
    erc20Amount: BigNumberish;
    fee: FeeAmount;
    lowerPrice: number;
    upperPrice: number;
}


type AVNUSwapParams = SwapParams & {
    erc1155AmountIn: BigNumberish;
    aggregatorAddress: string;
}

type SimpleSwapParams = SwapParams & {
    simpleSwapperAddress: string;
    amountIn: BigNumberish;
}


type SwapParams = {
    minERC20AmountOut: BigNumberish;
    userAddress: string;
    fee: FeeAmount;
    slippage: number;
}



export class Wrap {

    public static ERC1155Contract: Contract;
    public static WERC20Contract: Contract;
    public static ERC20Contract: Contract;
    public static EkuboPosition: Contract;
    public static EkuboCoreContract: Contract;
    public static SortedTokens:Contract[];
    public static ERC1155ApproveCall:Call;
    public static CancelERC1155ApproveCall:Call;


    constructor(config:Config) {
        //default provider
        const provider         = config.provider ? config.provider : new Provider({ sequencer: { network: constants.NetworkName.SN_GOERLI } });
        Wrap.ERC1155Contract   = new Contract(ERC1155, config.erc1155Address, provider);
        Wrap.WERC20Contract    = new Contract(WERC20, config.werc20Address, provider);
        Wrap.ERC20Contract     = new Contract(ERC20, config.erc20Address, provider);
        Wrap.EkuboPosition     = new Contract(EkuboPosition, config.ekuboPositionAddress, provider);
        Wrap.EkuboCoreContract = new Contract(EkuboCore, config.ekuboCoreAddress, provider);
        Wrap.SortedTokens      = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));

        Wrap.ERC1155ApproveCall = {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(true)
            })
        };

        Wrap.CancelERC1155ApproveCall =  {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(false)
            })
        };


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
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "approve",
            calldata: CallData.compile({
                spender: spender,
                amount: cairo.uint256(amount)
            })
        }
    }



    public mayInitializePool(fee: FeeAmount, initial_tick: { mag: BigNumberish, sign: boolean }): Call[] {

        const mayInitializePool: Call = {
            contractAddress: Wrap.EkuboCoreContract.address,
            entrypoint: "maybe_initialize_pool",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0].address,
                    token1: Wrap.SortedTokens[1].address,
                    fee: Wrap.getFeeX128(fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                initial_tick
            })
        }

        return [mayInitializePool];
    }

    public addLiquidity(params:LiquidityParams): Call[] {

        const lowerSqrtRatioX128 = new Decimal(params.lowerPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        const upperSqrtRatioX128 = new Decimal(params.upperPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        const lowerTick = TickMath.getTickAtSqrtRatio(BigInt(lowerSqrtRatioX128));
        const upperTick = TickMath.getTickAtSqrtRatio(BigInt(upperSqrtRatioX128));

        if (lowerTick > upperTick) {
            throw new Error("lowerTick should be less than upperTick");
        }

        /**
         * create needed contract calls
         * mint_and_deposit
         */
        const mintAndDeposit: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "mint_and_deposit",
            calldata: CallData.compile(
                {
                    pool_key: {
                        token0: Wrap.SortedTokens[0].address,
                        token1: Wrap.SortedTokens[1].address,
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


        return [
                    Wrap.ERC1155ApproveCall,
                    Wrap.createDepositCall(Wrap.WERC20Contract.address,params.erc1155Amount),
                    Wrap.createTransferCall(Wrap.WERC20Contract.address,Wrap.EkuboPosition.address,
                        BigInt(params.erc1155Amount) * (BigInt(10) ** BigInt(18))),
                    Wrap.createTransferCall(Wrap.ERC20Contract.address,Wrap.EkuboPosition.address,BigInt(params.erc20Amount)),
                    mintAndDeposit,
                    Wrap.createClearCall(Wrap.EkuboPosition.address,Wrap.WERC20Contract.address),
                    Wrap.createClearCall(Wrap.EkuboPosition.address,Wrap.ERC20Contract.address),
                    Wrap.CancelERC1155ApproveCall
        ];
    }

    public withdraw(id: number):Call[]{
        return [];
    }


    public swapBySimple(direction:SwapDirection,params:SimpleSwapParams){
        if (direction == SwapDirection.ERC1155_TO_ERC20){
            return this.swapFromERC1155ToERC20BySimpleSwapper(params);
        }
        return this.swapFromERC20ToERC1155BySimpleSwapper(params);
    }


    public swapFromERC1155ToERC20ByAVNU(params:AVNUSwapParams):Call[] {

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
                token_from_address: Wrap.WERC20Contract.address,
                token_from_amount: cairo.uint256(werc20AmountIn),
                token_to_address: Wrap.ERC20Contract.address,
                token_to_amount: cairo.uint256(params.minERC20AmountOut), // this is useless in avnu contract
                token_to_min_amount: cairo.uint256(params.minERC20AmountOut),
                beneficiary: params.userAddress,
                integrator_fee_amount_bps: 0,
                integrator_fee_recipient: 0,
                routes: [
                    {
                        token_from: Wrap.WERC20Contract.address,
                        token_to: Wrap.ERC20Contract.address,
                        exchange_address: Wrap.EkuboCoreContract.address,
                        percent: 100,
                        additional_swap_params: [
                            Wrap.SortedTokens[0].address,
                            Wrap.SortedTokens[1].address,
                            Wrap.getFeeX128(params.fee),  //fee for determin the pool_key
                            200, // tick_spacing for determin the pool_key
                            0, // extension for determin the pool_key
                            363034526046013994104916607590000000000000000000001n//sqrt_ratio_limit
                        ],
                    }
                ]
            })
        }
        return [
                    Wrap.ERC1155ApproveCall,
                    Wrap.createDepositCall(Wrap.WERC20Contract.address,params.erc1155AmountIn),
                    Wrap.createWERC20ApproveCall(params.aggregatorAddress,werc20AmountIn),
                    multiRouteSwap
        ];

    }

    public swapFromERC1155ToERC20BySimpleSwapper(params:SimpleSwapParams):Call[] {

        if (params.slippage < 0 || params.slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }

        const werc20AmountIn = BigInt(params.amountIn.toString()) * BigInt(10 ** 18);


        const sqrt_ratio_limit = !(Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;

        // swap
        const simpleSwap: Call = {
            contractAddress: params.simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0].address,
                    token1: Wrap.SortedTokens[1].address,
                    fee: Wrap.getFeeX128(params.fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                swap_params: {
                    amount: {
                        mag: werc20AmountIn,
                        sign: false
                    },
                    is_token1: !(Wrap.ERC20Contract.address > Wrap.WERC20Contract.address),
                    sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                    skip_ahead: 4294967295,
                },
                recipient: params.userAddress,
                calculated_amount_threshold: 0,
            })
        }

        return [
                    Wrap.ERC1155ApproveCall,
                    Wrap.createDepositCall(Wrap.WERC20Contract.address,params.amountIn),
                    Wrap.createTransferCall(Wrap.WERC20Contract.address,params.simpleSwapperAddress,
                        BigInt(params.amountIn) * (BigInt(10 ** 18))),
                    simpleSwap,
                    Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[0].address),
                    Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[1].address),
        ];
    }

    public swapFromERC20ToERC1155BySimpleSwapper(params:SimpleSwapParams):Call[] {
        if (params.slippage < 0 || params.slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }

        // let isToken1 = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address);
        const sqrt_ratio_limit = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;
        // swap
        const simpleSwap: Call = {
            contractAddress: params.simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile({
                pool_key: {
                    token0: Wrap.SortedTokens[0].address,
                    token1: Wrap.SortedTokens[1].address,
                    fee: Wrap.getFeeX128(params.fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                swap_params: {
                    amount: {
                        mag: params.amountIn,
                        sign: false
                    },
                    is_token1: Wrap.ERC20Contract.address > Wrap.WERC20Contract.address,
                    sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                    skip_ahead: 4294967295,
                },
                recipient: params.userAddress,
                calculated_amount_threshold: 0,
            })
        };


        return [
                    Wrap.createTransferCall(Wrap.ERC20Contract.address,params.simpleSwapperAddress,params.amountIn),
                    simpleSwap,
                    Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[0].address),
                    Wrap.createClearCall(params.simpleSwapperAddress,Wrap.SortedTokens[1].address),
        ];
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

