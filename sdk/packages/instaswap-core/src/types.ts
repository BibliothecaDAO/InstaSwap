import { AccountInterface, BigNumberish, Provider } from "starknet";
import { FeeAmount } from "./constants";

export type Config = {
  erc1155Address: string;
  werc20Address: string;
  erc20Address: string;
  ekuboPositionAddress: string;
  ekuboCoreAddress: string;
  quoterAddress: string;
  account: AccountInterface | undefined;
  provider?: Provider;
};

export type LiquidityParams = {
  erc1155Amount: BigNumberish;
  erc20Amount: BigNumberish;
  fee: FeeAmount;
  lowerPrice: number;
  upperPrice: number;
};

export type AVNUSwapParams = SwapParams & {
  erc1155AmountIn: BigNumberish;
  aggregatorAddress: string;
};

export type SimpleSwapParams = SwapParams & {
  simpleSwapperAddress: string;
  amountIn: BigNumberish;
};

type SwapParams = {
  minERC20AmountOut: BigNumberish;
  userAddress: string;
  fee: FeeAmount;
  slippage: number;
};
