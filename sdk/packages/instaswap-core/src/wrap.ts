import { Contract, uint256, CallData, RawArgs, Call, num, cairo, BigNumberish } from 'starknet'

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";
import ERC20 from "./abi/erc20-abi.json";
import EkuboPosition from "./abi/ekubo-position-abi.json";
import EkuboCore from "./abi/ekubo-core-abi.json";

export class Wrap {
    public static ERC1155Contract: Contract;
    public static WERC20Contract: Contract;
    public static ERC20Contract: Contract;
    public static EkuboPosition: Contract;
    public static EkuboCoreContract: Contract;

    constructor(ERC1155Address: string, WERC20Address: string, ERC20Address: string, EkuboPositionAddress: string, EkuboCoreAddress: string) {
        Wrap.ERC1155Contract = new Contract(ERC1155, ERC1155Address);
        Wrap.WERC20Contract = new Contract(WERC20, WERC20Address);
        Wrap.ERC20Contract = new Contract(ERC20, ERC20Address);
        Wrap.EkuboPosition = new Contract(EkuboPosition, EkuboPositionAddress);
        Wrap.EkuboCoreContract = new Contract(EkuboCore, EkuboCoreAddress);
    }

    // public deposit = async (amount: bigint) => {
    //     // TODO: implement
    // }

    // public withdraw = async (amount: bigint) => {
    //     // 
    // }

    public addLiquidity(erc1155Amount: BigNumberish, erc20Amount: BigNumberish, fee: BigNumberish, tick_spacing: BigNumberish): Call[] {
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
        // mint_and_deposit
        const mintAndDeposit: Call = {
            contractAddress: Wrap.EkuboPosition.address,
            entrypoint: "mint_and_deposit",
            calldata: CallData.compile({
                pool_key: {
                    token0: sortedTokens[0].address,
                    token1: sortedTokens[1].address,
                    fee: fee,
                    tick_spacing: tick_spacing,
                    extension: 0,
                },
                bounds: {
                    lower: {
                        mag: 130,
                        sign: true,  
                    },
                    upper: {
                        mag: 210,
                        sign: false,
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

    public mayInitializePool(fee: BigNumberish, tick_spacing: BigNumberish, initial_tick: { mag: BigNumberish, sign: boolean }): Call[] {
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
                    fee: fee,
                    tick_spacing: tick_spacing,
                    extension: 0,
                },
                initial_tick
            })
        }
        return [mayInitializePool];
    }

}

