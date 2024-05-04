// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import {Lottery} from "../Lottery.sol";

library LotteryDeployerLibrary {
    function deployLotteryContract(
        address defaultAdmin,
        address lowerAdmin,
        uint256 lotteriesCount,
        uint32 mintDeadline,
        uint32 burnDeadline,
        uint32 lotteryTime
    ) external returns (address) {
        return address(
            new Lottery{salt: keccak256(abi.encodePacked(lotteriesCount))}(
                defaultAdmin,
                lowerAdmin,
                mintDeadline,
                burnDeadline,
                lotteryTime
            )
        );
    }
}