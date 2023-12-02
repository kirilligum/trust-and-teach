# syntax=docker.io/docker/dockerfile:1.4

# build stage: includes resources necessary for installing dependencies
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy as build-stage

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  build-essential=12.9ubuntu3 \
  && rm -rf /var/apt/lists/*


COPY ./tokenizer.bin .
COPY ./stories15M.bin .
COPY ./run.c .

RUN gcc -Ofast run.c  -lm  -o run

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY ./requirements.txt .
RUN pip install -r requirements.txt --no-cache \
  && find /usr/local/lib -type d -name __pycache__ -exec rm -r {} +
# RUN pip install -r requirements.txt


# runtime stage: produces final image that will be executed
FROM --platform=linux/riscv64 cartesi/python:3.10-slim-jammy

COPY --from=build-stage /opt/venv /opt/venv

WORKDIR /opt/cartesi/dapp
COPY ./entrypoint.sh .
COPY ./trust-and-teach.py .
