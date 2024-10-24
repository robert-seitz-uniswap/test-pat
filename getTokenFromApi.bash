#!/bin/bash
function getTokenFromApi {
    chain=$1

    checksummedAddress=$(node ../../../index.js $2)
    jqinput='{"query":"query Token($chain: Chain!, $address: String = null) {\n  token(chain: $chain, address: $address) {\n    address\n    symbol\n    decimals\n    name\n  }\n}","variables":{"chain":"ETHEREUM","address":"0xC2dd6A37f1692b2f7E794aB8bDAC5493D2F1aC6d"}}'
    payload=$(jq ".variables.address=\"$checksummedAddress\" | .variables.chain=\"$chain\"" <<< $jqinput)
    curloutput=$(curl -s --location 'https://api.uniswap.org/v1/graphql' \
                        --header 'accept: */*' \
                        --header 'content-type: application/json' \
                        --header 'origin: https://app.uniswap.org' \
                        --data "$payload")
    echo $(jq '.data.token' <<< $curloutput)
}
