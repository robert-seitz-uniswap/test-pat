export function getChainNameFromId(chainId) {
  if (!chainId) {
    throw new Error("chainId not supplied");
  }

  switch (Number(chainId)) {
    case 1:
      return "ETHEREUM";
    case 42161:
      return "ARBITRUM";
    case 43114:
      return "AVALANCHE";
    case 8453:
      return "BASE";
    case 56:
      return "BNB";
    case 42220:
      return "CELO";
    case 10:
      return "OPTIMISM";
    case 137:
      return "POLYGON";
    default:
      throw new Error("unsupported chainId");
  }
}
