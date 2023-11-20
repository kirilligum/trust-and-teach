#!/usr/bin/bash
docker compose -f docker-compose.yml -f docker-compose.override.yml down -v
docker images && docker ps -a --no-trunc &&  docker volume ls && docker network ls
docker image rm coin-toss-contracts

docker stop $(docker ps -aq)
docker rm $(docker ps -aq) -f
docker rmi $(docker images -q) -f
docker volume rm $(docker volume ls -q) -f
# docker network ls | grep "bridge\|none\|host" | awk '/ / { print $1 }' | xargs -r docker network rm -f
docker system prune -a --volumes -f
