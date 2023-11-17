docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
docker images && docker ps -a --no-trunc &&  docker volume ls && docker network ls

docker stop $(docker ps -aq)
docker rm $(docker ps -aq) -f
docker rmi $(docker images -q) -f
docker volume rm $(docker volume ls -q) -f
# docker network ls | grep "bridge\|none\|host" | awk '/ / { print $1 }' | xargs -r docker network rm -f
docker system prune -a --volumes -f

cd
sudo rm -rf tmp
mkdir tmp
cd tmp
git clone git@github.com:prototyp3-dev/coin-toss.git
git clone git@github.com:cartesi/rollups-examples.git

# termianl 1
cd ~/tmp/coin-toss
sed -i "s/CoinToss/TrustAndTeach/g" docker-compose.override.yml contracts/src/localhost/coin-toss.sol
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load && docker compose -f docker-compose.yml -f docker-compose.override.yml up

# terminal 2
cd ~/tmp/coin-toss
export PLAYER1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export PLAYER1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PLAYER2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export PLAYER2_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export COIN_TOSS_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"

docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"set_dapp_address(address)\" $DAPP_ADDRESS"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER1_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER2"
docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast send --private-key $PLAYER2_PRIVATE_KEY --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"play(address)\" $PLAYER1"
curl --data '{"id":1337,"jsonrpc":"2.0","method":"evm_increaseTime","params":[864010]}' http://localhost:8545

rm ../rollups-examples/deployments/localhost
ln -s ~/tmp/coin-toss/deployments/* ~/tmp/rollups-examples/deployments/
cd ../rollups-examples/frontend-console/
yarn && yarn build
yarn start notice list && yarn start voucher list
yarn start voucher execute --index 0 --input 0
cd -

docker run --rm --net="host" ghcr.io/foundry-rs/foundry "cast call --rpc-url $RPC_URL $COIN_TOSS_ADDRESS \"last_game()\""
