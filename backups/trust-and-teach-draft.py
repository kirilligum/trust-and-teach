# Copyright 2022 Cartesi Pte. Ltd.
#
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

from os import environ
import logging
import subprocess
import requests
import json
from eth_abi import decode_abi, encode_abi
from Crypto.Hash import keccak

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]
logger.info(f"HTTP rollup_server url is {rollup_server}")

k = keccak.new(digest_bits=256)
announcePromptResponse = k.update(b'announcePromptResponse(uint256,string[])').digest()[:4] # first 4 bytes

PROMPT_CMD_head = "./run stories15M.bin -t 0.8 -n 100 -i '"
PROMPT_CMD_tail = "'; exit 0"

def hex2str(hex):
    """
    Decodes a hex string into a regular string
    """
    return bytes.fromhex(hex[2:]).decode("utf-8")

def str2hex(str):
    """
    Encodes a string as a hex string
    """
    return "0x" + str.encode("utf-8").hex()

def post(endpoint, json):
    response = requests.post(f"{rollup_server}/{endpoint}", json=json)
    logger.info(f"Received {endpoint} status {response.status_code} body {response.content}")


def toss_coin(seed):
    random.seed(seed)
    return random.randint(0,1)

def submitPrompt(input):
    PROMPT_CMD = PROMPT_CMD_head + input + PROMPT_CMD_tail
    promptResponse1 = subprocess.check_output(PROMPT_CMD, shell=True, stderr=subprocess.STDOUT).decode()
    promptResponse2 = subprocess.check_output(PROMPT_CMD, shell=True, stderr=subprocess.STDOUT).decode()
    return [promptResponse1,promptResponse2];


def handle_advance(data):
    logger.info(f"Received advance request data {data}")

    status = "accept"
    try:
        promptAuthor_addr = data["metadata"]["msg_sender"]

        binary = bytes.fromhex(data["payload"][2:])

        # decode payload
        conversationId, promptInput = decode_abi(['uint256', 'string'], binary)
        logger.info(f"Received promptInput: {promptInput}, from conversationId: {conversationId}")

        promptLLMResponse = submitPrompt(promptInput)

        notice = {
            "conversationId": conversationId,
            "promptAuthor": promptAuthor_addr,
            "promptInput": promptInput,
            "promptLLMResponse": promptLLMResponse
        }

        post("notice", {"payload": str2hex(json.dumps(notice))})

        voucher_payload = announcePromptResponse + encode_abi(["uint256", "string[]"], [conversationId, promptLLMResponse])
        voucher = {"destination": promptAuthor_addr, "payload": "0x" + voucher_payload.hex()}
        post("voucher", voucher)

    except Exception as e:
        status = "reject"
        post("report", {"payload": str2hex(str(e))})

    return status

def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    logger.info("Adding report")

    inspect_response = "Trust and Teach LLM DApp, send an instruction prompt, get the responses, and rank the responses."
    inspect_response_hex = str2hex(inspect_response)
    post("report", {"payload": inspect_response_hex})

    status = "accept"
    return status

handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}
rollup_address = None

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
