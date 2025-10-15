// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title AssetToken
 * @author Hassan Ali
 * @notice An ERC1155 contract to represent AI datasets and models as unique tokens.
 * @dev Uses AccessControl for role-based permissions and a counter for unique token IDs.
 */
contract AssetToken is ERC1155, AccessControl {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    struct AssetData {
        uint256 licenseId;
        address owner; // The original minter/owner
    }
    mapping(uint256 => AssetData) public assetData;
    mapping(uint256 => string) private _tokenURIs;

    // --- Errors ---
    error InvalidTokenId(uint256 tokenId);

    // --- Constructor ---
    constructor(
        address _defaultAdmin,
        address _minter,
        address _uriSetter,
        string memory _initialURI
    ) ERC1155(_initialURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, _minter);
        _grantRole(URI_SETTER_ROLE, _uriSetter);
    }

    // --- Core Logic ---

    /**
     * @notice Mints a new asset token.
     * @dev Only callable by an address with MINTER_ROLE.
     * @param _owner The address that will own the new asset.
     * @param _licenseId The identifier for the asset's license.
     * @param _initialURI The metadata URI for the new asset.
     * @param _data Additional data with no specified format.
     * @return The ID of the newly created token.
     */
    function mint(address _owner, uint256 _licenseId, string memory _initialURI, bytes memory _data)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        assetData[newId] = AssetData({
            licenseId: _licenseId,
            owner: _owner
        });
        
        // Mint a single token of this new ID
        _mint(_owner, newId, 1, _data);
        _setURI(newId, _initialURI);
        
        return newId;
    }
    
    /**
     * @notice Sets the license ID for a given asset.
     * @dev Only callable by the contract admin.
     */
    function setLicense(uint256 _tokenId, uint256 _newLicenseId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!_exists(_tokenId)) revert InvalidTokenId(_tokenId);
        assetData[_tokenId].licenseId = _newLicenseId;
    }

    // --- View Functions ---
    
    /**
     * @notice Returns the URI for a given token ID.
     * @dev Overridden to support per-token URIs. Falls back to the base URI if a specific one isn't set.
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[_tokenId];
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }
        return super.uri(_tokenId);
    }

    /**
     * @notice Public function to check if a token ID has been minted.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }
    
    /**
     * @notice Returns the license ID for a given asset token.
     */
    function licenseId(uint256 _tokenId) public view returns (uint256) {
        return assetData[_tokenId].licenseId;
    }

    /**
     * @notice Returns the original owner/creator of the asset token.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        if (!_exists(_tokenId)) revert InvalidTokenId(_tokenId);
        return assetData[_tokenId].owner;
    }
    
    /**
     * @notice Internal check if a token ID is valid.
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _tokenId > 0 && _tokenId <= _tokenIdCounter.current();
    }


    // --- Internal & Overrides ---

    /**
     * @notice Sets the URI for a given token ID.
     * @dev Restricted to URI_SETTER_ROLE. This function does not override a parent function.
     */
    function _setURI(uint256 _tokenId, string memory _newuri) internal onlyRole(URI_SETTER_ROLE) {
        _tokenURIs[_tokenId] = _newuri;
    }

    /**
     * @notice Hook that is called before any token transfer.
     * @dev Overridden to match the latest OpenZeppelin signature.
     */
    // function _update(address from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data)
    //     internal
    //     override(ERC1155)
    // {
    //     // This functionality can be customized or restricted if needed.
    //     // For now, we allow standard transfers.
    //     super._update(from, to, ids, values);
    // }

    /**
     * @notice Overridden to support both ERC1155 and AccessControl interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

