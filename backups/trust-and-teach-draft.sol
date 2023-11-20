// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@cartesi/rollups/contracts/inputs/IInputBox.sol";

contract TrustAndTeach {
    address deployer;
    address public L2_DAPP;
    string public license = "MIT";
    string public llm = "stories15m";
    IInputBox inputBox = IInputBox(0x59b22D57D4f067708AB0c00552767405926dc768);

    struct Conversation {
        address author;
        string prompt;
        string[] responses;
        uint256[] ranks; // most relevent is 0
        uint256 createInstructionTimestamp;
        uint256 responseAnnouncedTimestamp;
        uint256 rankingTimestamp;
    }

    uint256 public current_conversation_id = 0; // initial value is 0
    mapping(uint256 => Conversation) conversations;

    constructor() {
        deployer = msg.sender;
    }

    function set_dapp_address(address l2_dapp) public {
        require(msg.sender == deployer);
        L2_DAPP = l2_dapp;
    }

    function sendInstructionPrompt(string memory prompt) public {
        // require(L2_DAPP != address(0));

        Conversation storage conversation = conversations[
            current_conversation_id
        ];
        conversation.author = msg.sender;
        conversation.prompt = prompt;
        conversation.createInstructionTimestamp = block.timestamp;
        cartesiSubmitPrompt(current_conversation_id, prompt);
        emit PromptSent(current_conversation_id, prompt);
        current_conversation_id++;
    }

    function cartesiSubmitPrompt(uint256 conversation_id, string memory prompt)
        public
    {
        bytes memory payload = abi.encode(conversation_id, prompt);
        inputBox.addInput(L2_DAPP, payload); // this line gives an error :-(
    }

    function announcePromptResponse(
        uint256 conversation_id,
        string[] memory responses
    ) public {
        // require(msg.sender == L2_DAPP);
        require(conversation_id <= current_conversation_id);
        // adds each response to a conversation as a list of responses
        Conversation storage conversation = conversations[conversation_id];
        conversation.responses = responses; // this is a list of responses to the prompt
        conversation.responseAnnouncedTimestamp = block.timestamp;
        emit PromptResponseAnnounced(conversation_id, responses);
    }

    //a function to assign a rank to prompt responses
    function rankPromptResponses(
        uint256 conversation_id,
        uint256[] memory ranks
    ) public {
        // require(msg.sender == L2_DAPP);
        require(conversation_id <= current_conversation_id);
        Conversation storage conversation = conversations[conversation_id];
        conversation.ranks = ranks;
        conversation.rankingTimestamp = block.timestamp;
        emit PromptResponsesRanked(conversation_id, ranks);
    }

    function getL2Dapp()
        public
        view
        returns (address)
    {
        return L2_DAPP;
    }

    function getConversation(uint256 conversation_id)
        public
        view
        returns (Conversation memory)
    {
        return conversations[conversation_id];
    }

    function getPrompt(uint256 conversation_id)
        public
        view
        returns (string memory)
    {
        return conversations[conversation_id].prompt;
    }

    function getResponses(uint256 conversation_id)
        public
        view
        returns (string[] memory)
    {
        return conversations[conversation_id].responses;
    }

    function getRanks(uint256 conversation_id)
        public
        view
        returns (uint256[] memory)
    {
        return conversations[conversation_id].ranks;
    }

    event PromptSent(uint256 conversation_id, string prompt);
    event PromptResponseAnnounced(uint256 conversation_id, string[] responses);
    event PromptResponsesRanked(uint256 conversation_id, uint256[] ranks);
}
