import { useAccount, useConnectors } from "@starknet-react/core";
import { useMemo } from "react";
import ButtonClick from "./ButtonClick";

function WalletConnected() {
  const { address } = useAccount();
  const { disconnect } = useConnectors();

  const shortenedAddress = useMemo(() => {
    if (!address) return "";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }, [address]);

  return (
    <div>
      <span>Connected: {shortenedAddress}</span>
      <button onClick={disconnect}>Disconnect</button>
      <ButtonClick />
    </div>
  );
}

function ConnectWallet() {
  const { connectors, connect } = useConnectors();

  return (
    <div>
      <span>Choose a wallet:</span>
      {connectors.map((connector) => {
        return (
          <button key={connector.id} onClick={() => connect(connector)}>
            {connector.id}
          </button>
        );
      })}
    </div>
  );
}

export default function WalletBar() {
  const { address } = useAccount();

  return address ? <WalletConnected /> : <ConnectWallet />;
}
