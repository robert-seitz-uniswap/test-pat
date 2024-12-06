#!/bin/bash

# git, github cli, npm? (npm version minor)
# setup ssh key?

clear
source ./menu.sh
source ./addToJsonList.bash
source ./getChainIdFromName.bash
source ./getChainNameFromId.bash

choices=("default" "extended" "unsupported")
getChoice -q "Select List" -o choices -v "selectedChoice"

case $selectedChoice in 
 default)
  repository=git@github.com:Uniswap/default-token-list.git
  folderName=default-token-list
  ;;
 extended)
  repository=git@github.com:Uniswap/extended-token-list.git
  ;;
 unsupported)
  repository=git@github.com:Uniswap/unsupported-token-list.git
  ;;
esac

folderName=${repository#*Uniswap/}
folderName=${folderName%.git*}

if [ ! -d node_modules ];
then
  echo 'installing dependencies'
  npm install
fi

if [ ! -d $repository ];
then
 echo 'cloning'
 git clone $repository
fi

cd ./$folderName/src/tokens
git reset --hard && git checkout main && git pull
files=($(ls -1 | sed -e 's/\..*$//'))

addAnotherChain="Yes"
allNames=()
names=()
while [ "$addAnotherChain" == "Yes" ]
do
  getChoice -q "Select Chain" -o files -v "selectedChain"
  chainName=$(getChainIdFromName $selectedChain)
  chainId=$(getChainNameFromId $chainName)
  getJsonList jsonList names $chainId
  cat "./$selectedChain.json" | jq ". += $jsonList" > newfile
  mv newfile "./$selectedChain.json"
  allNames+=("${names[@]}")
  # if [ ${#allNames[@]} -eq 0 ]; then
  #   echo "No errors, hooray"
  # else
  #   echo "Oops, something went wrong..."
  # fi

  echo $allNames
  choices=("No" "Yes")
  getChoice -q "Modify Another Chain?" -o choices -v "addAnotherChain"
done

random=$((1 + $RANDOM % 100))
branchName=add-$(printf '%s-' "${allNames[@]}")$(date '+%Y-%m-%d')-$random
branchName="${branchName// /_}"

git checkout -b $branchName
git add -u
commitMsg=$(printf 'add %s' "${names[@]}")
git commit -m "$commitMsg"
npm version minor
git push -u -f origin HEAD
gh pr create
git checkout main
