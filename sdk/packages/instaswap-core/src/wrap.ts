import { Contract } from "starknet";

import ERC1155 from "./abi/erc1155-abi.json";
import WERC20 from "./abi/werc20-abi.json";

export abstract class Wrap {
    public static ERC1155Contract: Contract;
    public static WERC20Contract: Contract;

    constructor(ERC1155Address: string, WERC20Address: string) {
        Wrap.ERC1155Contract = new Contract(ERC1155, ERC1155Address);
        Wrap.WERC20Contract = new Contract(WERC20, WERC20Address);
    }

    public deposit = async (amount: bigint) => {
        // TODO: implement
    }

    public withdraw = async (amount: bigint) => {
        // 
    }
}