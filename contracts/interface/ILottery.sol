// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface ILottery is IERC165, IKarrotErrors {
    struct CampaignTickets {
        address campaignTicketContract;
        TicketRange ticketRange;
    }

    struct TicketRange {
        uint256 firstLotteryTicketId;
        uint256 lastLotteryTicketId;
    }

    struct Tier {
        TierType tierType;
        uint256 winnersShare;
        uint256 winnersCount;
        uint256 rewardAmount;
    }

    enum TierType {
        Jackpot,
        Random,
        Fixed
    }
    
    function registerTicketContract(address ticketContract) external;
    
    function mintDeadline() external view returns (uint32);
    function burnDeadline() external view returns (uint32);
    function lotteryTime() external view returns (uint32);
}
