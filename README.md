# trust-and-teach


## contract and ui

after modifying a contract

```
cd trust-and-teach-cartesi
docker compose -f docker-compose.yml -f docker-compose.override.yml down -v ; docker image rm trust-and-teach-cartesi-contracts
docker buildx bake -f docker-bake.hcl -f docker-bake.override.hcl --load && docker compose -f docker-compose.yml -f docker-compose.override.yml up
solc --abi --optimize --base-path . --include-path node_modules/ ../trust-and-teach-cartesi/contracts/src/localhost/trust-and-teach.sol -o src/contract_abi/
cd src/contract_abi/
mv TrustAndTeach.abi TrustAndTeach.json
```
