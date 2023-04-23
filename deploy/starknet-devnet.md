### Export ENV
``` bash
export STARKNET_NETWORK=alpha-goerli
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
```

### Setup accounts
``` bash
starknet new_account --account with_testnet_eth --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
starknet deploy_account --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050 --account with_testnet_eth
```

### Check txn status
ps. replace with your own hash

``` bash
starknet tx_status --hash 0x455435c053cd9f8d3783a78828756335d21a6acea6c41464ee20c54a138fd01 --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

### Declare contracts on dev-net
``` bash
starknet declare --contract target/dev/instaswap_InstaSwapPair.sierra.json  --account with_testnet_eth --max_fee 10000000000000000 --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

### Deploy contracts on dev-net
//TODO
``` bash

```