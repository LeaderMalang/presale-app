// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Titan Royale (TROY) Token
 * @dev A fixed-supply BEP-20 token for Titan Royale.
 *
 * This contract creates a token with a maximum supply of 888,888,888 TROY.
 * The entire supply is distributed upon creation to the owner reserve and
 * public circulation addresses.
 * No new tokens can be minted after deployment.
 * The contract is based on the OpenZeppelin ERC20 and Ownable contracts.
 */
contract TitanRoyale is ERC20, Ownable {
    /**
     * @dev Constructor that sets the token's name, symbol, and distributes the supply.
     * The entire supply is minted to the owner reserve and public circulation addresses.
     * The deployer of the contract is set as the initial owner.
     * @param ownerReserve The address to receive the Owner Reserve tokens (40%).
     * @param publicCirculation The address to receive the Public Circulation tokens (60%).
     */
    constructor(address ownerReserve, address publicCirculation)
        ERC20("Titan Royale", "TROY")
        Ownable(msg.sender)
    {
        require(ownerReserve != address(0), "TROY: Owner reserve address cannot be the zero address");
        require(publicCirculation != address(0), "TROY: Public circulation address cannot be the zero address");

        uint256 decimalsMultiplier = 10**decimals();

        // --- Distribution Amounts ---
        // Owner Reserve (Hold): 40% -> 355,555,555 TROY
        uint256 ownerReserveAmount = 355_555_555 * decimalsMultiplier;

        // Public Circulation: 60% -> 533,333,333 TROY
        uint256 publicCirculationAmount = 533_333_333 * decimalsMultiplier;
        
        // --- Sanity Check ---
        // Ensure the distribution amounts correctly add up to the max supply.
        uint256 maxSupply = 888_888_888 * decimalsMultiplier;
        require(
            ownerReserveAmount + publicCirculationAmount == maxSupply,
            "TROY: Distribution amounts do not match max supply"
        );

        // Mint tokens to the respective addresses
        _mint(ownerReserve, ownerReserveAmount);
        _mint(publicCirculation, publicCirculationAmount);
    }
}

