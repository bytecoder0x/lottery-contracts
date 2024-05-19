// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotErrors} from "./IKarrotErrors.sol";

/**
 * @title KarrotFactory Interface
 * @notice Interface for the KarrotFactory contract that serving as a factory for various contracts such as organizations, campaigns, lotteries, redemption, and tickets.
 * @dev KarrotFactory manages the deployment process and keeps track of deployed contracts.
 */
interface IKarrotFactory is IERC165, IKarrotErrors {

    /**
     * @notice Emitted when the minter contract address is updated.
     * @param minterContract The new address of the minter contract.
     */
    event MinterContractUpdated(address indexed minterContract);
    /**
     * @notice Emitted when the randomGetter contract address is updated.
     * @param randomGetterContract The new address of the randomGetter contract.
     */
    event RandomGetterContractUpdated(address indexed randomGetterContract);
    /**
     * @notice Emitted when a lottery contract is deployed.
     * @param lotteryContract The address of the deployed lottery contract.
     */
    event LotteryContractDeployed(address indexed lotteryContract);
    /**
     * @notice Emitted when a redemption contract is deployed.
     * @param redemptionContract The address of the deployed redemption contract.
     */
    event RedemptionContractDeployed(address indexed redemptionContract);
    /**
     * @notice Emitted when an organization contract is deployed.
     * @param organizationContract The address of the deployed organization contract.
     */
    event OrganizationContractDeployed(address indexed organizationContract);
    /**
     * @notice Emitted when a campaign contract is deployed.
     * @param campaignContract The address of the deployed campaign contract.
     * @param organization The address of the organization associated with the campaign.
     */
    event CampaignContractDeployed(address indexed campaignContract, address indexed organization);
    /**
     * @notice Emitted when a ticket contract is deployed.
     * @param ticketContract The address of the deployed ticket contract.
     * @param campaign The address of the campaign associated with the ticket.
     */
    event TicketContractDeployed(address indexed ticketContract, address indexed campaign);
    /**
     * @notice Emitted when an organization is enabled.
     * @param organization The address of the enabled organization.
     */
    event EnableOrganization(address indexed organization);
    /**
     * @notice Emitted when an organization is disabled.
     * @param organization The address of the disabled organization.
     */
    event DisabledOrganization(address indexed organization);
    
    /**
     * @notice Checks if an address is an organization.
     * @param organization The address to check.
     * @return A boolean indicating whether the address is an organization.
     */
    function isOrganization(address organization) external view returns (bool);
    /**
     * @notice Checks if an address is a lottery contract.
     * @param lottery The address to check.
     * @return A boolean indicating whether the address is a lottery contract.
     */
    function isLottery(address lottery) external view returns (bool);
    /**
     * @notice Retrieves the organization associated with a campaign contract.
     * @param campaign The address of the campaign contract.
     * @return organization The address of the organization associated with the campaign.
     */
    function campaignOrganization(address campaign) external view returns (address organization);
    /**
     * @notice Retrieves the campaign associated with a ticket contract.
     * @param ticketContract The address of the ticket contract.
     * @return campaign The address of the campaign associated with the ticket contract.
     */
    function ticketsCampaign(address ticketContract) external view returns (address campaign);

    /**
     * @notice Retrieves the addresses of all deployed lottery contracts.
     * @return An array containing the addresses of all deployed lottery contracts.
     */
    function getAllLotteries() external view returns (address[] memory);
    /**
     * @notice Retrieves the addresses of all deployed redemption contracts.
     * @return An array containing the addresses of all deployed redemption contracts.
     */
    function getAllRedemptions() external view returns (address[] memory);
    /**
     * @notice Retrieves the addresses of all deployed organization contracts.
     * @return An array containing the addresses of all deployed organization contracts.
     */
    function getAllOrganizations() external view returns (address[] memory);
    /**
     * @notice Retrieves the addresses of all deployed campaign contracts.
     * @return An array containing the addresses of all deployed campaign contracts.
     */
    function getAllCampaigns() external view returns (address[] memory);
    /**
     * @notice Retrieves the addresses of all deployed ticket contracts.
     * @return An array containing the addresses of all deployed ticket contracts.
     */
    function getAllTickets() external view returns (address[] memory);

    /**
     * @notice Enables an organization.
     * @param organization The address of the organization to enable.
     */
    function enableOrganization(address organization) external;
    /**
     * @notice Disables an organization.
     * @param organization The address of the organization to disable.
     */
    function disableOrganization(address organization) external;
    /**
     * @notice Sets the minter contract address that can mint organization, campaigns and tickets.
     * @param _minterContract The address of the minter contract to set.
     */
    function setMinterContract(address _minterContract) external;
    /**
     * @notice Sets the randomGetter contract address providing random numbers.
     * @param _randomGettercontract The address of the randomGetter contract to set.
     */
    function setRandomGetterContract(address _randomGettercontract) external;

    /**
     * @notice Deploys a new lottery and redemption contract.
     * @param defaultAdmin The address of the admin for the contracts.
     * @param mintDeadline The deadline for ticket minting.
     * @param burnDeadline The deadline for ticket burning.
     * @param lotteryTime The time when the lottery will be conducted.
     * @return deployedLottery The address of the newly deployed lottery contract.
     * @return deployedRedemption The address of the newly deployed redemption contract.
     * @dev Reverts if _mintDeadline is greater than _burnDeadline,
     *  _burnDeadline is greater than _lotteryTime,
     *  _mintDeadline is greater than _lotteryTime.
     */
    function deployLotteryAndRedemptionContract(
        address defaultAdmin,
        uint32 mintDeadline,
        uint32 burnDeadline,
        uint32 lotteryTime
    ) external returns (address deployedLottery, address deployedRedemption);

    /**
     * @notice Deploys a new organization contract.
     * @param defaultAdmin The address of the admin for the contract.
     * @param organizationName The name of the organization.
     * @return deployedOrganization The address of the newly deployed organization contract.
     */
    function deployOrganizationContract(
        address defaultAdmin,
        string memory organizationName
    ) external returns (address deployedOrganization);

    /**
     * @notice Deploys a new campaign and ticket contract.
     * @param defaultAdmin The address of the admin for the contracts.
     * @param lottery The address of the lottery contract.
     * @param organization The address of the parent organization contract.
     * @param campaignName The name of the campaign.
     * @return deplyedCampaign The address of the newly deployed campaign contract.
     * @return deployedTicket The address of the newly deployed ticket contract.
     */
    function deployCampaignAndTicketContract(
        address defaultAdmin,
        address lottery,
        address organization,
        string memory campaignName
    ) external returns (address deplyedCampaign, address deployedTicket);

    /**
     * @notice Deploys an organization contract and multiple campaigns that are linked to the organization and corresponding ticket contracts.
     * @param defaultAdmin The address of the admin for the contracts.
     * @param lottery The address of the lottery contract.
     * @param organizationName The name of the organization.
     * @param campaignNames An array of campaign names to be deployed.
     * @return deployedOrganization The address of the newly deployed organization contract.
     * @return deployedCampaigns An array containing the addresses of the newly deployed campaign contracts.
     * @return deployedTickets An array containing the addresses of the newly deployed ticket contracts.
     */
    function deployOrganizationAndCampaigns(
        address defaultAdmin,
        address lottery,
        string memory organizationName,
        string[] memory campaignNames
    ) external returns (
        address deployedOrganization,
        address[] memory deployedCampaigns,
        address[] memory deployedTickets
    );
}
