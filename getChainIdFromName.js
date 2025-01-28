export function getChainIdFromName(chainName) {
  if (!chainName) {
    throw new Error("chainId not supplied");
  }

  switch (chainName.toLowerCase()) {
    case "ethereum":
    case "mainnet":
      return 1;
    case "arbitrum":
      return 42161;
    case "avalanche":
      return 43114;
    case "base":
      return 8453;
    case "binance":
    case "bnb":
      return 56;
    case "celo":
      return 42220;
    case "optimism":
      return 10;
    case "polygon":
      return 137;
    default:
      throw new Error("unsupported chainId");
  }
}
