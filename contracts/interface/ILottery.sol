// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title Lottery contract
 * @notice Manages lottery functionality including ticket registration, initialization, running, and rewarding winners.
 * @notice The lottery has 3 tiers type - jackpot, random and fixed. 
 * @notice Winners are selected from registered tickets using a specific algorithm that relies on a random number generated
 * by the Chainlink VRF to ensure randomness, then receive a reward in their wallet.
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
    
    /**
    * @notice Mapping that contains registered addresses of tickets.
    * @param ticketAddress The address of the ticket contract.
    * @return True if the ticket address is registered, false otherwise.
    */
    function isRegisteredTicket(address ticketAddress) external view returns (bool);

    /**
     * @notice Registers a ticket contract for the lottery.
     * @param ticketContract The address of the ticket contract to register.
     * @dev Only can be called by accounts with the REGISTRAR_ROLE.
     * @dev Reverts if the ticket contract does not support the IKarrotTicket interface.
     * @dev Add the organization of the ticket to all organizations
     */
    function registerTicketContract(address ticketContract) external;

    /**
     * @notice Sets up the lottery with specified parameters is like reward token, tiers and shares of organizations for fixed tiers.
     * @notice The specified reward token will be sent to the winners of the lottery.
     * @notice Based on shares of organizations will choose the winners for the fixed tier. The large shares from the organization, the more winners it will have.
     * @notice The tiers contain detailed information about each tier, such as type, amount of winners, reward amount.
     * @param _rewardToken The address of the token used as rewards.
     * @param _tiers An array containing the configuration of lottery tiers.
     * @param _organizationSharesForFixedTiers An array containing the percentage shares of organizations for fixed tiers.
     * @dev Each element in `_tiers` is defined by its type(jackpot, random and fixed), the amount of winners and the reward amount.
     * @dev Each element in the `_organizationSharesForFixedTiers` is the percentage share of an organization for fixed tiers.
     * @dev Total share is 100_00 corresponds to 100% and 100 corresponds to 1% (BIPS).
     * @dev This function must be called before the deadline lottery time.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @dev Reverts if the reward token is not a contract.
     * @dev Reverts if the amount of organization shares for fixed tiers does not match the amount of organizations.
     * @dev Reverts if there are any incorrect tier configurations or if the total organization shares do not sum up to 100%.
     */
    function setupLottery(
        address _rewardToken,
        Tier[] calldata _tiers,
        uint256[] calldata _organizationSharesForFixedTiers
    ) external;

    /**
     * @notice Initializes the lottery by assigning ticket ranges to each organization's tickets.
     * @notice Initializes a specified number of organizations to avoid exceeding gas limits when dealing with many organizations.
     * @param organizationsCount The amount of organizations to initialize in the lottery.
     * @dev If the gas limit is exceeded when calling the function, the organization must be initialized in parts.
     * @dev This function can be called when the burn deadline passed, since after that amount of tokens cannot be changed.
     * @dev This function can be called if lottery hasn't been fully initialized.
     * @dev Calculates the amount of winners for each random tier based on the total supply of lottery tickets.
     * @dev If `organizationsCount` is 0 or exceeds the remaining amount of organizations to initialize,
     * it automatically sets `organizationsCount` to the remaining amount of organizations.
     */
    function initializeLottery(uint256 organizationsCount) external;

    /**
     * @notice Run the lottery process. We'll receive a random number based on that all winners can be selected. 
     * @dev This function can be called when the lottery time reached.
     * @dev This function doesn't select winners and rewards aren't distributed here.
     * @dev Reverts if the function was called before and the `requestRandomNumberId` was received.
     * @dev Reverts if the lottery is not fully initialized with all organizations.
     * @dev Initiates a request for a random number using the `requestRandomNumber`.
     */
    function runLottery() external;

    /**
     * @notice Rewards the winners of the lottery tiers.
     * @notice Rewards a specified amoumt of tiers to avoid exceeding gas limits when dealing with many tiers.
     * @notice This function calculates the rewards for winners in the specified tier, selects winners randomly based on
     * a random number within the given range of lottery tickets then the reward amount is transferred to the winners.
     * @param tiersCount The number of tiers to process.
     * @dev If the gas limit is exceeded when calling the function, the tiers should be rewarded in parts.
     * @dev Winners are chosen based on a random number.
     * @dev Reverts if a random number is still pending or if the lottery is not yet run.
     * @dev Reverts if the lottery has already been processed.
     * @dev If the tier is of type `Random`, it distributes rewards among the winners based on the random number.
     * @dev If the tier is of type `Fixed`, it distributes rewards among the winners based on their organization's shares.
     * @dev If `tiersCount` is 0 or exceeds the remaining amount of tiers to initialize,
     * it automatically sets `tiersCount` to the remaining amount of tiers.
    */
    function rewardWinners(uint256 tiersCount) external;

    /**
     * @notice Retrieves the underlying ticket information for a given lottery ticket ID.
     * @param lotteryTicketId The ID of the lottery ticket.
     * @return The address of the ticket contract and the corresponding ticket ID within that contract.
     * @dev Uses a binary search algorithm to efficiently locate the corresponding campaign ticket contract.
     */
    function getUnderlyingTicket(uint256 lotteryTicketId) external view returns (address, uint256);
    /**
     * @notice Retrieves information about a specific tier in the lottery.
     * @param tierIndex The index of the tier to retrieve.
     * @return Tier information including tier type, winners count, reward amount, etc.
     */
    function getTier(uint256 tierIndex) external view returns (Tier memory);
    /**
     * @notice Retrieves information about all tiers in the lottery.
     * @return An array containing information about all tiers including tier type, winners count, reward amount, etc.
     */
    function getAllTiers() external view returns (Tier[] memory);
    /**
     * @notice Retrieves the addresses of all organizations participating in the lottery.
     * @return An array containing the addresses of all participating organizations.
     */
    function getAllOrganizations() external view returns (address[] memory);
    /**
     * @notice Retrieves the amount of tiers in the lottery.
     * @return The amount of tiers in the lottery.
     */
    function getTiersCount() external view returns (uint256);
    /**
     * @notice Retrieves the amount of organizations participating in the lottery.
     * @return The amount of participating organizations.
     */
    function getOrganizationsCount() external view returns (uint256);
    /**
     * @notice Retrieves the addresses of all ticket contracts associated with a specific organization.
     * @param organization The address of the organization.
     * @return An array containing the addresses of ticket contracts associated with the organization.
     */
    function getOrganizationTicketsContracts(address organization) external view returns (address[] memory);
    /**
     * @notice Retrieves the shares assigned to each organization for fixed tiers.
     * @return An array containing the shares assigned to each organization for fixed tiers.
     */
    function getOrganizationSharesForFixedTiers() external view returns (uint256[] memory);
    /**
     * @notice Retrieves all campaign tickets stored in the lottery.
     * @return An array containing all campaign tickets stored in the lottery.
     */
    function getAllCampaignTickets() external view returns (CampaignTickets[] memory);
}
