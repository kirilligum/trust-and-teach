#!/usr/bin/env fish
# set -x
set fish_trace 1
source coin_toss_vars.fish

function test_cartesi_voucher
  argparse "p/path=" -- $argv
  or return
  echo "======== $_flag_path $_flag_p "
  set logfile $_flag_path"test.log"
  echo "****logfile: $logfile" &|tee -a $logfile
  docker image inspect coin-toss-contracts >/dev/null 2>&1; and docker image rm coin-toss-contracts; or true
  docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load
  fish -c "docker compose -f docker-compose.yml -f docker-compose.override.yml up"&
  while true
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
    echo "Current block number is $decimal_number."

    set cut_off_block 28

    # Check if the block number is greater than 1
    if test $decimal_number -gt $cut_off_block
      echo "Block number is $decimal_number, which is greater than $cut_off_block."
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER2"
      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER2_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER1"
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545
      curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545

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
end
# test_cartesi_voucher

# docker images && docker ps -a --no-trunc &&  docker volume ls && docker network ls
# docker image rm coin-toss-contracts

# docker stop $(docker ps -aq)
# docker rm $(docker ps -aq) -f
# docker rmi $(docker images -q) -f
# docker volume rm $(docker volume ls -q) -f
# # docker network ls | grep "bridge\|none\|host" | awk '/ / { print $1 }' | xargs -r docker network rm -f
# docker system prune -a --volumes -f
