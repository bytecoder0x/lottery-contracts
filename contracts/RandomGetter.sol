// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {VRFV2WrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {IRandomGetter} from "./interface/IRandomGetter.sol";

/**
 * @title RandomGetter contract
 * @notice RandomGetter gets random numbers for lotteries using chainlink VRF.
 * @notice RandomGetter contract must be has enough link token, since we pay a link token for getting a random number.
 * @dev We use one RandomGetter contract for all lotteries, avoiding the
 * need to send the link token to the balance of each contract separately.
 */
contract RandomGetter is VRFV2WrapperConsumerBase, AccessControl, IRandomGetter {
    using SafeERC20 for IERC20;

    /// @notice Gas limit for callback fulfillRandomWords function execution.
    uint32 constant callbackGasLimit = 100_000;
    /// @notice Amount of random numbers that will be received.
    uint32 constant numWords = 1;
    /// @notice Minimum amount of confirmations during the request.
    uint16 constant requestConfirmations = 3; // cannot be lower

    /// @notice Address of the KarrotFactory contract.
    IKarrotFactory factory;

    /// @notice Mapping from lottery address to its associated request ID.
    mapping(address => uint) public requestIds;
    /// @notice Mapping from request ID to its associated random number.
    mapping(uint256 => uint256) public randomNumbersByRequestId;

    /**
     * @notice The modifier checks whether the function is called from the lottery contract.
     */
    modifier onlyLottery() {
        if (!factory.isLottery(msg.sender)) {
            revert IncorrectCondition("Only lottery can call this function");
        }
        _;
    }

    /**
     * @notice Constructor function to initialize the RandomGetter contract.
     * @param _link The address of the LINK token contract.
     * @param _vrfWrapper The address of the VRF wrapper contract.
     * @param _factory The address of the KarrotFactory contract.
     * @param _defaultAdmin The address of the admin this contract.
     * @dev Reverts if the factory contract does not support their respective interfaces.
     */
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

    /**
     * @notice Requests a random number for the calling lottery contract
     * after that calls the VRF that returns the requestId. With this requestId we can get a random number.
     * @dev Only can be called callable by the lottery contract itself.
     * @return requestId The unique identifier for the random number request.
     * @dev Reverts if the lottery contract already has random number request is pending.
     */
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

    /**
     * @notice Retrieves the random number associated with the given request ID.
     * @param requestId The unique identifier for the random number request.
     * @return random The generated random number.
     */
    function getRandomNumber(uint256 requestId) external view returns (uint256 random) {
        random = randomNumbersByRequestId[requestId];
    }

    /**
     * @notice Retrieves the random number associated with the given lottery contract address.
     * @param lottery The address of the lottery contract.
     * @return random The generated random number.
     */
    function getRandomNumber(address lottery) external view returns (uint256 random) {
        uint256 requestId = requestIds[lottery];
        random = randomNumbersByRequestId[requestId];
    }

    /**
     * @notice Allows the admin of this contract to withdraw tokens from the contract.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(address _token, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
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

    /**
     * @notice Fulfills the requested random words.
     * @param _requestId The ID of the request.
     * @param randomWords The array of random words to fulfill.
     * @dev Overrides the internal function in the VRFConsumerBase contract.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory randomWords
    ) internal override {
        randomNumbersByRequestId[_requestId] = randomWords[0] == 0 ? 1 : randomWords[0];

        emit RequestFulfilled(_requestId, randomWords[0]);
    }
}
