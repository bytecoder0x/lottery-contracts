// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ILottery} from "../interface/ILottery.sol";

abstract contract KarrotCheckMintTime {
    error MintTimeEnded();

    modifier notBeforeMintClosed() {
        if (block.timestamp > ILottery(getLotteryContract()).mintDeadline()) {
            revert MintTimeEnded();
        }
        _;
    }

    function getLotteryContract() public view virtual returns (address);
}