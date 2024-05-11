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

    mapping(uint256 => uint256) public randomNumbersById;
    mapping(address => uint256) public randomNumbersByAddress;

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
        if (randomNumbersByAddress[msg.sender] != 0) {
            revert IncorrectCondition("Lottery already has random number");
        }

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        randomNumbersById[requestId] = 0;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function getRandomNumber(uint256 requestId) external onlyLottery returns (uint256) {
        if (randomNumbersById[requestId] != 0) {
            randomNumbersByAddress[msg.sender] = randomNumbersById[requestId] ;
            return randomNumbersById[requestId] ;
        }
        return 0;
    }

    function withdrawLink(uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_amount > LINK.balanceOf(address(this))) {
            revert IncorrectCondition("Not enough funds");
        }
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
        randomNumbersById[_requestId] = randomWords[0] == 0 ? 1 : randomWords[0];

        emit RequestFulfilled(_requestId, randomWords[0]);
    }
}
