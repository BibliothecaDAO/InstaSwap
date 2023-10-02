import { useAccount, useConnectors } from '@starknet-react/core'
import { useCallback, useMemo, useState, useEffect } from 'react'
import { Contract, uint256, CallData, RawArgs, Call, num } from 'starknet'
import { Wrap } from '@bibliothecadao/instaswap-core'
import { FeeAmount } from '@bibliothecadao/instaswap-core'
import { Provider, constants, cairo } from "starknet"


const ButtonClick = () => {
  const [lowerBound, setLowerBound] = useState(0);
  const [upperBound, setUpperBound] = useState(0);
  const { address, account } = useAccount()
  const [balance, setBalance] = useState("0");
  const [mintAmount, setMintAmount] = useState(0);
  const [erc1155Amount, setAddLiquidityERC1155Amount] = useState(0);
  const [ethAmount, setAddLiquidityEthAmount] = useState(0);

  const erc1155_address = useMemo(() => "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6", [])
  const werc20_address = useMemo(() => "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4", [])
  const eth_address = useMemo(() => "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7", [])
  const ekubo_position_address = useMemo(() => "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc", [])
  const ekubo_core_address = useMemo(() => "0x031e8a7ab6a6a556548ac85cbb8b5f56e8905696e9f13e9a858142b8ee0cc221", [])
  const provider = new Provider({ sequencer: { network: constants.NetworkName.SN_GOERLI } });

  let wrap = new Wrap(
    erc1155_address,
    werc20_address,
    eth_address,
    ekubo_position_address,
    ekubo_core_address,
    provider
  )
  const getERC1155Balance = useCallback(async () => {
    if (!address) return;
    let b = await Wrap.getERC1155Balance(address, 1);
    setBalance(b.toString());
  }, [address, erc1155_address]);

  useEffect(() => {
    getERC1155Balance();
    const interval = setInterval(() => {
      getERC1155Balance();
    }, 10000);
    return () => clearInterval(interval);
  }, [getERC1155Balance]);

  const handleAddLiquidity = useCallback(() => {
    if (!account) return;
    const realERC1155Amount = erc1155Amount;
    const realERC20Amount = ethAmount * (10 **18);
    account?.execute(wrap.addLiquidity(realERC1155Amount, realERC20Amount, FeeAmount.MEDIUM, lowerBound, upperBound))
  }, [account, lowerBound, upperBound, ethAmount, erc1155Amount])

  const mayInitializePool = useCallback(() => {
    let initialize_tick = {
      mag: 0n,
      sign: false
    }
    account?.execute(wrap.mayInitializePool(FeeAmount.MEDIUM, initialize_tick))
  }, [account, lowerBound, upperBound])

  const mintERC1155Token = useCallback(async () => {
    if (!address) return;
    const call: Call = {
      contractAddress: Wrap.ERC1155Contract.address,
      entrypoint: "mint",
      calldata: CallData.compile({
          to: address,
          id: cairo.uint256(1),
          amount: cairo.uint256(mintAmount),
      })
  }
    account?.execute(
      call
    )
  }, [address, erc1155_address, getERC1155Balance, mintAmount]);

  return (
    <div>
      <div>
        <button onClick={mayInitializePool}>may initialize pool</button>
      </div>
      <div>
        <p>ERC1155 Balance: {balance}</p>
      </div>
      <div>
        <h3> Mint ERC1155 </h3>
      </div>
      <div>
        <label htmlFor="mintAmount">Mint Amount:</label>
        <input type="number" id="mintAmount" value={mintAmount} onChange={(e) => setMintAmount(parseFloat(e.target.value))} />
      </div>
      <div>
        <button onClick={mintERC1155Token}>mint ERC1155 token</button>
      </div>
      <div>
        <h3> Add Liquidity </h3>
      </div>
      <div>
        <label htmlFor="lowerBound">Lower Bound For ERC1155/ETH:</label>
        <input type="number" id="lowerBound" value={lowerBound} onChange={(e) => setLowerBound(parseFloat(e.target.value))} />
      </div>
      <div>
        <label htmlFor="upperBound">Upper Bound For ERC1155/ETH:</label>
        <input type="number" id="upperBound" value={upperBound} onChange={(e) => setUpperBound(parseFloat(e.target.value))} />
      </div>
      <div>
        <label htmlFor="erc1155 amount">ERC1155 amount:</label>
        <input type="number" id="erc1155 amount" value={erc1155Amount} onChange={(e) => setAddLiquidityERC1155Amount(parseFloat(e.target.value))} />
      </div>
      <div>
        <label htmlFor="eth amount">eth Amount:</label>
        <input type="number" id="erc20 amount" value={ethAmount} onChange={(e) => setAddLiquidityEthAmount(parseFloat(e.target.value))} />
      </div>
      <div>
        <button onClick={handleAddLiquidity}>add liquidity</button>
      </div>

    </div>
  )
}

export default ButtonClick