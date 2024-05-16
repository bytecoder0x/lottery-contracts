// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title Random Getter Interface
 * @notice Interface for the RandomGetter contract that responsible for retrieving random numbers vue chainlink VRF for lotteries.
 */
interface IRandomGetter is IERC165, IKarrotErrors {
    /**
     * @notice Emitted when a request for a random number is sent.
     * @param requestId The ID of request that is done.
     * @param numWord The number of random words requested.
     */
    event RequestSent(uint256 requestId, uint32 numWord);
    /**
     * @notice Emitted when a request for a random number is fulfilled.
     * @param requestId The ID of request that is done.
     * @param randomWord The generated random number.
     */
    event RequestFulfilled(uint256 requestId, uint256 randomWord);

    /**
     * @notice Requests a random number after that calls the VRF that returns the requestId.
     * With this requestId we can get a random number.
     * @return requestId The ID of request that is done.
     */
    function requestRandomNumber() external returns (uint256);

    /**
     * @notice Retrieves the random number associated with the given request ID.
     * @param requestId The ID for which we received as a result of the request.
     * @return random The generated random number.
     */
    function getRandomNumber(uint256 requestId) external view returns (uint256);

    /**
     * @notice Retrieves the random number associated with the given lottery contract address.
     * @param lottery The address of the lottery contract that made the request.
     * @return random The generated random number.
     */
    function getRandomNumber(address lottery) external view returns (uint256);

    /**
     * @notice Allows the withdrawal of tokens from the contract.
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address token, uint256 amount) external;
}