// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {KarrotOrganization} from "./KarrotOrganization.sol";
import {KarrotCampaign} from "./KarrotCampaign.sol";
import {Lottery} from "./Lottery.sol";
import {TicketRedemption} from "./TicketRedemption.sol";
import {KarrotTicket} from "./KarrotTicket.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {ILottery} from "./interface/ILottery.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {ITicketMinter} from "./interface/ITicketMinter.sol";

import {LotteryDeployerLibrary} from "./libraries/LotteryDeployerLibrary.sol";
import {RedemptionDeployerLibrary} from "./libraries/RedemptionDeployerLibrary.sol";
import {OrganizationDeployerLibrary} from "./libraries/OrganizationDeployerLibrary.sol";
import {CampaignDeployerLibrary} from "./libraries/CampaignDeployerLibrary.sol";
import {TicketDeployerLibrary} from "./libraries/TicketDeployerLibrary.sol";

/**
 * @title KarrotFactory contract
 * @notice The KarrotFactory contract serves as a factory for various contracts 
 * such as organizations, campaigns, lotteries, redemption and tickets.
 * @dev KarrotFactory manages the deployment process and keeps track of deployed contracts.
*/
contract KarrotFactory is AccessControl, IKarrotFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Сonstant that contains the DEPLOYER role. Owner of this role can deploy contracts.
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER");
    /// @notice Address of the minterContract that can mint organization, campaigns and tickets. Expected to be the TicketMinter contract.
    address public minterContract;

    /// @notice Stores addresses of active organizations.
    EnumerableSet.AddressSet private activeOrganizations;

    /// @notice Stores addresses of deployed lottery contracts.
    address[] public lotteries;
    /// @notice Stores addresses of deployed redemption contracts.
    address[] public redemptions;
    /// @notice Stores addresses of deployed organization contracts.
    address[] public organizations;
    /// @notice Stores addresses of deployed campaign contracts.
    address[] public campaigns;
    /// @notice Stores addresses of deployed ticket contracts.
    address[] public tickets;

    /// @notice Mapping that contains added addresses of organizations.
    mapping(address => bool) public isOrganization;
    /// @notice Mapping that contains added addresses of lotteries.
    mapping(address => bool) public isLottery;
    /// @notice Mapping from campaign address to its associated organization address.
    mapping(address => address) public campaignOrganization;
    /// @notice Mapping from ticket address to its associated campaign address.
    mapping(address => address) public ticketsCampaign;

    /**
     * @notice The modifier checks whether the function is without set minter contract.
     */
    modifier withSetupMinterContract() {
        if (minterContract == address(0)) revert IncorrectCondition("Minter contract not set");
        _;
    }

    /**
     * @notice Constructor function to initialize the KarrotFactory contract.
     * @param _deployer The address of the deployer role.
     */
    constructor(address _deployer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEPLOYER_ROLE, _deployer);
    }

    /**
     * @notice Disables an organization if they leave the project.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @param _organization The address of the organization to be disabled.
     * @dev If the organization is Non Karrot or already disabled, reverts with an error message.
     */
    function disableOrganization(
        address _organization
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!activeOrganizations.contains(_organization)) revert IncorrectValue("Non Karrot organization or organization is already disabled");
        activeOrganizations.remove(_organization);

        emit DisabledOrganization(_organization);
    }

    /**
     * @notice Enables an organization if they are returned in the project.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @param _organization The address of the organization to be enabled.
     * @dev If the organization is already enabled, reverts with an error message.
     */
    function enableOrganization(
        address _organization
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (activeOrganizations.contains(_organization)) revert IncorrectValue("Organization is already enabled");
        activeOrganizations.add(_organization);

        emit EnableOrganization(_organization);
    }

    /**
     * @notice Sets the minter contract address for ticket minting.
     * @dev Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
     * @param _minterContract The address of the minter contract to be set.
     * @dev Reverts if the minter contract does not support the required interface.
     */
    function setMinterContract(
        address _minterContract
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            !ITicketMinter(_minterContract).supportsInterface(
                type(ITicketMinter).interfaceId
            )
        ) {
            revert InterfaceNotSupported();
        }
        minterContract = _minterContract;
        
        emit MinterContractUpdated(_minterContract);
    }

    /**
     * @notice Deploys a new lottery and redemption contract.
     * @dev Only can be called by accounts with the DEPLOYER_ROLE.
     * @param _defaultAdmin The address of the admin for the contracts.
     * @param _mintDeadline The deadline for ticket minting.
     * @param _burnDeadline The deadline for ticket burning.
     * @param _lotteryTime The time when the lottery will be conducted.
     * @return newLottery The address of the newly deployed lottery contract.
     * @return newRedemption The address of the newly deployed redemption contract.
     * @dev Reverts if _mintDeadline is greater than _burnDeadline,
     *  _burnDeadline is greater than _lotteryTime,
     *  _mintDeadline is greater than _lotteryTime.
     */
    function deployLotteryAndRedemptionContract(
        address _defaultAdmin,
        uint32 _mintDeadline,
        uint32 _burnDeadline,
        uint32 _lotteryTime
    ) public withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns (address newLottery, address newRedemption) {
    
            newLottery = _deployLotteryContract(
                _defaultAdmin,
                _mintDeadline,
                _burnDeadline,
                _lotteryTime
            );
            newRedemption = _deployRedemptionContract(_defaultAdmin, newLottery);

            emit LotteryContractDeployed(newLottery);
            emit RedemptionContractDeployed(newRedemption);
    }

    /**
     * @notice Deploys a new organization contract.
     * @dev Only can be called by accounts with the DEPLOYER_ROLE.
     * @param defaultAdmin The address of the admin for the contract.
     * @param organizationName The name of the organization.
     * @return newOrganization The address of the newly deployed organization contract.
     */
    function deployOrganizationContract(
        address defaultAdmin,
        string memory organizationName
    ) public withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns (address) {
        address newOrganization = _deployOrganizationContract(defaultAdmin, organizationName);
        emit OrganizationContractDeployed(newOrganization);
        return newOrganization;
    }

    /**
     * @notice Deploys a new campaign and ticket contract.
     * @dev Only can be called by accounts with the DEPLOYER_ROLE.
     * @param defaultAdmin The address of the admin for the contracts.
     * @param lottery The address of the lottery contract.
     * @param organization The address of the parent organization contract.
     * @param campaignName The name of the campaign.
     * @return newCampaign The address of the newly deployed campaign contract.
     * @return newTicket The address of the newly deployed ticket contract.
     */
    function deployCampaignAndTicketContract(
        address defaultAdmin,
        address lottery,
        address organization,
        string memory campaignName
    ) public withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns (address, address) {
        (address newCampaign, address newTicket) =_deployCampaignAndTicketContract(defaultAdmin, lottery, organization, campaignName);
        emit CampaignContractDeployed(newCampaign, organization);
        emit TicketContractDeployed(newTicket, newCampaign);
        return (newCampaign, newTicket);
    }

    /**
     * @notice Deploys an organization contract and multiple campaigns that are linked to the organization and corresponding ticket contracts.
     * @dev Only can be called by accounts with the DEPLOYER_ROLE.
     * @param _defaultAdmin The address of the admin for the contracts.
     * @param _lottery The address of the lottery contract.
     * @param _organizationName The name of the organization.
     * @param _campaignNames An array of campaign names to be deployed.
     * @return deployedOrganization The address of the newly deployed organization contract.
     * @return deployedCampaigns An array containing the addresses of the newly deployed campaign contracts.
     * @return deployedTickets An array containing the addresses of the newly deployed ticket contracts.
     */
    function deployOrganizationAndCampaigns(
        address _defaultAdmin,
        address _lottery,
        string memory _organizationName,
        string[] memory _campaignNames
    ) external withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns(
        address deployedOrganization,
        address[] memory deployedCampaigns,
        address[] memory deployedTickets
    ) {
        deployedOrganization = _deployOrganizationContract(
            _defaultAdmin,
            _organizationName
        );
        deployedCampaigns = new address[](_campaignNames.length);
        deployedTickets = new address[](_campaignNames.length);
        for (uint256 i = 0; i < _campaignNames.length; i++) {
            (address deployedCampaign, address deployedTicket) = _deployCampaignAndTicketContract(
                _defaultAdmin,
                _lottery,
                deployedOrganization,
                _campaignNames[i]
            );
            emit CampaignContractDeployed(deployedCampaign, deployedOrganization);
            emit TicketContractDeployed(deployedTicket, deployedCampaign);

            deployedCampaigns[i] = deployedCampaign;
            deployedTickets[i] = deployedTicket;
        }
        emit OrganizationContractDeployed(deployedOrganization);

    }

    /**
     * @notice Returns the addresses of all deployed lottery contracts.
     * @return An array containing the addresses of all lottery contracts.
     */
    function getAllLotteries() external view returns (address[] memory) {
        return lotteries;
    }

    /**
     * @notice Returns the addresses of all deployed redemption contracts.
     * @return An array containing the addresses of all redemption contracts.
     */
    function getAllRedemptions() external view returns (address[] memory) {
        return redemptions;
    }

    /**
     * @notice Returns the addresses of all deployed organization contracts.
     * @return An array containing the addresses of all organization contracts.
     */
    function getAllOrganizations() external view returns (address[] memory) {
        return organizations;
    }

    /**
     * @notice Returns the addresses of all deployed campaign contracts.
     * @return An array containing the addresses of all campaign contracts.
     */
    function getAllCampaigns() external view returns (address[] memory) {
        return campaigns;
    }

    /**
     * @notice Returns the addresses of all deployed ticket contracts.
     * @return An array containing the addresses of all ticket contracts.
     */
    function getAllTickets() external view returns (address[] memory) {
        return tickets;
    }

    /**
     * @notice Deploys a new organization contract.
     * @param defaultAdmin The address of the admin for the contract.
     * @param _organizationName The name of the organization.
     * @return newOrganization The address of the newly deployed organization contract.
     */
    function _deployOrganizationContract(
        address defaultAdmin,
        string memory _organizationName
    ) private returns (address) {
        address newOrganization = OrganizationDeployerLibrary.deployOrganizationContract(
            defaultAdmin,
            minterContract,
            organizations.length,
            _organizationName
        );
        activeOrganizations.add(newOrganization);
        organizations.push(newOrganization);
        isOrganization[newOrganization] = true;
        return newOrganization;
    }

    /**
     * @notice Deploys a new campaign and ticket contract.
     * @param defaultAdmin The address of the admin for the contracts.
     * @param lottery The address of the lottery contract.
     * @param organization The address of organization contract to that tickets belong to.
     * @param campaignName The name of the campaign.
     * @return deployedCampaign The address of the newly deployed campaign contract.
     * @return deployedTicket The address of the newly deployed ticket contract.
     */
    function _deployCampaignAndTicketContract(
        address defaultAdmin,
        address lottery,
        address organization,
        string memory campaignName
    ) private returns (address deployedCampaign, address deployedTicket) {
        if (!isOrganization[organization]) revert IncorrectValue("Not valid organization contract");
        if (!activeOrganizations.contains(organization)) revert IncorrectValue("Organization is disabled");
        if (!isLottery[lottery]) revert IncorrectValue("Not valid lottery contract");
        if (ILottery(lottery).mintDeadline() < block.timestamp) revert IncorrectCondition("Mint deadline is in the past");
        if (bytes(campaignName).length == 0) revert IncorrectValue("Campaign name is empty");

        deployedCampaign = CampaignDeployerLibrary.deployCampaignContract(
                defaultAdmin,
                address(this),
                minterContract,
                campaigns.length,
                lottery,
                organization,
                campaignName
        );
        campaigns.push(deployedCampaign);
        campaignOrganization[deployedCampaign] = organization;


        deployedTicket = _deployTicketContract(
            defaultAdmin,
            deployedCampaign,
            campaignName
        );
        IKarrotCampaign(deployedCampaign).setTicketContract(deployedTicket);
        ILottery(lottery).registerTicketContract(deployedTicket);
    }

    /**
     * @notice Deploys a new lottery contract.
     * @param _defaultAdmin The address of the admin for the contract.
     * @param _mintDeadline The deadline for ticket minting.
     * @param _burnDeadline The deadline for ticket burning.
     * @param _lotteryTime The time when the lottery will be conducted.
     * @return newLottery The address of the newly deployed lottery contract.
     * @dev Reverts if _mintDeadline is greater than _burnDeadline,
     *  _burnDeadline is greater than _lotteryTime,
     *  _mintDeadline is greater than _lotteryTime.
     */
    function _deployLotteryContract(
        address _defaultAdmin,
        uint32 _mintDeadline,
        uint32 _burnDeadline,
        uint32 _lotteryTime
    ) private returns (address) {

        address newLottery = LotteryDeployerLibrary.deployLotteryContract(
            _defaultAdmin, 
            address(this), 
            lotteries.length, 
            _mintDeadline, 
            _burnDeadline, 
            _lotteryTime
        );
        
        lotteries.push(newLottery);
        isLottery[newLottery] = true;
        return newLottery;
    }

    /**
     * @notice Deploys a new redemption contract.
     * @param _defaultAdmin The address of the admin for the contract.
     * @param _lottery The address of the associated lottery contract.
     * @return newRedemption The address of the newly deployed redemption contract.
     */
    function _deployRedemptionContract(
        address _defaultAdmin,
        address _lottery
    ) private returns (address) {

        address newRedemption = RedemptionDeployerLibrary.deployRedemtionContract(
            _defaultAdmin,
            _lottery,
            redemptions.length
        );

        redemptions.push(newRedemption);
        return newRedemption;
    }

    /**
     * @notice Deploys a new ticket contract.
     * @param _defaultAdmin The address of the admin for the contract.
     * @param _campaign The address of the associated campaign contract.
     * @param _campaignName The name of the campaign.
     * @return newTicket The address of the newly deployed ticket contract.
     */
    function _deployTicketContract(
        address _defaultAdmin,
        address _campaign,
        string memory _campaignName
    ) private returns (address) {

        address newTicket = TicketDeployerLibrary.deployTicket(
            _defaultAdmin,
            minterContract,
            tickets.length,
            _campaign,
            _campaignName
        );

        tickets.push(newTicket);
        ticketsCampaign[newTicket] = _campaign;
        return newTicket;
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return A boolean indicating whether the contract supports the interface.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(AccessControl, IERC165)
        returns (bool)
    {
        return 
            type(IKarrotFactory).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }
}