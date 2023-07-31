import JSBI from 'jsbi'
import { StarknetChainId } from 'starknet/dist/constants'

// exports for external consumption
export type BigintIsh = JSBI | bigint | string

export const DEFAULT_CHAIN_ID = 'MAINNET'

export enum TradeType {
  EXACT_INPUT,
  EXACT_OUTPUT
}

export enum Rounding {
  ROUND_DOWN,
  ROUND_HALF_UP,
  ROUND_UP
}

export const FACTORY_ADDRESS: { [chainId in StarknetChainId]: string } = {
  [StarknetChainId.MAINNET]: '0xdad44c139a476c7a17fc8141e6db680e9abc9f56fe249a105094c44382c2fd',
  [StarknetChainId.TESTNET]: '0x262744f8cea943dadc8823c318eaf24d0110dee2ee8026298f49a3bc58ed74a'
}

export const PAIR_CLASS_HASH: { [chainId in StarknetChainId]: string } = {
  [StarknetChainId.MAINNET]: '0x2b39bc3f4c1fd5bef8b7d21504c44e0da59cf27b350551b13d913da52e40d3b',
  [StarknetChainId.TESTNET]: '0x2b39bc3f4c1fd5bef8b7d21504c44e0da59cf27b350551b13d913da52e40d3b'
}

export const PAIR_PROXY_CLASS_HASH: { [chainId in StarknetChainId]: string } = {
  [StarknetChainId.MAINNET]: '0x7b5cd6a6949cc1730f89d795f2442f6ab431ea6c9a5be00685d50f97433c5eb',
  [StarknetChainId.TESTNET]: '0x7b5cd6a6949cc1730f89d795f2442f6ab431ea6c9a5be00685d50f97433c5eb'
}

export const FEE_TO_SETTER_ADDRESS: { [chainId in StarknetChainId]: string } = {
  [StarknetChainId.MAINNET]: '0x284a1ad6382cffc520d8f711cf9519ccf43b3c105b89ef081cbe1a625322410',
  [StarknetChainId.TESTNET]: '0x284a1ad6382cffc520d8f711cf9519ccf43b3c105b89ef081cbe1a625322410'
}

export const MINIMUM_LIQUIDITY = JSBI.BigInt(1000)

// exports for internal consumption
export const ZERO = JSBI.BigInt(0)
export const ONE = JSBI.BigInt(1)
export const TWO = JSBI.BigInt(2)
export const THREE = JSBI.BigInt(3)
export const FIVE = JSBI.BigInt(5)
export const TEN = JSBI.BigInt(10)
export const _100 = JSBI.BigInt(100)
export const _997 = JSBI.BigInt(997)
export const _1000 = JSBI.BigInt(1000)

export enum SolidityType {
  uint8 = 'uint8',
  uint256 = 'uint256'
}

export const SOLIDITY_TYPE_MAXIMA = {
  [SolidityType.uint8]: JSBI.BigInt('0xff'),
  [SolidityType.uint256]: JSBI.BigInt('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff')
}
