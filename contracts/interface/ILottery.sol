// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

interface ILottery is IERC165, IKarrotErrors {
    
    event RegisterTicketContract(address indexed organization, address indexed ticketContract);
    event LotteryInitialized(uint indexed organizationsCount);
    event LotterySetup(address indexed rewardToken, Tier[] tiers, uint[] organizationSharesForFixedTiers);
    event TicketRedeemed(address indexed redeemer, address ticketContract, uint ticketsCount, uint redemptionAmount);
    event TierProcessed(uint indexed tierIndex, address indexed organization, uint256 totalRewardAmount);
    event WinnerDefined(address indexed winner, uint256 indexed lotteryTicketId, address campaignTicketContract, uint256 indexed campaignTicketId, uint256 tierType, uint256 rewardAmount);
    event LotteryFinished();
    event SetRedemptionPrice(uint redemptionPrice);
    event SetRedemptionCap(uint redemptionCap);

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
    function getOrganizationTicketsContracts(address organization) external view returns (address[] memory);
    
    function mintDeadline() external view returns (uint32);
    function burnDeadline() external view returns (uint32);
    function lotteryTime() external view returns (uint32);
}
