#!/bin/sh

# TODO: Base this off of v1 branch

# Calculate Gas Costs for all contracts
BINARY='junod'
DENOM='ujunox'
CHAIN_ID='testing'
RPC='http://localhost:26657/'
TXFLAG="--gas-prices 0.1$DENOM --gas auto --gas-adjustment 1.5 -y -b block --chain-id $CHAIN_ID --node $RPC"
ADDR=$1

echo "Calculating Gas For Contracts"
echo "Address to deploy contracts: $ADDR"

# TODO HACK: Poll and wait for juno chain to post genesis block instead of sleeping
sleep 60

##### UPLOAD DEPENDENCIES #####
curl -LO https://github.com/CosmWasm/cw-plus/releases/download/v0.11.1/cw20_base.wasm
curl -LO https://github.com/CosmWasm/cw-plus/releases/download/v0.11.1/cw4_group.wasm

CW20_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "cw20_base.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')
CW4_GROUP_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "cw4_group.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

echo "TX Flags: $TXFLAG"

#### CONTRACT GAS BENCHMARKING ####

for CONTRACT in ./scripts/calc_gas_json/*/
do
  CONTRACT_NAME=`basename $CONTRACT`
  echo "Processing Contract: $CONTRACT_NAME"

  # Store old and new versions:
  CONTRACT_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts/$CONTRACT_NAME.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')
  OLD_CONTRACT_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts-old/$CONTRACT_NAME.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

  # Instatiate old and new versions:
  # TODO: Support multiple instatiate json files
  INSTANTIATE_JSON=`cat $CONTRACT/instantiate/*.json | jq`
  echo $INSTANTIATE_JSON | jq .

  mkdir -p gas_usage/$CONTRACT_NAME

  GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm instantiate "$CONTRACT_CODE" "$INSTANTIATE_JSON" --from validator $TXFLAG --label "DAO DAO" --output json --no-admin | jq -r '.gas_used')
  echo "$CONTRACT_NAME gas used (new commit): $GAS_USED"

  OLD_GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm instantiate "$OLD_CONTRACT_CODE" "$INSTANTIATE_JSON" --from validator $TXFLAG --label "DAO DAO" --output json --no-admin | jq -r '.gas_used')
  echo "$CONTRACT_NAME gas used (old commit): $OLD_GAS_USED"

  jq -n --arg n "$GAS_USED" --arg o "$OLD_GAS_USED" '{"pr": $n, "main": $o}' > gas_usage/$CONTRACT_NAME/instatiate.json

  # TODO: Execute

  # TODO: Query

done