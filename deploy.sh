#!/bin/bash

# deploys a BridgedSuperTokenProxy
# usage: deploy.sh <type> <network>
#    type: L1, L2, OP
#    env vars PRIVKEY and OWNER needs to be set
#    PRIVKEY: private key of the deployer
#    OWNER: owner of the initial supply and/or upgradeable proxy
#    env var <explorer>_API_KEY needed for verification
#    additional env vars which have a default for testing: NAME, SYMBOL
#    additional env vars needed for type L1, having a default for testing: INITIAL_SUPPLY (whole tokens)
#    additional env vars needed for type OP: NATIVE_BRIDGE (0x4200000000000000000000000000000000000010), REMOTE_TOKEN
#    env vars can be provided via .env file

set -eu

echo "!! note that env vars from .env take precedence over the ones set in the shell !!"
source .env

type=$1
network_name=$2

# default token name & symbol
export NAME=${NAME:-"Test Token"}
export SYMBOL=${SYMBOL:-"TTT"}

# get network metadata
metadata=$(curl -s "https://raw.githubusercontent.com/superfluid-finance/protocol-monorepo/dev/packages/metadata/networks.json")
network=$(echo "$metadata" | jq -r '.[] | select(.name == "'$network_name'")')
factory=$(echo "$network" | jq -r '.contractsV1.superTokenFactory')

# verify chain id
rpc_url=${RPC:-"https://$network_name.rpc.x.superfluid.dev?app=deployer"}
connected_chain_id_hex=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' $rpc_url | jq -r '.result')
connected_chain_id=$(printf "%d" $connected_chain_id_hex)
expected_chain_id=$(echo "$network" | jq -r '.chainId')
if [ "$connected_chain_id" != "$expected_chain_id" ]; then
    echo "chain id mismatch: expected $expected_chain_id, connected to $connected_chain_id"
    exit 1
fi

# get explorer api key
explorer_url=$(echo "$network" | jq -r '.explorer')
explorer_api_key_name=$(echo $explorer_url | sed -E 's|https://(.*)\..*|\U\1_API_KEY|g' | sed 's/\./_/g' | sed 's/\-/_/g')
fallback_explorer_api_key_name=$(echo $explorer_api_key_name | sed 's/^[^_]*_//')
explorer_api_key=${!explorer_api_key_name:-${!fallback_explorer_api_key_name}}

echo "Network: $network_name"
echo "Type: $type"
echo "Token Name: $NAME"
echo "Token Symbol: $SYMBOL"
echo "Owner: $OWNER"

multiply_by_10e18() {
    echo "$(echo "$1 * 1000000000000000000" | bc)"
}

if [ "$type" == "L1" ]; then
    export INITIAL_SUPPLY=$(multiply_by_10e18 ${INITIAL_SUPPLY:-1000000}) # default: 1M tokens

    echo "deploying L1 token"
    forge script --rpc-url $rpc_url --broadcast --verify --etherscan-api-key $explorer_api_key script/Deploy.s.sol:DeployL1Token
elif [ "$type" == "L2" ]; then
    export INITIAL_SUPPLY=$(multiply_by_10e18 ${INITIAL_SUPPLY:-0}) # default: 0
    echo "Initial Supply: $INITIAL_SUPPLY"

    echo "deploying L2 token (bridged Super Token with xERC20 support)"
    SUPERTOKEN_FACTORY=$factory forge script --rpc-url $rpc_url --broadcast --verify --etherscan-api-key $explorer_api_key script/Deploy.s.sol:DeployL2Token
elif [ "$type" == "OP" ]; then
    # will succeed only if REMOTE_TOKEN is set
    export NATIVE_BRIDGE=${NATIVE_BRIDGE:-"0x4200000000000000000000000000000000000010"}
    export INITIAL_SUPPLY=$(multiply_by_10e18 ${INITIAL_SUPPLY:-0}) # default: 0
    echo "Initial Supply: $INITIAL_SUPPLY"
    echo "Remote Token: $REMOTE_TOKEN"
    echo "Native Bridge: $NATIVE_BRIDGE"

    echo "deploying OP token (bridged Super Token with xERC20 and native OP bridge support)"
    SUPERTOKEN_FACTORY=$factory forge script --rpc-url $rpc_url --broadcast --verify --etherscan-api-key $explorer_api_key script/Deploy.s.sol:DeployOPToken
else
    echo "invalid type: $type"
    exit 1
fi
