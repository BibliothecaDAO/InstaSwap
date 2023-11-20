# InstaSwap

### initialize sdk

To initialize sdk,fill the config first

```js

import { Provider, constants } from "starknet";
import { useAccount } from "@starknet-react/core";
....

const provider = new Provider({
    sequencer: { network: constants.NetworkName.SN_GOERLI },
  });

const config = {
    erc1155Address: "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6",
    werc20Address: "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4",
    erc20Address: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    ekuboPositionAddress: "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc",
    ekuboCoreAddress: "0x031e8a7ab6a6a556548ac85cbb8b5f56e8905696e9f13e9a858142b8ee0cc221",
    quoterAddress: "0x042aa743335663ed9c7b52b331ab7f81cc8d65280d311506653f9b5cc22be7cb",
    provider: provider,
    account: useAccount(),
};

const wrap = new Wrap(config);
...
```

### Initialize pool

```js
const initialize_tick = { mag: 0n, sign: false };

const { transaction_hash } = await wrap.mayInitializePool(
  FeeAmount.LOWEST,
  initialize_tick,
);
```

### Add liquidity

```js
const params = {
      erc1155Amount: [erc1155 amount],
      erc20Amount: [erc20 amount],
      fee: [fee],
      lowerPrice: [lowerBound],
      upperPrice: [upperBound],
    };

wrap.addLiquidity(params);

```



### Withdraw Liquidity

```js
wrap.withdrawLiquidity(positionId,liquidity);
```




### Simple wrap

- from erc115 to erc20

```js

const params = {
  amountIn: [erc1155 amount for swap],
  minERC20AmountOut: [min amount],
  simpleSwapperAddress: [simple swapper address],
  userAddress:[user address],
  fee: [fee],
  slippage: [slippage],
};

wrap.swapSimple(
  SwapDirection.ERC1155_TO_ERC20,
  params,
);


```

- from erc20 to erc1155

```js
 const params = {
  amountIn: [erc20 amount for swap],
  minERC20AmountOut: [min amount],
  simpleSwapperAddress: [simple swapper address],
  userAddress:[user address],
  fee: [fee],
  slippage: [slippage],
};

wrap.swapSimple(
  SwapDirection.ERC20_TO_ERC1155,
  params,
);

```

### Withdraw erc1155

```js
wrap.withdraw(erc1155Num);
```


