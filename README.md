# Trust-and-Teach AI DApp

Reinforcement learning with human feedback (RLHF) on-chain, leverging on-chain trust, scalability, transparensy, and reputation.

[Video of using this project https://www.youtube.com/watch?v=LazBNDzf0e0](https://www.youtube.com/watch?v=LazBNDzf0e0)

<!--START_SECTION:update_image-->
<img src="./diagrams/usersequence.mmd.svg?jl">
<!--END_SECTION:update_image-->

Note, this work is a proof of concept.

## Features

- runs a large language model (LLM) inference in an optimistic roll-up
- on-chain ranking of multiple responses to create RLHF dataset
- tracking of LLM version and licenses

## Motivation

Higher accuracy for specific application as well as a practical interface, such as chat, of large language models (LLMs) comes from supervised fine-tuning (SFT) and RLHF [A Survey of Large Language Models (2023)](https://arxiv.org/abs/2303.18223).
In RLHF, a human ranks responses from the same prompt of an already fine-tuned model. 
These ranks are used to fine-tune the LLM.
In this project we get 2 inferences from on-chain LLM and allow the users to rank which of the two responses is better.
The next step would be to fine-tune the model using the dataset generated by this project.

The impact of this project is two-fold.
1. The last step in fine-tuning LLM, RLHF and its variants, are the most crucial for alignment and specialization -- this step requires the most trust.
Running this process deterministically on-chain allows to have trusted specialized alligned LLMs.
1. Although there are a few projects running LLM on-chain opML/Agatha, zkML, Zama's FHE NN. 
This project integrates with the largest and most secure smart-contract network -- Ethereum.
This project also levereges well developed and decentralized network of nodes.

The future vision of this project is to impact both AI and blockchain.
Leveraging the security and payment capability of Ethereum we can create a decentralized economy for data labeling and creating training data for AI, where labelers and reviewers get paid from a DAO grant.
As for impacting blockchain, specifically focusing on DAOs, we can have AI delegates that are trained and aligned in a trusted way to reflect the vision of the delegator; these AI delegates can solve the problem of lack of participation in DAO voting.

## How it works
The LLM runs as an oprimistic rollup onto EVM chain.
Cartesi VM allows running linux applications, in our case, we run llama2.c with stories15m model.
The Cartesi Rollup infrastructure optimistically executes the transitions between the states of the Cartesi VM.
After finishing running the LLM, Cartesi creates vouchers. 
These vouchers allow to validate and post the result of running the LLM on to the EVM; for that the vouchers need to be executed as an EVM transaction.

## User flow
1. Enter the prompt and run 2 LLM **inferences** by clicking "Generate" button and signing the transaction.
    1. (optionally) enter the total number of tokens that llm will work with = tokens you entered + tokens that LLM will generate
1. When LLM is done, you will see "Off-chain" reponses in the table. You will need to wait for the voucher proofs to be ready. Once the proofs are ready, you can **post** the LLM responses on to the chain by clicking "Post 0" and "Post 1".
1. Now you can **rank** the responses. If you like the order of the responses, you can click "Confirm" if you prefer to switch them, you can click "Switch".
1. When you looped over the previous steps enough times to have a dataset, you can download the dataset as a TSV or JSON. Next you can do the RLHF fine-tuning of the model using other projects.

## Deploy the contract and Cartesi

Clone this repo and its submodules that are repsonsible for backend and front-end.

```shell
git clone --recurse-submodules git@github.com:kirilligum/trust-and-teach.git
```

### local

Build and run the Cartesi VM and the local chain with a deployed contract

```shell

```shell
cd trust-and-teach-cartesi
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
docker compose -f docker-compose.yml -f docker-compose.override.yml up
```

Shut down and clean docker containers up after you are done
```shell
docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
```

Next, we will use a front-end to interact with the dapp. You can also interact through a command line by following the instrucations in ./trust-and-teach-cartesi/README.md. 

You can return to the parent folder:
```shell
cd ..
```


## Run front-end


```shell
cd trust-and-teach-cartesi-frontend
yarn
solc --abi --optimize --base-path . --include-path node_modules/ ../trust-and-teach-cartesi/contracts/src/localhost/trust-and-teach.sol -o src/contract_abi/
cd src/contract_abi/
mv TrustAndTeach.abi TrustAndTeach.json
yarn codegen
yarn start
```

Open [http://localhost:3000](http://localhost:3000) to view it in the browser.
Click on "Show Instructions" button to see the instructions for the front-end.

Note that to execute Vouchers, the voucher epoch must be finalized so the rollups framework generate the proofs.
As a reminder, you can advance time in hardhat with the command:

```shell
curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
```

## Limitation

- Cartesi currently does not suport vectorization. the inference is 10_000x slower than on CPU.
- Currently, there is a problem running more than 90 tokens
