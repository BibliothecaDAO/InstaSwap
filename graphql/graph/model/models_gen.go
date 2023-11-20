// Code generated by github.com/99designs/gqlgen, DO NOT EDIT.

package model

type PoolKey struct {
	KeyHash     string `json:"key_hash"`
	Token0      string `json:"token0"`
	Token1      string `json:"token1"`
	Fee         string `json:"fee"`
	TickSpacing string `json:"tick_spacing"`
	Extension   string `json:"extension"`
}

type PositionDeposit struct {
	tableName    struct{} `pg:"position_deposit"`
	BlockNumber      *int   `json:"block_number,omitempty"`
	TransactionIndex *int   `json:"transaction_index,omitempty"`
	EventIndex       *int   `json:"event_index,omitempty"`
	TransactionHash  string `json:"transaction_hash"`
	TokenID          *int   `json:"token_id,omitempty"`
	LowerBound       string `json:"lower_bound"`
	UpperBound       string `json:"upper_bound"`
	PoolKeyHash      string `json:"pool_key_hash"`
	Liquidity        string `json:"liquidity"`
	Delta0           string `json:"delta0"`
	Delta1           string `json:"delta1"`
}

type PositionTransfer struct {
	BlockNumber      *int   `json:"block_number,omitempty"`
	TransactionIndex *int   `json:"transaction_index,omitempty"`
	EventIndex       *int   `json:"event_index,omitempty"`
	TransactionHash  string `json:"transaction_hash"`
	TokenID          *int   `json:"token_id,omitempty"`
	FromAddress      string `json:"from_address"`
	ToAddress        string `json:"to_address"`
}

type Swap struct {
	BlockNumber      *int   `json:"block_number,omitempty"`
	TransactionIndex *int   `json:"transaction_index,omitempty"`
	EventIndex       *int   `json:"event_index,omitempty"`
	TransactionHash  string `json:"transaction_hash"`
	Locker           string `json:"locker"`
	PoolKeyHash      string `json:"pool_key_hash"`
	Delta0           string `json:"delta0"`
	Delta1           string `json:"delta1"`
	SqrtRatioAfter   string `json:"sqrt_ratio_after"`
	TickAfter        string `json:"tick_after"`
	LiquidityAfter   string `json:"liquidity_after"`
}