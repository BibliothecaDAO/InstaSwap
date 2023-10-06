import { Contract, uint256, CallData, RawArgs, Call, num, cairo, BigNumberish, Provider } from 'starknet'

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";
import ERC20 from "./abi/erc20-abi.json";
import EkuboPosition from "./abi/ekubo-position-abi.json";
import EkuboCore from "./abi/ekubo-core-abi.json";
import { FeeAmount } from './constants';
import { TickMath } from './tickMath';
import { Decimal } from 'decimal.js-light';

const MAX_SQRT_RATIO = 6277100250585753475930931601400621808602321654880405518632n;
const MIN_SQRT_RATIO = 18446748437148339061n;

export class Wrap {
    public static ERC1155Contract: Contract;
    public static WERC20Contract: Contract;
    public static ERC20Contract: Contract;
    public static EkuboPosition: Contract;
    public static EkuboCoreContract: Contract;

    

    constructor(ERC1155Address: string, WERC20Address: string, ERC20Address: string, EkuboPositionAddress: string, EkuboCoreAddress: string, provider: Provider) {
        Wrap.ERC1155Contract = new Contract(ERC1155, ERC1155Address, provider);
        Wrap.WERC20Contract = new Contract(WERC20, WERC20Address, provider);
        Wrap.ERC20Contract = new Contract(ERC20, ERC20Address, provider);
        Wrap.EkuboPosition = new Contract(EkuboPosition, EkuboPositionAddress, provider);
        Wrap.EkuboCoreContract = new Contract(EkuboCore, EkuboCoreAddress, provider);
    }

    // public deposit = async (amount: bigint) => {
    //     // TODO: implement
    // }

    // public withdraw = async (amount: bigint) => {
    //     // 
    // }
    public static closestTick(tick: number): bigint {
        let t = 200n;
        let tick2 = BigInt(tick);
        let closestTick = tick2 - (tick2 % t);
        return closestTick;

        

    }

    public addLiquidity(erc1155Amount: BigNumberish, erc20Amount: BigNumberish, fee: FeeAmount, lowerPrice: number, upperPrice: number): Call[] {

        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));


        const approveForAll: Call = {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(true)
            })
        }

        // wrap token
        const depositToWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "deposit",
            calldata: CallData.compile({
                amount: cairo.uint256(erc1155Amount)
            })
        }

        // transfer werc20
        const transferWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: Wrap.EkuboPosition.address,
                amount: cairo.uint256(BigInt(erc1155Amount) * (BigInt(10) ** BigInt(18))) // wrap token has 18 decimals
            })
        }
        // transfer erc20
        const transferERC20: Call = {
            contractAddress: Wrap.ERC20Contract.address,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: Wrap.EkuboPosition.address,
                amount: cairo.uint256(BigInt(erc20Amount))
            })
        }
        Decimal.set({ precision: 78 });
        let lowerSqrtRatioX128 = new Decimal(lowerPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        let upperSqrtRatioX128 = new Decimal(upperPrice).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        const lowerTick = TickMath.getTickAtSqrtRatio(BigInt(lowerSqrtRatioX128));
        const upperTick = TickMath.getTickAtSqrtRatio(BigInt(upperSqrtRatioX128));
        if (lowerTick > upperTick) {
            throw new Error("lowerTick should be less than upperTick");
        }
        let absLowerTick = Math.abs(lowerTick);
        let signLowerTick = lowerTick < 0 ? true : false;
        let absUpperTick = Math.abs(upperTick);
        let signUpperTick = upperTick < 0 ? true : false;
        let tick = 50000000n;
        let tmp = {
            pool_key: {
                token0: sortedTokens[0].address,
                token1: sortedTokens[1].address,
                fee: Wrap.getFeeX128(fee),
                tick_spacing: 200,
                extension: 0,
            },
            bounds: {
                lower: {
                    mag: tick,
                    sign: signLowerTick,
                },
                upper: {
                    mag: tick,
                    sign: signUpperTick,
                }
            },
            min_liquidity: 2000,
        };
        // mint_and_deposit
        const mintAndDeposit: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "mint_and_deposit",
            calldata: CallData.compile(tmp)
        }
        // clear werc20
        const clearWERC20: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: Wrap.WERC20Contract.address
            })
        }
        // clear erc20
        const clearERC20: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: Wrap.ERC20Contract.address
            })
        }
        // cancel approval
        const cancelApproval: Call = {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(false)
            })
        }

        return [approveForAll, depositToWERC20, transferWERC20, transferERC20, mintAndDeposit, clearWERC20, clearERC20, cancelApproval];
    }

    public withdraw(id: number) {
        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));


    }

    public swapFromERC1155ToERC20ByAVNU(erc1155AmountIn: BigNumberish, minERC20AmountOut: BigNumberish, aggregatorAddress: string, userAddress: string, fee: FeeAmount, slippage: number, currentPrice: number) {
        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));
        if (slippage < 0 || slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }
        const werc20AmountIn = BigInt(erc1155AmountIn.toString()) * BigInt(10 ** 18);
        Decimal.set({ precision: 78 });
        let sqrtRatioLimitX128 = (Wrap.ERC20Contract.address < Wrap.WERC20Contract.address) ? new Decimal(currentPrice / 300).sqrt().mul(new Decimal(2).pow(128)).toFixed(0) : new Decimal(currentPrice * 300).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        
        const approveForAll: Call = {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(true)
            })
        }
        // wrap token
        const depositToWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "deposit",
            calldata: CallData.compile({
                amount: cairo.uint256(erc1155AmountIn)
            })
        }
        // approve WERC20
        const approveWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "approve",
            calldata: CallData.compile({
                spender: aggregatorAddress,
                amount: cairo.uint256(werc20AmountIn)
            })
        }
        let tmp = {
            token_from_address: Wrap.WERC20Contract.address,
            token_from_amount: cairo.uint256(werc20AmountIn),
            token_to_address: Wrap.ERC20Contract.address,
            token_to_amount: cairo.uint256(minERC20AmountOut), // this is useless in avnu contract
            token_to_min_amount: cairo.uint256(minERC20AmountOut),
            beneficiary: userAddress,
            integrator_fee_amount_bps: 0,
            integrator_fee_recipient: 0,
            routes: [
                {
                    token_from: Wrap.WERC20Contract.address,
                    token_to: Wrap.ERC20Contract.address,
                    exchange_address: Wrap.EkuboCoreContract.address,
                    percent: 100,
                    additional_swap_params: [
                        sortedTokens[0].address,
                        sortedTokens[1].address,
                        Wrap.getFeeX128(fee),  //fee for determin the pool_key
                        200, // tick_spacing for determin the pool_key
                        0, // extension for determin the pool_key
                        363034526046013994104916607590000000000000000000001n  //sqrt_ratio_limit
                    ],
                }
            ]
        };
        // swap
        const multiRouteSwap: Call = {
            contractAddress: aggregatorAddress,
            entrypoint: "multi_route_swap",
            calldata: CallData.compile(tmp)
        }
        return [approveForAll, depositToWERC20, approveWERC20, multiRouteSwap];

    }

    public swapFromERC1155ToERC20BySimpleSwapper(erc1155AmountIn: BigNumberish, minERC20AmountOut: BigNumberish, simpleSwapperAddress: string, userAddress: string, fee: FeeAmount, slippage: number, currentPrice: number) {
        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));
        if (slippage < 0 || slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }
        const werc20AmountIn = BigInt(erc1155AmountIn.toString()) * BigInt(10 ** 18);
        Decimal.set({ precision: 78 });
        let sqrtRatioLimitX128 = (Wrap.ERC20Contract.address < Wrap.WERC20Contract.address) ? new Decimal(currentPrice / 300).sqrt().mul(new Decimal(2).pow(128)).toFixed(0) : new Decimal(currentPrice * 300).sqrt().mul(new Decimal(2).pow(128)).toFixed(0);
        
        const approveForAll: Call = {
            contractAddress: Wrap.ERC1155Contract.address,
            entrypoint: "setApprovalForAll",
            calldata: CallData.compile({
                operator: Wrap.WERC20Contract.address,
                approved: num.toCairoBool(true)
            })
        }
        // wrap token
        const depositToWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "deposit",
            calldata: CallData.compile({
                amount: cairo.uint256(erc1155AmountIn)
            })
        }
        // transfer werc20
        const transferWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: simpleSwapperAddress,
                amount: cairo.uint256(BigInt(erc1155AmountIn) * (BigInt(10 ** 18))) // wrap token has 18 decimals
            })
        }
        let isToken1 = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? true : false;
        let sqrt_ratio_limit = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;
        let tmp = {
            pool_key: {
                token0: sortedTokens[0].address,
                token1: sortedTokens[1].address,
                fee: Wrap.getFeeX128(fee),
                tick_spacing: 200,
                extension: 0,
            },
            swap_params: {
                amount: {
                    mag: werc20AmountIn, 
                    sign: false
                },
                is_token1: isToken1,
                sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                skip_ahead: 4294967295,
            },
            recipient: userAddress,
            calculated_amount_threshold: 0,
        };
        // swap
        const simpleSwap: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile(tmp)
        }
        const clearToken0: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: sortedTokens[0].address
            })
        }
        const clearToken1: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: sortedTokens[1].address
            })
        }
        return [approveForAll, depositToWERC20, transferWERC20, simpleSwap, clearToken0, clearToken1];
    }

    public swapFromERC20ToERC1155BySimpleSwapper(erc20AmountIn: BigNumberish, minERC1155AmountOut: BigNumberish, simpleSwapperAddress: string, userAddress: string, fee: FeeAmount, slippage: number, currentPrice: number) {
        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));
        if (slippage < 0 || slippage > 1) {
            throw new Error("slippage should be between 0 and 1");
        }
        
        // transfer werc20
        const transferERC20: Call = {
            contractAddress: Wrap.ERC20Contract.address,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: simpleSwapperAddress,
                amount: cairo.uint256(erc20AmountIn) 
            })
        }
        let isToken1 = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? true : false;
        let sqrt_ratio_limit = (Wrap.ERC20Contract.address > Wrap.WERC20Contract.address) ? MAX_SQRT_RATIO : MIN_SQRT_RATIO;
        let tmp = {
            pool_key: {
                token0: sortedTokens[0].address,
                token1: sortedTokens[1].address,
                fee: Wrap.getFeeX128(fee),
                tick_spacing: 200,
                extension: 0,
            },
            swap_params: {
                amount: {
                    mag: erc20AmountIn, 
                    sign: false
                },
                is_token1: isToken1,
                sqrt_ratio_limit: cairo.uint256(sqrt_ratio_limit),
                skip_ahead: 4294967295,
            },
            recipient: userAddress,
            calculated_amount_threshold: 0,
        };
        // swap
        const simpleSwap: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "swap",
            calldata: CallData.compile(tmp)
        }
        const clearToken0: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: sortedTokens[0].address
            })
        }
        const clearToken1: Call = {
            contractAddress: simpleSwapperAddress,
            entrypoint: "clear",
            calldata: CallData.compile({
                token: sortedTokens[1].address
            })
        }
        return [transferERC20, simpleSwap, clearToken0, clearToken1];
    }

    public mayInitializePool(fee: FeeAmount, initial_tick: { mag: BigNumberish, sign: boolean }): Call[] {
        // sort tokens
        // TODO check length
        const sortedTokens: Contract[] = [Wrap.ERC20Contract, Wrap.WERC20Contract].sort((a, b) => a.address.localeCompare(b.address));

        const mayInitializePool: Call = {
            contractAddress: Wrap.EkuboCoreContract.address,
            entrypoint: "maybe_initialize_pool",
            calldata: CallData.compile({
                pool_key: {
                    token0: sortedTokens[0].address,
                    token1: sortedTokens[1].address,
                    fee: Wrap.getFeeX128(fee),
                    tick_spacing: 200,
                    extension: 0,
                },
                initial_tick
            })
        }
        return [mayInitializePool];
    }

    public static getFeeX128(fee: FeeAmount): bigint {
        let feeX128 = BigInt(fee) * (2n ** 128n) / (10n ** 6n);
        return feeX128;
    }

    public static getERC1155Balance = async (address: string, tokenId: BigNumberish): Promise<number> => {
        const tokenIdCairo = cairo.uint256(tokenId);
        const balance = await Wrap.ERC1155Contract.balance_of(address, tokenIdCairo);
        return balance
    }

}

