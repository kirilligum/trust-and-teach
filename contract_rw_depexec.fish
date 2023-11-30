#!/usr/bin/env fish
set -x
set fish_trace 1
source  ../contract_rw_vars.fish

# print hello

function test_cartesi_voucher
  argparse "p/path=" -- $argv
  or return
  echo "======== $_flag_p "
  set logfile $_flag_path"test.log"
  echo "**** logfile: $logfile" &|tee -a $logfile
  if not docker version >/dev/null
    echo "docker isn't running :-("  &| tee -a $logfile
    return
  end
  docker image inspect coin-toss-contracts >/dev/null 2>&1; and docker image rm coin-toss-contracts; or true
  docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
  fish -c "docker compose -f docker-compose.yml -f docker-compose.override.yml up"&
  while true
    if not docker version >/dev/null
      echo "docker isn't running :-( (in the while block loop)"  &| tee -a $logfile
      return
    end
    set hex_response (curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL 2>/dev/null)
    # Check if the response is empty (server might not be running)
    if test -z "$hex_response"
      echo "RPC server not available. Retrying in 10 seconds..."
      sleep 10
      continue
    end

    # Process response
    set hex_number (echo $hex_response | jq -r .result)
    set decimal_number (math $hex_number)
    echo "Current block number is $decimal_number. log: $_flag_p"

    set cut_off_block_load 28 # by this time, all should be loaded

    # Check if the block number is greater than 1
    if test $decimal_number -gt $cut_off_block_load
      echo "Block number is $decimal_number, which is greater than $cut_off_block."
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER2"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER2_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER1"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address,string)\" $PLAYER2 \"hi\""
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $player2_private_key --rpc-url $rpc_url $coin_toss_address \"play(address,string)\" $player1 \"byr\""
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"sendInstructionPrompt(string)\" \"heeeeieeeyy\""
      echo "+++++ conversations: "
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"conversations()\""
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
      break
    end

    sleep 10
  end

  while true
    if not docker version >/dev/null
      echo "docker isn't running :-( (in the while block loop)"  &| tee -a $logfile
      return
    end
    set hex_response (curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL 2>/dev/null)
    # Check if the response is empty (server might not be running)
    if test -z "$hex_response"
      echo "front end RPC server not available. Retrying in 10 seconds..."
      sleep 10
      continue
    end

    # Process response
    set hex_number (echo $hex_response | jq -r .result)
    set decimal_number (math $hex_number)
    echo "Current block number is $decimal_number."

    set cut_off_block_interaction_wait 38 # by this time, all should be loaded
    if test $decimal_number -gt $cut_off_block_interaction_wait
      cd ../rollups-examples/frontend-console/
      # yarn && yarn build
      yarn start notice list &| tee -a $logfile
      yarn start voucher list &| tee -a $logfile
      yarn start voucher execute --index 0 --input 0 &| tee -a $logfile
      cd -

      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"last_game()\""
      docker compose -f docker-compose.yml -f docker-compose.override.yml down -v

      break
    end

    sleep 10
  end
  echo "**** logfile: $logfile" &|tee -a $logfile
end
