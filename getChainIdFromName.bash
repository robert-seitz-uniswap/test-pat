#!/bin/bash

function getChainIdFromName { 
if [ ! $1 ]; 
then
    echo "chainId not supplied"
    exit 1
fi

case $1 in
  ethereum|mainnet|ETHEREUM)
    echo 1
    ;;
  arbitrum|ARBITRUM)
    echo 42161
    ;;
  avalanche|AVALANCHE)
    echo 43114
    ;;
  base|BASE)
    echo 8453
    ;;
  binance|BNB)
    echo 56
    ;;
  celo|CELO)
    echo 42220
    ;;
  optimism|OPTIMISM)
    echo 10
    ;;
  polygon|POLYGON)
    echo 137
    ;;
  *)
    echo 'unsupported chainId'
    exit 1
    ;;
esac
}