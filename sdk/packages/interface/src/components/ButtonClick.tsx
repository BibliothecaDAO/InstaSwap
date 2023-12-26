import { useAccount, useConnectors } from "@starknet-react/core";
import { useCallback, useMemo, useState, useEffect } from "react";
import { Contract, uint256, CallData, RawArgs, Call, num } from "starknet";
import { Wrap } from "instaswap-core";
import { FeeAmount, SwapDirection } from "instaswap-core";
import { Provider, constants, cairo } from "starknet";

const ButtonClick = () => {
  const [lowerBound, setLowerBound] = useState(0);
  const [upperBound, setUpperBound] = useState(0);
  const { address, account } = useAccount();
  const [balance, setBalance] = useState("0");
  const [currentPrice, setCurrentPrice] = useState(0);
  const [mintAmount, setMintAmount] = useState(0);
  const [erc1155Amount, setAddLiquidityERC1155Amount] = useState(0);
  const [ethAmount, setAddLiquidityEthAmount] = useState(0);
  const [erc1155AmountForSwap, setERC1155AmountForSwap] = useState(0);
  const [erc20AmountForSwap, setERC20AmountForSwap] = useState(0);
  const [wGoldForSwap, setWGoldForSwap] = useState(0);
  const [nftForWithdraw, setNftForWithdraw] = useState(0);
  const [positionId, setPositionId] = useState(0);
  const [liquidity, setLiquidity] = useState(0);

  const erc1155_address = useMemo(
    () => "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6",
    [],
  );

  const werc20_address = useMemo(
    () => "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4",
    [],
  );
  const eth_address = useMemo(
    () => "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    [],
  );

  const ekubo_position_address = useMemo(
    () => "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc",
    [],
  );
  const ekubo_core_address = useMemo(
    () => "0x031e8a7ab6a6a556548ac85cbb8b5f56e8905696e9f13e9a858142b8ee0cc221",
    [],
  );

  const simple_swapper = useMemo(
    () => "0x064f7ed2dc5070133ae8ccdf85f01e82507facbe5cdde456e1418e3901dc51a0",
    [],
  );
  const quoter = useMemo(
    () => "0x042aa743335663ed9c7b52b331ab7f81cc8d65280d311506653f9b5cc22be7cb",
    [],
  );
  const nft_address = useMemo(
    () => "0x1090e3cfd9990c396f246cd1d5c7fb091905cba9f99739653db1f2960a3311f",
    [],
  );
  const provider = new Provider({
    sequencer: { network: constants.NetworkName.SN_GOERLI },
  });

  const config = {
    erc1155Address: erc1155_address,
    werc20Address: werc20_address,
    erc20Address: eth_address,
    ekuboPositionAddress: ekubo_position_address,
    ekuboCoreAddress: ekubo_core_address,
    quoterAddress: quoter,
    provider: provider,
    account: account,
  };

  const wrap = new Wrap(config);

  const getERC1155Balance = useCallback(async () => {
    if (!address) return;
    const b = await Wrap.getERC1155Balance(address, 1);
    setBalance(b.toString());
  }, [address, erc1155_address]);

  const getCurrentPrice = useCallback(async () => {
    if (!address) return;
    const p = await wrap.quoteSingle(
      FeeAmount.LOWEST,
      eth_address,
      BigInt(10 ** 7),
    );
    const realPrice = p / 10 ** 7;
    setCurrentPrice(realPrice);
  }, [address, erc1155_address, account]);

  useEffect(() => {
    getERC1155Balance();
    const interval = setInterval(() => {
      getERC1155Balance();
    }, 10000);
    return () => clearInterval(interval);
  }, [getERC1155Balance]);

  useEffect(() => {
    getCurrentPrice();
    const interval = setInterval(() => {
      getCurrentPrice();
    }, 3000);
    return () => clearInterval(interval);
  }, [getCurrentPrice]);

  const handleAddLiquidity = useCallback(async () => {
    if (!account) return;

    const params = {
      erc1155Amount: erc1155Amount,
      erc20Amount: ethAmount * 10 ** 18,
      fee: FeeAmount.LOWEST,
      lowerPrice: lowerBound,
      upperPrice: upperBound,
    };

    //add liquidity
    const { transaction_hash } = await wrap.addLiquidity(params);
    console.log(transaction_hash);
  }, [account, lowerBound, upperBound, ethAmount, erc1155Amount]);


  const withdraw = useCallback(async () => {
    const { transaction_hash } = await wrap.withdraw(nftForWithdraw);
    console.log(transaction_hash);
  }, [account, nftForWithdraw]);


  const handleSwapFromERC1155ToERC20BySimpleSwap = useCallback(async () => {
    if (!account) return;

    const params = {
      amountIn: erc1155AmountForSwap,
      minERC20AmountOut: 1313331313,
      simpleSwapperAddress: simple_swapper,
      userAddress: account.address,
      fee: FeeAmount.LOWEST,
      slippage: 0.99,
    };

    const { transaction_hash } = await wrap.swapSimple(
      SwapDirection.ERC1155_TO_ERC20,
      params,
    );
    console.log(transaction_hash);
  }, [account, erc1155AmountForSwap, currentPrice]);

  const handleSwapFromERC20ToERC1155BySimpleSwap = useCallback(async () => {
    if (!account) return;
    // debugger;
    const params = {
      amountIn: erc20AmountForSwap * 10 ** 18,
      minERC20AmountOut: 1313331313,
      simpleSwapperAddress: simple_swapper,
      userAddress: account.address,
      fee: FeeAmount.LOWEST,
      slippage: 0.99,
    };

    const { transaction_hash } = await wrap.swapSimple(
      SwapDirection.ERC20_TO_ERC1155,
      params,
    );
    console.log(transaction_hash);
  }, [account, erc20AmountForSwap, currentPrice]);

  const withdrawLiquidity = useCallback(async () => {
    if (!account) return;

    const { transaction_hash } = await wrap.withdrawLiquidity(
      positionId,
      liquidity,
    );
    console.log(transaction_hash);
  }, [account, liquidity]);

  const mayInitializePool = useCallback(async () => {
    const initialize_tick = {
      mag: 0n,
      sign: false,
    };

    const { transaction_hash } = await wrap.mayInitializePool(
      FeeAmount.LOWEST,
      initialize_tick,
    );
    console.log(transaction_hash);
  }, [account, lowerBound, upperBound]);

  const mintERC1155Token = useCallback(async () => {
    if (!address) return;
    const call: Call = {
      contractAddress: Wrap.ERC1155Contract.address,
      entrypoint: "mint",
      calldata: CallData.compile({
        to: address,
        id: cairo.uint256(1),
        amount: cairo.uint256(mintAmount),
      }),
    };
    account?.execute(call);
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
        <p>Current Price : 1 ETH = {currentPrice} WERC20 </p>
      </div>
      <div>
        <h3> Mint ERC1155 </h3>
      </div>
      <div>
        <label htmlFor="mintAmount">Mint Amount:</label>
        <input
          type="number"
          id="mintAmount"
          value={mintAmount}
          onChange={(e) => setMintAmount(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <button onClick={mintERC1155Token}>mint ERC1155 token</button>
      </div>

      <div>
        <h3> Add Liquidity </h3>
      </div>
      <div>
        <label htmlFor="lowerBound">Lower Price For ETH/ERC1155:</label>
        <input
          type="number"
          id="lowerBound"
          value={lowerBound}
          onChange={(e) => setLowerBound(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <label htmlFor="upperBound">Upper Price For ETH/ERC1155:</label>
        <input
          type="number"
          id="upperBound"
          value={upperBound}
          onChange={(e) => setUpperBound(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <label htmlFor="eth amount">eth Amount:</label>
        <input
          type="number"
          id="erc20 amount"
          value={ethAmount}
          onChange={(e) => setAddLiquidityEthAmount(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <label htmlFor="erc1155 amount">ERC1155 amount:</label>
        <input
          type="number"
          id="erc1155 amount"
          value={erc1155Amount}
          onChange={(e) =>
            setAddLiquidityERC1155Amount(parseFloat(e.target.value))
          }
        />
      </div>
      <div>
        <button onClick={handleAddLiquidity}>add liquidity</button>
      </div>

      <div>
        <h3> Withdraw Liquidity </h3>
      </div>
      <div>
        <label htmlFor="erc20 amount">id:</label>
        <input
          type="number"
          id="position id"
          value={positionId}
          onChange={(e) => setPositionId(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <label htmlFor="erc20 amount">liquidity:</label>
        <input
          type="number"
          id="liquidity"
          value={liquidity}
          onChange={(e) => setLiquidity(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <button onClick={withdrawLiquidity}>withdraw</button>
      </div>

      {/*<div>*/}
      {/*    <h3> Swap From ERC1155 to ERC20 By AVNU </h3>*/}
      {/*</div>*/}
      {/*<div>*/}
      {/*    <label htmlFor="erc1155 amount">ERC1155 amount:</label>*/}
      {/*    <input type="number" id="erc1155 amount" value={erc1155AmountForSwap} onChange={(e) => setERC1155AmountForSwap(parseFloat(e.target.value))} />*/}
      {/*</div>*/}
      {/*<div>*/}
      {/*    <button onClick={handleSwapFromERC1155ToERC20ByAVNU}>swap</button>*/}
      {/*</div>*/}

      <div>
        <h3> Swap From ERC1155 to ERC20 By SimpleSwapper </h3>
      </div>
      <div>
        <label htmlFor="erc1155 amount">ERC1155 amount:</label>
        <input
          type="number"
          id="erc1155 amount"
          value={erc1155AmountForSwap}
          onChange={(e) => setERC1155AmountForSwap(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <button onClick={handleSwapFromERC1155ToERC20BySimpleSwap}>swap</button>
      </div>
      <div>
        <h3> Swap From ERC20 to ERC1155 By SimpleSwapper</h3>
      </div>
      <div>
        <label htmlFor="erc20 amount">ERC20 amount:</label>
        <input
          type="number"
          id="erc20 amount"
          value={erc20AmountForSwap}
          onChange={(e) => setERC20AmountForSwap(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <button onClick={handleSwapFromERC20ToERC1155BySimpleSwap}>swap</button>
      </div>

      <div>
        <h3> Withdraw </h3>
      </div>
      <div>
        <label htmlFor="erc20 amount">ERC1155 amount:</label>
        <input
          type="number"
          id="nft amount"
          value={nftForWithdraw}
          onChange={(e) => setNftForWithdraw(parseFloat(e.target.value))}
        />
      </div>
      <div>
        <button onClick={withdraw}>withdraw</button>
      </div>
    </div>
  );
};

export default ButtonClick;
