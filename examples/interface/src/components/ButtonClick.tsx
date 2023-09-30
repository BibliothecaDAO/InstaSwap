import { useAccount, useConnectors } from '@starknet-react/core'
import { useCallback, useMemo } from 'react'
import { Contract, uint256, CallData, RawArgs, Call, num } from 'starknet'
import {Wrap} from '@bibliothecadao/instaswap-core'

const ButtonClick = () => {
  const { address, account } = useAccount()

  const erc1155_address = useMemo(() => "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6", [])
  const werc20_address = useMemo(() => "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4", [])
  const eth_address = useMemo(() => "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", [])
  const ekubo_nft_address = useMemo(() => "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc", [])

  const handleAddLiquidity = useCallback(() => {
    debugger;
    let wrap = new Wrap(
      erc1155_address,
      werc20_address,
      eth_address,
      ekubo_nft_address,
    )
    const fee = 0xcccc;
    const tick_spacing = 0x01744e;
    
    // 10^18
    const eth_amount = 1n * 10n ** 14n;
    
    account?.execute(wrap.addLiquidity(1n, eth_amount, fee, tick_spacing))
  }, [account])

  return (
    <div>
      <button onClick={handleAddLiquidity}>add liquidity</button>
    </div>
  )
}

export default ButtonClick