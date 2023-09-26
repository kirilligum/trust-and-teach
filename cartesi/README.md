### Setup LLM

download stories15m.bin model weights into the directory that creates Cartesi machine with LLM

```bash
cd stories15m
wget https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
```

Install docker check that it supports qemu (https://docs.cartesi.io/cartesi-rollups/build-dapps/run-dapp/)

```bash
docker buildx ls

```

If you do not see linux/riscv64 in the platforms list, install QEMU by running:


```bash
apt install qemu-user-static
```

Build the docker that will create the machine and the interaction with the evm

```bash
docker buildx bake --load
```

Start the Cartesi machine

```bash
docker compose -f ../docker-compose.yml -f ./docker-compose.override.yml up
```

To interact with the Cartesi machine, we need to use front-end console.

use https://github.com/dhood/rollups-examples/tree/main/frontend-console

```bash
cd ../frontend-console/
yarn
yarn build
```

Here is how to send the start of the story to the LLM that is inside Cartesi

```bash
yarn start input send --payload 'Long time ago there was a lake'
```

To see the output that will be on the EVM chain after finalizing the epoch, use 

```bash
yarn start notice list
```

To shutdown the Cartesi machine docker, use

```bash
cd ../stories15m
docker compose -f ../docker-compose.yml -f ./docker-compose.override.yml down -v

```
