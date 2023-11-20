package utils

import "math/big"

func Hex2BigNum(hexStr string)string{
	if len(hexStr) > 2 && hexStr[:2] == "0x" {
		hexStr = hexStr[2:]
	}

	bigNum := new(big.Int)
	bigNum.SetString(hexStr, 16)
	return bigNum.String()
}
