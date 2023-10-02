import { Contract, uint256, CallData, RawArgs, Call, num, cairo, BigNumberish, Provider } from 'starknet'

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";
import ERC20 from "./abi/erc20-abi.json";
import EkuboPosition from "./abi/ekubo-position-abi.json";
import EkuboCore from "./abi/ekubo-core-abi.json";
import { FeeAmount } from './constants';
import { TickMath } from './tickMath';
import {Decimal} from 'decimal.js-light';


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

        // mint_and_deposit
        const mintAndDeposit: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "mint_and_deposit",
            calldata: CallData.compile({
                pool_key: {
                    token0: sortedTokens[0].address,
                    token1: sortedTokens[1].address,
                    fee: Wrap.getFeeX128(fee),
                    tick_spacing: 1, 
                    extension: 0,
                },
                bounds: {
                    lower: {
                        mag: absLowerTick,
                        sign: signLowerTick,
                    },
                    upper: {
                        mag: absUpperTick,
                        sign: signUpperTick,
                    }
                },
                min_liquidity: 12,
            })
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
                    tick_spacing: 1n,
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

