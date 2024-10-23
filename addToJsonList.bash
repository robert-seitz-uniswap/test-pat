#!/bin/bash
source ./menu.sh
source ./getTokenFromApi.bash

function getJsonList {
    chainName=$3
    addNew=Yes
    jsonList="[]"
    names=()
    echo "${names[@]}"
    while [ "$addNew" == "Yes" ]
    do
        read -p "enter address " address
        checksummedAddress=$(node ../../../index.js $address)
        token=$(getTokenFromApi $chainName $address)
        symbol=$(echo $token | jq -r '.symbol')
        decimals=$(echo $token | jq '.decimals')
        name=$(echo $token | jq -r '.name')
        chainId=$(getChainIdFromName $chainName)
        read -p "enter logo url (optional)" logoURI
        
        jsonObject=$( jq -n \
                    --arg ci "$chainId" \
                    --arg ad "$checksummedAddress" \
                    --arg nm "$name" \
                    --arg sm "$symbol" \
                    --arg dc "$decimals" \
                    --arg lg "$logoURI" \
                    '{chainId: $ci, address: $ad, name: $nm, symbol: $sm, decimals: $dc, logoURI: $lg}' )
        jsonList=$(echo $jsonList | jq ". += [${jsonObject}]")
        names=("${names[@]}" "$name")
        echo "${names[@]}"
        addNew=No
        choices=("No" "Yes")
        getChoice -q "Add Another Token?" -o choices -v "addNew"
    done

    eval "$1='$jsonList'"
    echo "${names[@]}"
    eval "$2='${names}'"
}
