

import {
    Account,
    Contract,
    DeclareDeployUDCResponse,
    DeployTransactionReceiptResponse,
    Provider,
    TransactionType,
    cairo,
    contractClassResponseToLegacyCompiledContract,
    ec,
    extractContractHashes,
    hash,
    num,
    parseUDCEvent,
    shortString,
    stark,
    constants
  } from 'starknet';
import {describe, expect, test, beforeAll} from '@jest/globals';

import {Wrap} from './wrap';


const { cleanHex, hexToDecimalString, toBigInt, toHex } = num;
const { encodeShortString } = shortString;
const { randomAddress } = stark;
const { uint256 } = cairo;
const { Signature } = ec.starkCurve;


const DEFAULT_TEST_ACCOUNT_ADDRESS =
  '0x41a44af91dce40db477e72b1c69ee440333b70acca5d973644ed2f9983d8990';
const DEFAULT_TEST_ACCOUNT_PUBLIC_KEY = '0x61e0c11613e66dd0364c2fca21db1c728e8d6b4e8a57a8a128755dd17b4a9b2';
const DEFAULT_TEST_ACCOUNT_PRIVATE_KEY = '0x69cb61a345cbb5b67f134a931eacede43d6c07407bb6384a15f663159bb184f';

const erc1155_address = "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6";
const werc20_address = "0x06b09e4c92a08076222b392c77e7eab4af5d127188082713aeecbe9013003bf4";
const eth_address = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";
const ekubo_nft_address = "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc";
describe('deploy and test Wallet', () => {
    let testAccountAddress = DEFAULT_TEST_ACCOUNT_ADDRESS;
    let testAccountPrivateKey = DEFAULT_TEST_ACCOUNT_PRIVATE_KEY;
    const provider = new Provider({ sequencer: { network: constants.NetworkName.SN_GOERLI } });
    const account = new Account(provider, toHex(testAccountAddress), testAccountPrivateKey, '0');
    


    let wrap = new Wrap(
        erc1155_address,
        werc20_address,
        eth_address,
        ekubo_nft_address
    );


    test('test add liquidity', async () => {
        const { transaction_hash } = await account.execute(wrap.addLiquidity(1));
        const receipt = await account.waitForTransaction(transaction_hash);
        
    });

  });