// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IKarrotFactory} from "./interface/IKarrotFactory.sol";

contract Randomizer is VRFV2WrapperConsumerBase, AccessControl {
    uint32 constant callbackGasLimit = 100000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3; // cannot be lower

    address factoryAddress;
    address linkAddress;

    struct RequestStatus {
        uint256 paid;
        uint256 randomWord;
        bool fulfilled;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    event RequestSent(uint256 requestId, uint32 numWord);
    event RequestFulfilled(uint256 requestId, uint256 randomWord);

    modifier onlyLottery() {
        if (!IKarrotFactory(factoryAddress).isLottery(msg.sender)) {
            revert IncorrectCondition("Only lottery can call this function");
        }
        _;
    }

    constructor(
        address _link,
        address _vrfWrapper,
        address _factory,
        address _defaultAdmin
    ) VRFV2WrapperConsumerBase(_link, _vrfWrapper) {
        linkAddress = _link;
        factoryAddress = _factory;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }
}
