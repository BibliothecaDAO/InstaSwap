// src/apollo-client.ts
import { ApolloClient, InMemoryCache, HttpLink } from '@apollo/client';

// Define your GraphQL server URL here
const GRAPHQL_URL = 'https://instaswap-api.metaforo.io/query';

const httpLink = new HttpLink({
  uri: GRAPHQL_URL,
});

// Create the Apollo Client instance
const client = new ApolloClient({
  link: httpLink,
  cache: new InMemoryCache(),
});

export default client;