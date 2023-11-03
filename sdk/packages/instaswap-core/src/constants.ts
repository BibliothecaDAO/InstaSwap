export const MAX_SQRT_RATIO =
  6277100250585753475930931601400621808602321654880405518632n;
export const MIN_SQRT_RATIO = 18446748437148339061n;
export const AVNU_SQRT_RATIO =
  363034526046013994104916607590000000000000000000001n;

/**
 * The default factory enabled fee amounts, denominated in hundredths of bips.
 */
export enum FeeAmount {
  LOWEST = 100,
  LOW = 500,
  MEDIUM = 3000,
  HIGH = 10000,
}

/**
 * The default factory tick spacings by fee amount.
 */
export const TICK_SPACINGS: { [amount in FeeAmount]: number } = {
  [FeeAmount.LOWEST]: 200,
  [FeeAmount.LOW]: 1000,
  [FeeAmount.MEDIUM]: 5096,
  [FeeAmount.HIGH]: 10000,
};

export enum SwapType {
  AVNU = "AVNU",
  SIMPLE_SWAPPER = "SIMPLE_SWAPPER",
}

export enum SwapDirection {
  ERC1155_TO_ERC20,
  ERC20_TO_ERC1155,
}
