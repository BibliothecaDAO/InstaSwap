### Export ENV

```bash
export STARKNET_NETWORK=alpha-goerli
export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
```

### Setup accounts

```bash
starknet new_account --account with_testnet_eth --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
starknet deploy_account --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050 --account with_testnet_eth
```

### Check txn status

ps. replace with your own hash

```bash
starknet tx_status --hash 0x2b221bc1aab675e99189692fd530003d269eb099abba70ebd29c3fb5ab10187 --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

### Declare contracts on dev-net

```bash
starknet declare --contract target/dev/instaswap_InstaSwapPair.sierra.json  --account devnet_account1 --max_fee 10000000000000000 --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050
```

### Deploy contracts on dev-net

```bash
starknet deploy --class_hash 0x11e3711dbd08dd49631efa3a80faa28457cc193d1c620708331e1780e4b6b6e --account devnet_account1 --max_fee 100000000000000000 --gateway_url http://localhost:5050 --feeder_gateway_url http://localhost:5050

```
