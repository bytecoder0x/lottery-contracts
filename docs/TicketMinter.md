# Solidity API

## TicketMinter

The TicketMinter contract manages the creation of tickets for campaigns on the Karrot platform by interfacing with the KarrotFactory.

_TicketMinter ensures that tickets are minted for end owners within specified campaigns._

### MINTER_ROLE

```solidity
bytes32 MINTER_ROLE
```

Сonstant that contains the MINTER role. Owner of this role can mint organization, campaigns and tickets.

### factory

```solidity
contract IKarrotFactory factory
```

Address of the KarrotFactory contract.

### constructor

```solidity
constructor(address _defaultAdmin, address _minter, address _factory) public
```

Constructor function to initialize the TicketMinter contract.

_Reverts if the factory contract does not support their respective interfaces._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultAdmin | address | The address of the admin this contract. |
| _minter | address | The address of the minter role. |
| _factory | address | The address of the KarrotFactory contract. |

### mintTicketsBatch

```solidity
function mintTicketsBatch(address[] endOwners, address campaign, uint256[] ticketsCounts) public returns (uint256[][] ticketsTokenIds)
```

Mints tickets for multiple end owners in batches.

_Reverts if the length of `endOwners` does not match the length of `ticketsCounts`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| endOwners | address[] | An array of end owners to whom tickets will be minted. |
| campaign | address | The address of the campaign for which tickets are being minted. |
| ticketsCounts | uint256[] | An array specifying the number of tickets to mint for each end owner. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ticketsTokenIds | uint256[][] | An array of arrays containing the token IDs of the minted tickets for each end owner. |

### mintTickets

```solidity
function mintTickets(address endOwner, address campaign, uint256 ticketsCount) public returns (uint256[] ticketsTokenIds)
```

Mints tickets for a specific end owner in a campaign.

_If any organization is found for the endOwner, we will mint it for him.
If any campaign is found for the endOwner, we will mint it for him._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| endOwner | address | The address of the end owner who will receive the tickets. |
| campaign | address | The address of the campaign for which tickets are being minted. |
| ticketsCount | uint256 | The number of tickets to mint. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| ticketsTokenIds | uint256[] | An array containing the token IDs of the minted tickets. |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

Checks if the contract supports a given interface.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| interfaceId | bytes4 | The interface identifier. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | A boolean indicating whether the contract supports the interface. |

