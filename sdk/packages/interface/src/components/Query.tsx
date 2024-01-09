import React, { useEffect, useState } from 'react';
import { useQuery, gql } from '@apollo/client';
import { Wrap } from "instaswap-core";
import { Provider, constants, cairo, shortString, num } from "starknet";


// Define the TypeScript types for the GraphQL response
type ListLiquidityResponse = {
  list_liquidity: {
    token_id: number;
  }[];
};

// Define the query with the appropriate GraphQL syntax
const GET_LIST_LIQUIDITY = gql`
  query getListLiquidity($account: String!) {
    list_liquidity(account: $account) {
      token_id
    }
  }
`;

// Define the TypeScript type for the component props
type LiquidityListProps = {
  account: string|undefined;
  wrap: Wrap;
};

interface TokenDetails {
  name: string;
  // Include other known properties here
  // propertyX: typeX;
  // propertyY: typeY;
}

const LiquidityList: React.FC<LiquidityListProps> = ({ account }) => {
  // Use the useQuery hook with the response type
  const { loading, error, data } = useQuery<ListLiquidityResponse>(GET_LIST_LIQUIDITY, {
    variables: { account },
  });

  // State to store additional token data
  const [tokenDetails, setTokenDetails] = useState<{ [key: number]: TokenDetails }>({});

  // State to store the fetched JSON data
  const [tokenInfo, setTokenInfo] = useState<{ [key: number]: any }>({});


  useEffect(() => {
    if (data) {
      (async () => {
        try {
          for (const liquidity of data.list_liquidity) {
            const res = await Wrap.getNFTTokenUri(liquidity.token_id);
            const longString = res.map((shortStr: bigint) => {
              return shortString.decodeShortString(num.toHex(shortStr));
            }).join("");

            // Fetch the JSON from the URL
            const response = await fetch(longString);
            const jsonData = await response.json();

            // Update the tokenInfo state with the fetched data
            setTokenInfo((prevTokenInfo) => ({
              ...prevTokenInfo,
              [liquidity.token_id]: jsonData
            }));

            // You can also update your tokenDetails state here if you need to
            // setTokenDetails(...)
          }
        } catch (error) {
          console.error('Error fetching token details:', error);
        }
      })();
    }
  }, [data]);
  if (loading) return <p>Loading...</p>;
  if (error) return <p>An error occurred: {error.message}</p>;

  return (
    <ul>
      {data && data.list_liquidity.map((liquidity, index) => (
        <li key={index}>
          Token ID: {liquidity.token_id}
          {tokenInfo[liquidity.token_id] && (
            <div>
              <p>Name: {tokenInfo[liquidity.token_id].name}</p>
              <p>Description: {tokenInfo[liquidity.token_id].description}</p>
              <img src={tokenInfo[liquidity.token_id].image} alt="Token" />
              {/* Map over the attributes array */}
              {tokenInfo[liquidity.token_id].attributes.map((attribute, attrIndex) => (
                <p key={attrIndex}>{attribute.trait_type}: {attribute.value}</p>
              ))}
            </div>
          )}
        </li>
      ))}
    </ul>
  );
};

export default LiquidityList;