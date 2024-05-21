// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ILottery} from "../interface/ILottery.sol";

/**
 * @title KarrotCheckMintTime
 * @notice Abstract contract that has a modifier to check if the current block timestamp is before the minting period ends.
 * @dev KarrotCheckMintTime contract must be inherited by others.
 */
abstract contract KarrotCheckMintTime {
    /// @notice Error message to be reverted when the minting period has ended.
    error MintTimeEnded();

    /**
     * @notice Modifier to ensure that the current block timestamp is before the minting period ends.
     * @dev Reverts with MintTimeEnded error if the minting period has ended.
     */
    modifier notBeforeMintClosed() {
        if (block.timestamp > ILottery(getLotteryContract()).mintDeadline()) {
            revert MintTimeEnded();
        }
        _;
    }

    /**
     * @notice This function to retrieve the address of the Lottery contract.
     * @dev This function must be implemented by contracts inheriting from KarrotCheckMintTime.
     * @return Address of the Lottery contract.
     */
    function getLotteryContract() public view virtual returns (address);
}