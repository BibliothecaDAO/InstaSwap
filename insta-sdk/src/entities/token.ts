import invariant from 'tiny-invariant'
import { validateAndParseAddress } from 'starknet'
import { Currency, ETHER } from './currency'
import { number } from 'starknet'
import { StarknetChainId } from 'starknet/dist/constants'

/**
 * Represents an ERC20 token with a unique address and some metadata.
 */
export class Token extends Currency {
  public readonly chainId: StarknetChainId
  public readonly address: string

  public constructor(
    chainId: StarknetChainId,
    address: string,
    decimals: number,
    symbol?: string,
    name?: string,
    logoURI?: string
  ) {
    super(decimals, symbol, name, logoURI)
    this.chainId = chainId
    this.address = validateAndParseAddress(address).toLowerCase()
  }

  /**
   * Returns true if the two tokens are equivalent, i.e. have the same chainId and address.
   * @param other other token to compare
   */
  public equals(other: Token): boolean {
    // short circuit on reference equality
    if (this === other) {
      return true
    }
    return this.chainId === other.chainId && this.address === other.address
  }

  /**
   * Returns true if the address of this token sorts before the address of the other token
   * @param other other token to compare
   * @throws if the tokens have the same address
   * @throws if the tokens are on different chains
   */
  public sortsBefore(other: Token): boolean {
    invariant(this.chainId === other.chainId, 'CHAIN_IDS')
    invariant(this.address !== other.address, 'ADDRESSES')
    const thisAddress = number.toBN(this.address)
    const otherAddress = number.toBN(other.address)

    return thisAddress.lt(otherAddress)
  }
}

/**
 * Compares two currencies for equality
 */
export function currencyEquals(currencyA: Currency, currencyB: Currency): boolean {
  if (currencyA instanceof Token && currencyB instanceof Token) {
    return currencyA.equals(currencyB)
  } else if (currencyA instanceof Token) {
    return false
  } else if (currencyB instanceof Token) {
    return false
  } else {
    return currencyA === currencyB
  }
}

export const WETH = {
  [StarknetChainId.TESTNET]: new Token(
    StarknetChainId.TESTNET,
    '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
    ETHER.decimals,
    ETHER.symbol,
    ETHER.name
  ),
  [StarknetChainId.MAINNET]: new Token(
    StarknetChainId.MAINNET,
    '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
    ETHER.decimals,
    ETHER.symbol,
    ETHER.name
  )
}
