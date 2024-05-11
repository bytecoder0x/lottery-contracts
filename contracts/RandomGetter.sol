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

    struct RequestStatus {
        uint256 paid;
        uint256 randomWord;
        bool fulfilled;
    }

    mapping(uint256 => RequestStatus) public s_requests;
    mapping(address => uint256) public randomNumbers;

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
        if (randomNumbers[msg.sender] != 0) {
            revert IncorrectCondition("Lottery already has random number");
        }

        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );

        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWord: 0,
            fulfilled: false
        });

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function getRandomNumber(uint256 requestId) external onlyLottery returns (uint256) {
        if (s_requests[requestId].fulfilled) {
            randomNumbers[msg.sender] = s_requests[requestId].randomWord;
            return s_requests[requestId].randomWord;
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
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWord = randomWords[0] == 0 ? 1 : randomWords[0];

        emit RequestFulfilled(_requestId, randomWords[0]);
    }
}
