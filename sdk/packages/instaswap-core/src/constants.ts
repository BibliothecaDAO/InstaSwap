
/**
 * The default factory enabled fee amounts, denominated in hundredths of bips.
 */
export enum FeeAmount {
    LOWEST = 100,
    LOW = 500,
    MEDIUM = 3000,
    HIGH = 10000
  }
  
  /**
   * The default factory tick spacings by fee amount.
   */
  export const TICK_SPACINGS: { [amount in FeeAmount]: number } = {
    [FeeAmount.LOWEST]: 200,
    [FeeAmount.LOW]: 1000,
    [FeeAmount.MEDIUM]: 5096,
    [FeeAmount.HIGH]: 10000
  }