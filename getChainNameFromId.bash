#!/bin/bash

function getChainNameFromId { 
if [ ! $1 ]; 
then
    echo "chainId not supplied"
    exit 1
fi

case $1 in
  1)
    echo ETHEREUM
    ;;
  42161)
    echo ARBITRUM
    ;;
  43114)
    echo AVALANCHE
    ;;
  8453)
    echo BASE
    ;;
  56)
    echo BNB
    ;;
  42220)
    echo CELO
    ;;
  10)
    echo OPTIMISM
    ;;
  137)
    echo POLYGON
    ;;
  *)
    echo 'unsupported chainId'
    exit 1
    ;;
esac
}