import { InjectedConnector, StarknetConfig } from "@starknet-react/core";
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { ApolloProvider } from '@apollo/client';
import client from './apollo-client';


const connectors = [
  new InjectedConnector({ options: { id: "braavos" } }),
  new InjectedConnector({ options: { id: "argentX" } }),
];

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <ApolloProvider client={client}>
      {/* Wrap App with StarknetConfig */}
      <StarknetConfig autoConnect connectors={connectors}>
        <App />
      </StarknetConfig>
    </ApolloProvider>
  </React.StrictMode>,
);
