// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {IRandomizer} from "./interface/IRandomizer.sol";

contract Randomizer is VRFV2WrapperConsumerBase, AccessControl, IRandomizer {
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
        if (
            !IKarrotFactory(_factory).supportsInterface(
                type(IKarrotFactory).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        
        linkAddress = _link;
        factoryAddress = _factory;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    }

    function requestRandomNumber() external onlyLottery returns (uint256) {
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

        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function getRandomNumber(uint256 requestId) public view onlyLottery returns (uint256) {
        if (s_requests[requestId].fulfilled) {
            return s_requests[requestId].randomWord;
        }
        return 0;
    }

    function withdrawLink() public onlyRole(DEFAULT_ADMIN_ROLE) {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);

        if (!link.transfer(msg.sender, link.balanceOf(address(this)))){
            revert IncorrectCondition("Unable to transfer");
        }
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
            type(IRandomizer).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory randomWords
    ) internal override {
        if (s_requests[_requestId].paid == 0) revert IncorrectValue("Request not found");

        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWord = randomWords[0];

        emit RequestFulfilled(_requestId, randomWords[0]);
    }
}
