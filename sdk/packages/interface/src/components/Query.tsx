import React from 'react';
import { useQuery, gql } from '@apollo/client';

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
  account: string;
};

const LiquidityList: React.FC<LiquidityListProps> = ({ account }) => {
  // Use the useQuery hook with the response type
  const { loading, error, data } = useQuery<ListLiquidityResponse>(GET_LIST_LIQUIDITY, {
    variables: { account },
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>An error occurred: {error.message}</p>;

  return (
    <ul>
      {data && data.list_liquidity.map((liquidity, index) => (
        <li key={index}>Token ID: {liquidity.token_id}</li>
      ))}
    </ul>
  );
};

export default LiquidityList;