# Solidity API

## KarrotOrganization

The KarrotOrganization contract handles the creation and ownership of organization tokens in Karrot.

_KarrotOrganization allows minting new tokens for specific addresses and ensures each address can own only one organization token._

### ownerToken

```solidity
mapping(address => uint256) ownerToken
```

Retrieves the token ID owned by the specified address.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor(address _defaultAdmin, address _minter, string _name) public
```

Constructor function to initialize the KarrotOrganization contract.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _defaultAdmin | address | The address of the admin this contract. |
| _minter | address | The address of the minter role. |
| _name | string | The name of the contract. |

### mintTo

```solidity
function mintTo(address to, bytes data) public returns (uint256)
```

Mints a new organization token to the specified address.

_Reverts if the recipient already owns an organization token._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to mint the token to. |
| data | bytes | Additional data to include in the minted token. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The ID of the newly minted token. |

### ownerOf

```solidity
function ownerOf(uint256 tokenId) public view returns (address)
```

Used to retrieve the *root* owner of a given token.

_The *root* owner of the token is an externally owned account (EOA). If the given token is child of another
 NFT, this will return an EOA address. Otherwise, if the token is owned by an EOA, this EOA will be returned._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | ID of the token for which the *root* owner has been retrieved |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

### _beforeAcceptChild

```solidity
function _beforeAcceptChild(uint256, uint256, address childAddress, uint256) internal virtual
```

Performs check whether the child has IKarrotCampaign interface before accepting it.

_Throws an error if the child contract does not support the IKarrotCampaign interface._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | uint256 |  |
|  | uint256 |  |
| childAddress | address | The address of the child contract. |
|  | uint256 |  |

