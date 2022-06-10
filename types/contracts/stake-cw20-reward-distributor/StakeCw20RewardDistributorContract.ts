/**
* This file was automatically generated by cosmwasm-typescript-gen@0.2.14.
* DO NOT MODIFY IT BY HAND. Instead, modify the source JSONSchema file,
* and run the cosmwasm-typescript-gen generate command to regenerate this file.
*/

import { CosmWasmClient, ExecuteResult, SigningCosmWasmClient } from "@cosmjs/cosmwasm-stargate";
import { Coin, StdFee } from "@cosmjs/amino";
export type Uint128 = string;
export interface InstantiateMsg {
  owner: string;
  reward_rate: Uint128;
  reward_token: string;
  staking_addr: string;
  [k: string]: unknown;
}
export interface StakeCw20RewardDistributorReadOnlyInterface {
  contractAddress: string;
  info: () => Promise<InfoResponse>;
}
export class StakeCw20RewardDistributorQueryClient implements StakeCw20RewardDistributorReadOnlyInterface {
  client: CosmWasmClient;
  contractAddress: string;

  constructor(client: CosmWasmClient, contractAddress: string) {
    this.client = client;
    this.contractAddress = contractAddress;
    this.info = this.info.bind(this);
  }

  info = async (): Promise<InfoResponse> => {
    return this.client.queryContractSmart(this.contractAddress, {
      info: {}
    });
  };
}
export interface StakeCw20RewardDistributorInterface extends StakeCw20RewardDistributorReadOnlyInterface {
  contractAddress: string;
  sender: string;
  updateConfig: ({
    owner,
    rewardRate,
    rewardToken,
    stakingAddr
  }: {
    owner: string;
    rewardRate: Uint128;
    rewardToken: string;
    stakingAddr: string;
  }, fee?: number | StdFee | "auto", memo?: string, funds?: readonly Coin[]) => Promise<ExecuteResult>;
  distribute: (fee?: number | StdFee | "auto", memo?: string, funds?: readonly Coin[]) => Promise<ExecuteResult>;
  withdraw: (fee?: number | StdFee | "auto", memo?: string, funds?: readonly Coin[]) => Promise<ExecuteResult>;
}
export class StakeCw20RewardDistributorClient extends StakeCw20RewardDistributorQueryClient implements StakeCw20RewardDistributorInterface {
  client: SigningCosmWasmClient;
  sender: string;
  contractAddress: string;

  constructor(client: SigningCosmWasmClient, sender: string, contractAddress: string) {
    super(client, contractAddress);
    this.client = client;
    this.sender = sender;
    this.contractAddress = contractAddress;
    this.updateConfig = this.updateConfig.bind(this);
    this.distribute = this.distribute.bind(this);
    this.withdraw = this.withdraw.bind(this);
  }

  updateConfig = async ({
    owner,
    rewardRate,
    rewardToken,
    stakingAddr
  }: {
    owner: string;
    rewardRate: Uint128;
    rewardToken: string;
    stakingAddr: string;
  }, fee: number | StdFee | "auto" = "auto", memo?: string, funds?: readonly Coin[]): Promise<ExecuteResult> => {
    return await this.client.execute(this.sender, this.contractAddress, {
      update_config: {
        owner,
        reward_rate: rewardRate,
        reward_token: rewardToken,
        staking_addr: stakingAddr
      }
    }, fee, memo, funds);
  };
  distribute = async (fee: number | StdFee | "auto" = "auto", memo?: string, funds?: readonly Coin[]): Promise<ExecuteResult> => {
    return await this.client.execute(this.sender, this.contractAddress, {
      distribute: {}
    }, fee, memo, funds);
  };
  withdraw = async (fee: number | StdFee | "auto" = "auto", memo?: string, funds?: readonly Coin[]): Promise<ExecuteResult> => {
    return await this.client.execute(this.sender, this.contractAddress, {
      withdraw: {}
    }, fee, memo, funds);
  };
}