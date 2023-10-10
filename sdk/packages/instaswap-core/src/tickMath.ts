import { Decimal } from 'decimal.js-light';
// import JSBI from 'jsbi';


export abstract class TickMath {

    /**
     * Cannot be constructed.
     */
    private constructor() { }

    public static getTickAtSqrtRatio(sqrt_ratio_x128: bigint): number {
        // A fixed point .128 number has at most 128 bits after the decimal, 
        // which translates to about 10**38.5 in decimal.
        // That means ~78 decimals of precision should be able to represent
        // any price with full precision.
        // Note there can be loss of precision for intermediate calculations,
        // but this should be sufficient for just computing the price.
        Decimal.set({ precision: 78 });

        const sqrt_ratio = new Decimal(sqrt_ratio_x128.toString()).div(new Decimal(2).pow(128));
        const tick = sqrt_ratio
            .div(new Decimal('1.000001').sqrt())
            .log()
            .div(new Decimal('2').log())
            .toFixed(0);
        return Number(tick);

    }

    public static getSqrtRatioAtTick(tick: number): bigint {
        // A fixed point .128 number has at most 128 bits after the decimal, 
        // which translates to about 10**38.5 in decimal.
        // That means ~78 decimals of precision should be able to represent
        // any price with full precision.
        // Note there can be loss of precision for intermediate calculations,
        // but this should be sufficient for just computing the price.
        Decimal.set({ precision: 78 });

        const sqrt_ratio_x128 =
            new Decimal('1.000001')
                .sqrt()
                .pow(tick)
                .mul(new Decimal(2).pow(128));
        return BigInt(sqrt_ratio_x128.toFixed(0));
    }

    public static tryParseTick(): number | undefined {
        // TODO
        return undefined;
    }

}
