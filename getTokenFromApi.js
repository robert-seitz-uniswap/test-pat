import { ethers } from "ethers";

export async function getTokenFromApi(chain, address) {
  // Get checksummed address (assuming the checksum function is imported)
  const checksummedAddress = getChecksumAddress(address);

  // Construct the GraphQL query
  const query = {
    query: `query Token($chain: Chain!, $address: String = null) {
            token(chain: $chain, address: $address) {
                address
                symbol
                decimals
                name
            }
        }`,
    variables: {
      chain: chain,
      address: checksummedAddress,
    },
  };

  // Make the API request
  const response = await fetch("https://api.uniswap.org/v1/graphql", {
    method: "POST",
    headers: {
      accept: "*/*",
      "content-type": "application/json",
      origin: "https://app.uniswap.org",
    },
    body: JSON.stringify(query),
  });

  const data = await response.json();
  return data.data.token;
}

const getChecksumAddress = (address) => {
  try {
    const checksummed = ethers.getAddress(address);
    return checksummed;
  } catch (e) {
    process.stderr.write(e.toString());
    throw e;
  }
};

await getTokenFromApi("ETHEREUM", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48");
