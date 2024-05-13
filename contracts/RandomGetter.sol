// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {IRandomGetter} from "./interface/IRandomGetter.sol";

contract RandomGetter is VRFV2WrapperConsumerBase, AccessControl, IRandomGetter {
    uint32 constant callbackGasLimit = 100000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3; // cannot be lower

    IKarrotFactory factory;

    mapping(address => uint) public requestIds;
    mapping(uint256 => uint256) public randomNumbersByRequestId;

    modifier onlyLottery() {
        if (!factory.isLottery(msg.sender)) {
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
        if (
            !IKarrotFactory(_factory).supportsInterface(
                type(IKarrotFactory).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }

        factory = IKarrotFactory(_factory);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    function requestRandomNumber() external onlyLottery returns (uint256) {
        if (requestIds[msg.sender] != 0) {
            revert IncorrectCondition("Lottery already has random number or request id pending");
        }

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        requestIds[msg.sender] = requestId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function getRandomNumber(uint256 requestId) external view onlyLottery returns (uint256 random) {
        if (randomNumbersByRequestId[requestId] != 0) {
            random = randomNumbersByRequestId[requestId];
        }
    }

    function withdrawLink(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LINK.transfer(msg.sender, _amount);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControl, IERC165)
        returns (bool)
    {
        return 
            type(IRandomGetter).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory randomWords
    ) internal override {
        randomNumbersByRequestId[_requestId] = randomWords[0] == 0 ? 1 : randomWords[0];

        emit RequestFulfilled(_requestId, randomWords[0]);
    }
}
