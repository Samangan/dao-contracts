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

STAKE_CW20_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts/stake_cw20.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')
OLD_STAKE_CW20_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts-old/stake_cw20.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

echo "TX Flags: $TXFLAG"

#### CONTRACT GAS BENCHMARKING ####

instantiate() {
  CONTRACT_NAME=$1
  WASM=$2
  STAKE_CODE=$3
  VERSION=$4

  CODE=$(echo xxxxxxxxx | $BINARY tx wasm store $WASM --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')
  INSTANTIATE_JSON=$(cat $CONTRACT/instantiate/*.json | sed -e s/\$CW20_CODE/$CW20_CODE/g -e s/\$ADDR/$ADDR/g -e s/\$STAKE_CW20_CODE/$STAKE_CODE/g | jq)
  GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm instantiate "$CODE" "$INSTANTIATE_JSON" --from validator $TXFLAG --label "DAO DAO" --output json --no-admin | jq -r '.gas_used')

  mkdir -p gas_usage/$CONTRACT_NAME/instantiate/
  echo $GAS_USED > gas_usage/$CONTRACT_NAME/instatiate/$VERSION
  echo $CODE
}

execute() {
  CODE=$1
  STAKE_CODE=$2
  VERSION=$3

  CONTRACT_ID=$(echo xxxxxxxxx | $BINARY query wasm list-contract-by-code $CODE $NODE --output json | jq -r '.contracts[-1]')
  # Send some coins to the dao contract to init its treasury.
  # Unless this is done the DAO will be unable to perform actions like executing proposals that require it to pay gas fees.
  $BINARY tx bank send validator $CONTRACT_ID 9000000$DENOM --chain-id testing $TXFLAG -y

  EXECUTE_MSG="$CONTRACT/execute/propose.json"
  EXECUTE_JSON=$(cat $EXECUTE_MSG | sed -e s/\$CW20_CODE/$CW20_CODE/g -e s/\$ADDR/$ADDR/g -e s/\$STAKE_CW20_CODE/$STAKE_CODE/g | jq)
  echo $EXECUTE_JSON | jq .
  GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm execute "$CONTRACT_ID" "$EXECUTE_JSON" --from validator $TXFLAG  --output json | jq -r '.gas_used')

  FILE_NAME=`basename $EXECUTE_MSG`
  echo $GAS_USED > gas_usage/$CONTRACT_NAME/execute_$FILE_NAME/$VERSION
}

for CONTRACT in ./scripts/calc_gas/msg_json/*/
do
  CONTRACT_NAME=`basename $CONTRACT`
  echo "Processing Contract: $CONTRACT_NAME"

  CONTRACT_CODE=$(instantiate $CONTRACT_NAME "artifacts/$CONTRACT_NAME.wasm" $STAKE_CW20_CODE "pr")
  OLD_CONTRACT_CODE=$(instantiate $CONTRACT_NAME "artifacts-old/$CONTRACT_NAME.wasm" $OLD_STAKE_CW20_CODE "main")

  $(execute $CONTRACT_CODE $STAKE_CW20_CODE "pr")
  $(execute $OLD_CONTRACT_CODE $OLD_STAKE_CW20_CODE "main")

done