import { useAccount, useConnectors } from '@starknet-react/core'
import { useCallback, useMemo } from 'react'
import { Contract, uint256, CallData, RawArgs, Call, num } from 'starknet'

const ButtonClick = () => {
  const { address, account } = useAccount()

  const erc1155_address = useMemo(() => "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6", [])
  const werc20_address = useMemo(() => "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4", [])
  const eth_address = useMemo(() => "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", [])
  const ekubo_nft_address = useMemo(() => "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc", [])

  const approveForAll: Call = useMemo(() => ({
    contractAddress: erc1155_address,
    entrypoint: "setApprovalForAll",
    calldata: CallData.compile({
      operator: werc20_address,
      approved: num.toCairoBool(true)
    })
  }), [erc1155_address, werc20_address])
  
  // wrap token
  const depositToWERC20: Call = {
      contractAddress: werc20_address,
      entrypoint: "deposit",
      calldata: CallData.compile({
        amount: cairo.uint256(100000n)
      })
  }
  
  // transfer werc20
  const transferWERC20: Call = {
    contractAddress: werc20_address,
    entrypoint: "transfer",
    calldata: CallData.compile({
      recipient: receiverAddress,
      amount: cairo.uint256(100000n)
    })
  }
  // transfer erc20
  // mint_and_deposit
  // clear werc20
  // clear erc20

  // cancel approval

  const handleAddLiquidity = useCallback(() => {
    account?.execute([approveForAll])
  }, [account, approveForAll])

  return (
    <div>
      <button onClick={handleAddLiquidity}>add liquidity</button>
    </div>
  )
}

export default ButtonClick