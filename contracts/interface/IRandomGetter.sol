// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface IRandomGetter is IERC165, IKarrotErrors {
    event RequestSent(uint256 requestId, uint32 numWord);
    event RequestFulfilled(uint256 requestId, uint256 randomWord);

    function requestRandomNumber() external returns (uint256);

    function getRandomNumber(uint256 requestId) external returns (uint256);

    function withdrawLink(uint256 amount) external;
}