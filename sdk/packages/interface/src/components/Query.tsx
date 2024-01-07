import React, { useEffect, useState } from 'react';
import { useQuery, gql } from '@apollo/client';
import { Wrap } from "instaswap-core";

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

  useEffect(() => {
    if (data) {
      (async () => {
        try {
          for (const liquidity of data.list_liquidity) {
            const ret = await Wrap.getNFTTokenUri(liquidity.token_id);
            console.log(ret.toString());
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
          {tokenDetails[liquidity.token_id] && (
            <div>
              <p>Name: {tokenDetails[liquidity.token_id].name}</p>
              {/* Add more details here as required */}
            </div>
          )}
        </li>
      ))}
    </ul>
  );
};

export default LiquidityList;