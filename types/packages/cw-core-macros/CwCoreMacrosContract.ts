/**
* This file was automatically generated by cosmwasm-typescript-gen@0.2.14.
* DO NOT MODIFY IT BY HAND. Instead, modify the source JSONSchema file,
* and run the cosmwasm-typescript-gen generate command to regenerate this file.
*/

import { CosmWasmClient, ExecuteResult, SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { Coin, StdFee } from "@cosmjs/amino";
export type VotingQuery = {
  VotingPowerAtHeight: {
    address: string;
    height?: number | null;
    [k: string]: unknown;
  };
} | {
  TotalPowerAtHeight: {
    height?: number | null;
    [k: string]: unknown;
  };
};