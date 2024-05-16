// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title Lottery contract
 * @notice Manages lottery functionality including ticket registration, initialization, running, and rewarding winners.
 */
interface ILottery is IERC165, IKarrotErrors {
    
    /**
     * @notice Emitted when a ticket contract is registered for a specific organization.
     * @param organization The address of the organization registering the ticket contract.
     * @param ticketContract The address of the registered ticket contract.
     */
    event RegisterTicketContract(address indexed organization, address indexed ticketContract);
    /**
     * @notice Emitted when the lottery is initialized with a certain amount of organizations.
     * @param organizationsCount The amount of organizations initialized for the lottery.
     */
    event LotteryInitialized(uint indexed organizationsCount);
    /**
     * @notice Emitted when the lottery setup is completed with reward token, tiers, and organization shares for fixed tiers.
     * @param rewardToken The address of the token used as rewards.
     * @param tiers An array containing the configuration of lottery tiers.
     * @param organizationSharesForFixedTiers An array containing the percentage shares of organizations for fixed tiers.
     */
    event LotterySetup(address indexed rewardToken, Tier[] tiers, uint[] organizationSharesForFixedTiers);
    /**
     * @notice Emitted when a tier in the lottery is processed, indicating the total reward amount for the tier.
     * @param tierIndex The index of the processed tier.
     * @param organization The address of the organization associated with the tier if it is(used for fixed tier).
     * @param totalRewardAmount The total reward amount distributed for the tier.
     */
    event TierProcessed(uint indexed tierIndex, address indexed organization, uint256 totalRewardAmount);
    /**
     * @notice Emitted when a winner is defined for a specific lottery ticket in a tier.
     * @param winner The address of the winner.
     * @param lotteryTicketId The ID of the lottery ticket that won.
     * @param campaignTicketContract The address of the ticket contract associated with the ticket ID that won.
     * @param campaignTicketId The ID of the parent campaign associated with the ticket that won.
     * @param tierType The type of tier in which the winner is defined.
     * @param rewardAmount The amount of reward received by the winner.
     */
    event WinnerDefined(address indexed winner, uint256 indexed lotteryTicketId, address campaignTicketContract, uint256 indexed campaignTicketId, uint256 tierType, uint256 rewardAmount);
    /**
     * @notice Emitted when the lottery is finished, indicating that all tiers have been processed.
     */
    event LotteryFinished();

    
    /**
     * @notice Struct representing campaign tickets, containing the ticket contract address and ticket range(first and last ticket IDs).
     */
    struct CampaignTickets {
        address campaignTicketContract; // address of the ticket contract
        TicketRange ticketRange; // TicketRange struct that contains first and last tikcet IDs
    }

    /**
     * @notice Struct representing the range of lottery tickets for a specific organization - first and last tikcet IDs. 
     */
    struct TicketRange {
        uint256 firstLotteryTicketId; // first ticket ID that associated with its organization
        uint256 lastLotteryTicketId; // last ticket ID that associated with its organization
    }

    /**
     * @notice Struct representing a tier in the lottery, containing the tier type, winners share, winners count, and reward amount.
     */
    struct Tier {
        TierType tierType; // tier type can be Jackpot, Random, Fixed
        uint256 winnersShare; // in percents for random tier
        uint256 winnersCount; // amount of winner
        uint256 rewardAmount; // amount of reward for each user
    }

    /**
     * @notice Enum representing the types of tiers in the lottery: Jackpot, Random, and Fixed.
     */
    enum TierType {
        Jackpot,
        Random,
        Fixed
    }
    
    /**
     * @notice Registers a ticket contract for the lottery.
     * @param ticketContract The address of the ticket contract to register.
     */
    function registerTicketContract(address ticketContract) external;
    /**
     * @notice Checks if a ticket contract is registered.
     * @param ticketContract The address of the ticket contract to check.
     * @return A boolean indicating whether the ticket contract is registered.
     */
    function isRegisteredTicket(address ticketContract) external view returns (bool);
    
    /**
     * @notice Retrieves the deadline for minting tickets.
     * @return The timestamp indicating the deadline for minting tickets.
     */
    function mintDeadline() external view returns (uint32);
    /**
     * @notice Retrieves the deadline for burning tickets.
     * @return The timestamp indicating the deadline for burning tickets.
     */
    function burnDeadline() external view returns (uint32);
    /**
     * @notice Retrieves the timestamp indicating the time when the lottery will occur.
     * @return The timestamp indicating the time when the lottery will occur.
     */
    function lotteryTime() external view returns (uint32);
}
