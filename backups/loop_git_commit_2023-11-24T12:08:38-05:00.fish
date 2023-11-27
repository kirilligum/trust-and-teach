#!/usr/bin/env fish
set -x
export PLAYER1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export PLAYER1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PLAYER2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export PLAYER2_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export COIN_TOSS_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"

set commits_to_test \
557a5b960454baa9e6662e79476391b861b7d5c1 \
ef36f5a3cc3486d4edefbab094434425b6d85ead \

# 99a36b8dc335e27d5223a30d2b00a66fc31ebb2a 


set debug_date (date -Is)
set run_path (pwd)"/runs_history/"
set log_filename $run_path$debug_date"_frontcon.log"
echo "****run_path: $run_path"
echo "****log_filename: $log_filename"




function test_cartesi_voucher
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
      set log_filename $run_path$debug_date"_frontcon.log"
      yarn start notice list &| tee -a $log_filename
      yarn start voucher list &| tee -a $log_filename
      yarn start voucher execute --index 0 --input 0 &| tee -a $log_filename
      cd -

      docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"last_game()\""
      docker compose -f docker-compose.yml -f docker-compose.override.yml down -v

      break
    end

    sleep 10
  end
end

for c in $commits_to_test
  echo "testing commit: $c" &| tee -a $log_filename
  set log_filename $run_path$debug_date"_frontcon.log"
  git checkout $c &| tee -a $log_filename
  git diff --name-status HEAD^ -- ':!* .md' &| tee -a $log_filename
  test_cartesi_voucher
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
