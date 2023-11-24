export PLAYER1="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
export PLAYER1_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export PLAYER2="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
export PLAYER2_PRIVATE_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
export COIN_TOSS_ADDRESS="0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1"
export DAPP_ADDRESS="0x70ac08179605AF2D9e75782b8DEcDD3c22aA4D0C"
export RPC_URL="http://localhost:8545"

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

    # Check if the block number is greater than 1
    if test $decimal_number -gt 1
        echo "Block number is $decimal_number, which is greater than 1."
        break
    end

    sleep 10
end

