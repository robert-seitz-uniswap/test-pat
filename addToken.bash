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

if [ ! -d /path/to/directory ];
then
  echo 'installing dependencies'
  npm install
fi

if [ ! -d /path/to/directory ];
then
 echo 'cloning'
 git clone $repository
fi

cd ./$folderName/src/tokens
git reset --hard && git checkout main && git pull
files=($(ls -1 | sed -e 's/\..*$//'))
getChoice -q "Select Chain" -o files -v "selectedChain"

chainName=$(getChainIdFromName $selectedChain)
chainId=$(getChainNameFromId $chainName)
getJsonList jsonList names $chainId
cat "./$selectedChain.json" | jq ". += $jsonList" > newfile
mv newfile "./$selectedChain.json"

random=$((1 + $RANDOM % 100))
branchName=add-$(printf '%s-' "${names[@]}")$(date '+%Y-%m-%d')-$random
branchName="${branchName// /_}"

git checkout -b $branchName
npm version minor
git add -u
commitMsg=$(printf 'add %s' "${names[@]}")
git commit -m "$commitMsg"
git push -u -f origin HEAD
gh pr create
git checkout main
