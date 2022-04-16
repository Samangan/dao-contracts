#!/bin/sh

# TODO: Base this off of v1 branch

# Calculate Gas Costs for all contracts
BINARY='junod'
DENOM='ujunox'
CHAIN_ID='testing'
RPC='http://localhost:26657/'
TXFLAG="--gas-prices 0.1$DENOM --gas auto --gas-adjustment 1.5 -y -b block --chain-id $CHAIN_ID --node $RPC"

# TODO HACK: Poll and wait for juno chain to post genesis block instead of sleeping
sleep 60

echo "Calculating Gas For Contracts"

# Download cw20_base.wasm
curl -LO https://github.com/CosmWasm/cw-plus/releases/download/v0.11.1/cw20_base.wasm
# Download c4_group.wasm
curl -LO https://github.com/CosmWasm/cw-plus/releases/download/v0.11.1/cw4_group.wasm

##### UPLOAD CONTRACTS #####

echo "Address to deploy contracts: $1"

### CW20-BASE ###
CW20_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "cw20_base.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

### CW-DAO ###
CW3_DAO_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts/cw3_dao.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')
CW3_DAO_OLD_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts-old/cw3_dao.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

### CW3-MULTISIG ###
CW3_MULTISIG_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts/cw3_multisig.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

### CW4-GROUP ###
CW4_GROUP_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "cw4_group.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

### STAKE-CW20 ###
STAKE_CW20_CODE=$(echo xxxxxxxxx | $BINARY tx wasm store "artifacts/stake_cw20.wasm" --from validator $TXFLAG --output json | jq -r '.logs[0].events[-1].attributes[0].value')

echo "TX Flags: $TXFLAG"

#### CONTRACT GAS BENCHMARKING ####

##### CW3-dao #####

# TODO: 
# * Write each contract json's instatiate, execute message, and query in separate json files
# * Load them here and then use it to calculate gas for each operation
# * Write gas cost to a yaml file for now

# Just testing this manually to see if we can see gas costs before making this all nice
# Instantiate a DAO contract instantiates its own cw20
CW3_DAO_INIT='{
  "name": "DAO DAO",
  "description": "A DAO that makes DAO tooling",
  "gov_token": {
    "instantiate_new_cw20": {
      "cw20_code_id": '$CW20_CODE',
      "label": "DAO DAO v0.1.1",
      "initial_dao_balance": "1000000000",
      "msg": {
        "name": "daodao",
        "symbol": "DAO",
        "decimals": 6,
        "initial_balances": [{"address":"'"$1"'","amount":"1000000000"}]
      }
    }
  },
  "staking_contract": {
    "instantiate_new_staking_contract": {
      "staking_contract_code_id": '$STAKE_CW20_CODE'
    }
  },
  "threshold": {
    "absolute_percentage": {
        "percentage": "0.5"
    }
  },
  "max_voting_period": {
    "height": 100
  },
  "proposal_deposit_amount": "0",
  "only_members_execute": false,
  "automatically_add_cw20s": true
}'
echo $CW3_DAO_INIT | jq .

GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm instantiate "$CW3_DAO_OLD_CODE" "$CW3_DAO_INIT" --from validator --label "DAO DAO" $TXFLAG --output json --no-admin | jq -r '.gas_used')
echo "CW3_DAO_INIT gas used (old commit): $GAS_USED"

GAS_USED=$(echo xxxxxxxxx | $BINARY tx wasm instantiate "$CW3_DAO_CODE" "$CW3_DAO_INIT" --from validator --label "DAO DAO" $TXFLAG --output json --no-admin | jq -r '.gas_used')

echo "CW3_DAO_INIT gas used (new commit): $GAS_USED"

