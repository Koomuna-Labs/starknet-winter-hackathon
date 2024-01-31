#! /bin/bash

yarn

echo Install scarb
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
scarb --version
echo

echo Download snfoundryup
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
snfoundryup
snforge --version
sncast --version
echo

echo Install starkliup
curl https://get.starkli.sh | sh

echo Install starkli
starkliup
echo
starkli --version

echo Install jq
if [[ "$OSTYPE" =~ ^darwin ]]; then
    brew install jq
fi

if [[ "$OSTYPE" =~ ^linux ]]; then
    sudo apt-get update
    sudo apt-get install jq
fi

cp .env.example .env
