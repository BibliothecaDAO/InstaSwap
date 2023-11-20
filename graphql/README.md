# indexer-graphql

## How to start

### step 1

copy the config example file,then replace the database information
```cmd
    cp .env.example .env
```


### step 2
```cmd
    go mod tidy
```

### step 3
```cmd
    go run server.go
```

then visit  http://localhost:8088/ for GraphQL playground

## Queries

```graphql
query getPoolKeys {
  pool_keys{
    fee
    key_hash
    token0
    token1
    tick_spacing
    extension
  }
}

query getPoolKeyByHash {
  pool_key(
    key_hash: "[hash]"
  ) {
    fee
    key_hash
    token0
    token1
    tick_spacing
    extension
  }
}

query getPositionDeposits {
  position_deposits {
    block_number
    transaction_index
    event_index
    transaction_hash
    token_id
    lower_bound
    upper_bound
    pool_key_hash
    liquidity
    delta0
    delta1
  }
}


query getPositionDepositByHash {
  position_deposit(transaction_hash:"[hash]") {
    block_number
    transaction_index
    event_index
    transaction_hash
    token_id
    lower_bound
    upper_bound
    pool_key_hash
    liquidity
    delta0
    delta1
  }
}


query getSwapByHash {
  swap(transaction_hash:"[hash]") {
      transaction_index
      event_index
      transaction_hash
      locker
      pool_key_hash
      delta0
      delta1
      sqrt_ratio_after
      tick_after
      liquidity_after
  }
}


query getListLiquidity {
  list_liquidity(account:"0x0112C1E020708b84aaC85983734A6ffB5fCe89891e8414e4E54F94CE75c06a90"){
     token_id
  }
}
```


