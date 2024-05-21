# Solidity API

## KarrotFactory

The KarrotFactory contract serves as a factory for various contracts 
such as organizations, campaigns, lotteries, redemption and tickets.

_KarrotFactory manages the deployment process and keeps track of deployed contracts._

### DEPLOYER_ROLE

```solidity
bytes32 DEPLOYER_ROLE
```

Сonstant that contains the DEPLOYER role. Owner of this role can deploy contracts.

### minterContract

```solidity
address minterContract
```

Address of the minterContract that can mint organization, campaigns and tickets. Expected to be the TicketMinter contract.

### randomGetterContract

```solidity
address randomGetterContract
```

Address of the randomGetterContract providing random numbers. Expected to be the RandomGetter contract.

### lotteries

```solidity
address[] lotteries
```

Stores addresses of deployed lottery contracts.

### redemptions

```solidity
address[] redemptions
```

Stores addresses of deployed redemption contracts.

### organizations

```solidity
address[] organizations
```

Stores addresses of deployed organization contracts.

### campaigns

```solidity
address[] campaigns
```

Stores addresses of deployed campaign contracts.

### tickets

```solidity
address[] tickets
```

Stores addresses of deployed ticket contracts.

### isOrganization

```solidity
mapping(address => bool) isOrganization
```

Checks if an address is an organization.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### isLottery

```solidity
mapping(address => bool) isLottery
```

Checks if an address is a lottery contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### campaignOrganization

```solidity
mapping(address => address) campaignOrganization
```

Retrieves the organization associated with a campaign contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### ticketsCampaign

```solidity
mapping(address => address) ticketsCampaign
```

Retrieves the campaign associated with a ticket contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### withSetupMinterContract

```solidity
modifier withSetupMinterContract()
```

The modifier checks whether the function is without set minter contract.

### withSetupRandomGetterContract

```solidity
modifier withSetupRandomGetterContract()
```

The modifier checks whether the function is without set randomGetter contract.

### constructor

```solidity
constructor(address _deployer) public
```

Constructor function to initialize the KarrotFactory contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _deployer | address | The address of the deployer role. |

### disableOrganization

```solidity
function disableOrganization(address _organization) external
```

Disables an organization if they leave the project.

_Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
If the organization is Non Karrot or already disabled, reverts with an error message._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _organization | address |  |

### enableOrganization

```solidity
function enableOrganization(address _organization) external
```

Enables an organization if they are returned in the project.

_Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
If the organization is already enabled, reverts with an error message._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _organization | address |  |

### setMinterContract

```solidity
function setMinterContract(address _minterContract) external
```

Sets the minter contract address for ticket minting.

_Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
Reverts if the minter contract does not support the required interface._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minterContract | address | The address of the minter contract to be set. |

### setRandomGetterContract

```solidity
function setRandomGetterContract(address _randomGetterContract) external
```

Sets the randomGetter contract address to get a random number in the lottery.

_Only can be called by accounts with the DEFAULT_ADMIN_ROLE.
Reverts if the randomGetter contract does not support the required interface._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _randomGetterContract | address | The address of the randomGetter contract to be set. |

### deployLotteryAndRedemptionContract

```solidity
function deployLotteryAndRedemptionContract(address _defaultAdmin, uint32 _mintDeadline, uint32 _burnDeadline, uint32 _lotteryTime) public returns (address newLottery, address newRedemption)
```

Deploys a new lottery and redemption contract.

_Only can be called by accounts with the DEPLOYER_ROLE.
Reverts if mintDeadline is greater than burnDeadline,
 burnDeadline is greater than lotteryTime,
 mintDeadline is greater than lotteryTime._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultAdmin | address |  |
| _mintDeadline | uint32 |  |
| _burnDeadline | uint32 |  |
| _lotteryTime | uint32 |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| newLottery | address |  |
| newRedemption | address |  |

### deployOrganizationContract

```solidity
function deployOrganizationContract(address defaultAdmin, string organizationName) public returns (address)
```

Deploys a new organization contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| defaultAdmin | address | The address of the admin for the contract. |
| organizationName | string | The name of the organization. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

### deployCampaignAndTicketContract

```solidity
function deployCampaignAndTicketContract(address defaultAdmin, address lottery, address organization, string campaignName) public returns (address, address)
```

Deploys a new campaign and ticket contract.

_Only can be called by accounts with the DEPLOYER_ROLE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| defaultAdmin | address | The address of the admin for the contracts. |
| lottery | address | The address of the lottery contract. |
| organization | address | The address of the parent organization contract. |
| campaignName | string | The name of the campaign. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |
| [1] | address |  |

### deployOrganizationAndCampaigns

```solidity
function deployOrganizationAndCampaigns(address _defaultAdmin, address _lottery, string _organizationName, string[] _campaignNames) external returns (address deployedOrganization, address[] deployedCampaigns, address[] deployedTickets)
```

Deploys an organization contract and multiple campaigns that are linked to the organization and corresponding ticket contracts.

_Only can be called by accounts with the DEPLOYER_ROLE._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultAdmin | address |  |
| _lottery | address |  |
| _organizationName | string |  |
| _campaignNames | string[] |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| deployedOrganization | address | The address of the newly deployed organization contract. |
| deployedCampaigns | address[] | An array containing the addresses of the newly deployed campaign contracts. |
| deployedTickets | address[] | An array containing the addresses of the newly deployed ticket contracts. |

### getAllLotteries

```solidity
function getAllLotteries() external view returns (address[])
```

Retrieves the addresses of all deployed lottery contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array containing the addresses of all deployed lottery contracts. |

### getAllRedemptions

```solidity
function getAllRedemptions() external view returns (address[])
```

Retrieves the addresses of all deployed redemption contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array containing the addresses of all deployed redemption contracts. |

### getAllOrganizations

```solidity
function getAllOrganizations() external view returns (address[])
```

Retrieves the addresses of all deployed organization contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array containing the addresses of all deployed organization contracts. |

### getAllCampaigns

```solidity
function getAllCampaigns() external view returns (address[])
```

Retrieves the addresses of all deployed campaign contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array containing the addresses of all deployed campaign contracts. |

### getAllTickets

```solidity
function getAllTickets() external view returns (address[])
```

Retrieves the addresses of all deployed ticket contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address[] | An array containing the addresses of all deployed ticket contracts. |

### getLotteriesCount

```solidity
function getLotteriesCount() external view returns (uint256)
```

Returns the amount of deployed lottery contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of deployed lottery contracts. |

### getRedemptionsCount

```solidity
function getRedemptionsCount() external view returns (uint256)
```

Returns the amount of deployed redemption contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of deployed redemption contracts. |

### getOrganizationsCount

```solidity
function getOrganizationsCount() external view returns (uint256)
```

Returns the amount of deployed organization contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of deployed organization contracts. |

### getCampaignsCount

```solidity
function getCampaignsCount() external view returns (uint256)
```

Returns the amount of deployed campaign contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of deployed campaign contracts. |

### getTicketsCount

```solidity
function getTicketsCount() external view returns (uint256)
```

Returns the amount of deployed ticket contracts.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The amount of deployed ticket contracts. |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

