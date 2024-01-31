#! /bin/bash
source .env

echo Create Account
starkli account oz init --private-key ${PRIVATE_KEY} keys
starkli account deploy account --private-key ${PRIVATE_KEY} --network ${STARKNET_NETWORK}
