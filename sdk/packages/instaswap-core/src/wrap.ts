import { Contract, uint256, CallData, RawArgs, Call, num, cairo } from 'starknet'

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";
import ERC20 from "./abi/erc20-abi.json";
import EkuboNFT from "./abi/ekubo-nft-abi.json";

export abstract class Wrap {
    public static ERC1155Contract: Contract;
    public static WERC20Contract: Contract;
    public static ERC20Contract: Contract;
    public static EkuboNFTContract: Contract;

    constructor(ERC1155Address: string, WERC20Address: string, ERC20Address: string, EkuboNFTAddress: string) {
        Wrap.ERC1155Contract = new Contract(ERC1155, ERC1155Address);
        Wrap.WERC20Contract = new Contract(WERC20, WERC20Address);
        Wrap.ERC20Contract = new Contract(ERC20, ERC20Address);
        Wrap.EkuboNFTContract = new Contract(EkuboNFT, EkuboNFTAddress);
    }

    // public deposit = async (amount: bigint) => {
    //     // TODO: implement
    // }

    // public withdraw = async (amount: bigint) => {
    //     // 
    // }

    public addLiquidity(depositAmount: number): Call[] {
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
                amount: cairo.uint256(depositAmount)
            })
        }

        // transfer werc20
        const transferWERC20: Call = {
            contractAddress: Wrap.WERC20Contract.address,
            entrypoint: "transfer",
            calldata: CallData.compile({
                recipient: Wrap.EkuboNFTContract.address,
                amount: cairo.uint256(BigInt(depositAmount) * (BigInt(10) ** BigInt(18)))
            })
        }
        // transfer erc20
        // mint_and_deposit
        // clear werc20
        // clear erc20
        // cancel approval

        return [approveForAll, depositToWERC20, transferWERC20];
    }
}

