// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {KarrotOrganization} from "./KarrotOrganization.sol";
import {KarrotCampaign} from "./KarrotCampaign.sol";
import {Lottery} from "./Lottery.sol";
import {KarrotTicket} from "./KarrotTicket.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {ILottery} from "./interface/ILottery.sol";
import {IKarrotCampaign} from "./interface/IKarrotCampaign.sol";
import {IKarrotFactory} from "./interface/IKarrotFactory.sol";
import {ITicketMinter} from "./interface/ITicketMinter.sol";

import {OrganizationDeployerLibrary} from "./libraries/OrganizationDeployerLibrary.sol";
import {CampaignDeployerLibrary} from "./libraries/CampaignDeployerLibrary.sol";
import {TicketDeployerLibrary} from "./libraries/TicketDeployerLibrary.sol";

contract KarrotFactory is AccessControl, IKarrotFactory {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER");
    address public minterContract;

    address[] public lotteries;
    address[] public organizations;
    address[] public campaigns;
    address[] public tickets;

    mapping(address => bool) public isOrganization;
    mapping(address => bool) public isLottery;
    mapping(address => address) public campaignOrganization;
    mapping(address => address) public ticketsCampaign;
   
    modifier withSetupMinterContract() {
        if (minterContract == address(0)) revert IncorrectCondition("Minter contract not set");
        _;
    }

    constructor(address _deployer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEPLOYER_ROLE, _deployer);
    }

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

    function deployLotteryContract(
        address _defaultAdmin,
        uint32 _mintDeadline,
        uint32 _burnDeadline,
        uint32 _lotteryTime
    ) public withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns (address) {
         
            address newLottery = _deployLotteryContract(
                _defaultAdmin,
                _mintDeadline,
                _burnDeadline,
                _lotteryTime
            );
            emit LotteryContractDeployed(newLottery);

            return newLottery;
    }

    function deployOrganizationContract(
        address defaultAdmin,
        string memory organizationName
    ) public withSetupMinterContract onlyRole(DEPLOYER_ROLE) returns (address) {
        address newOrganization = _deployOrganizationContract(defaultAdmin, organizationName);
        emit OrganizationContractDeployed(newOrganization);
        return newOrganization;
    }

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

    function getAllLotteries() external view returns (address[] memory) {
        return lotteries;
    }

    function getAllOrganizations() external view returns (address[] memory) {
        return organizations;
    }

    function getAllCampaigns() external view returns (address[] memory) {
        return campaigns;
    }

    function getAllTickets() external view returns (address[] memory) {
        return tickets;
    }

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
        organizations.push(newOrganization);
        isOrganization[newOrganization] = true;
        return newOrganization;
    }

    function _deployCampaignAndTicketContract(
        address defaultAdmin,
        address lottery,
        address organization,
        string memory campaignName
    ) private returns (address deployedCampaign, address deployedTicket) {
        if (!isOrganization[organization]) revert IncorrectValue("Not valid organization contract");
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

    function _deployLotteryContract(
        address _defaultAdmin,
        uint32 _mintDeadline,
        uint32 _burnDeadline,
        uint32 _lotteryTime
    ) private returns (address) {
        address newLottery = address(
            new Lottery{salt: keccak256(abi.encodePacked(lotteries.length))}(
                _defaultAdmin,
                address(this),
                _mintDeadline,
                _burnDeadline,
                _lotteryTime
            )
        );
        lotteries.push(newLottery);
        isLottery[newLottery] = true;
        return newLottery;
    }

    function _deployTicketContract(
        address _defaultAdmin,
        address _campaign,
        string memory _campaignName
    ) private returns (address) {

        if (bytes(_campaignName).length == 0) revert IncorrectValue("Campaign name is empty");

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


