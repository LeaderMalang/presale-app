// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the Ownable contract from OpenZeppelin for secure ownership management.
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EcommerceContract
 * @dev A smart contract to manage product purchases, referral commissions,
 * and lucky draw prize distributions for a MERN e-commerce application.
 * This contract is intended for deployment on the Binance Smart Chain (BSC).
 */
contract EcommerceContract is Ownable {
    //=======================================
    // State Variables
    //=======================================

    uint256 public constant PRODUCT_PRICE = 0.05 ether; // Price in BNB (or ETH-like value on BSC)
    uint256 public constant REFERRAL_COMMISSION_BPS = 1000; // 10% (1000 basis points)

    // A mapping to track which addresses have purchased the product.
    // This is useful for determining lucky draw eligibility on the backend.
    mapping(address => bool) public hasPurchased;

    //=======================================
    // Events
    //=======================================

    /**
     * @dev Emitted when a user successfully purchases the product.
     * @param buyer The address of the user who made the purchase.
     * @param referrer The address of the referrer who received a commission.
     * @param amount The total amount paid by the buyer.
     * @param commissionAmount The commission amount sent to the referrer.
     */
    event ProductPurchased(
        address indexed buyer,
        address indexed referrer,
        uint256 amount,
        uint256 commissionAmount
    );

    /**
     * @dev Emitted when the admin distributes lucky draw prizes.
     * @param winners An array of addresses of the prize winners.
     * @param amounts An array of the prize amounts sent to each winner.
     */
    event PrizesDistributed(address[] winners, uint256[] amounts);

    //=======================================
    // Constructor
    //=======================================

    /**
     * @dev Sets the initial owner of the contract upon deployment.
     * The deployer's address will be the owner.
     */
    constructor() Ownable(msg.sender) {}

    //=======================================
    // Core Functions
    //=======================================

    /**
     * @dev Allows a user to purchase the product and triggers a commission payment.
     * @param _referrer The wallet address of the user who referred the buyer.
     * Use address(0) if there is no referrer.
     */
    function purchase(address _referrer) external payable {
        // 1. Validate the payment amount
        require(
            msg.value == PRODUCT_PRICE,
            "EcommerceContract: Incorrect amount sent for purchase."
        );

        // 2. Mark the buyer as having purchased the product
        hasPurchased[msg.sender] = true;

        uint256 commissionAmount = 0;

        // 3. Handle referral commission if a valid referrer is provided
        if (_referrer != address(0) && _referrer != msg.sender) {
            commissionAmount = (msg.value * REFERRAL_COMMISSION_BPS) / 10000;
            
            // Securely send the commission to the referrer
            (bool success, ) = _referrer.call{value: commissionAmount}("");
            require(success, "EcommerceContract: Failed to send commission.");
        }

        // 4. Emit the event for backend tracking
        emit ProductPurchased(
            msg.sender,
            _referrer,
            msg.value,
            commissionAmount
        );
    }

    /**
     * @dev Distributes prizes to lucky draw winners. Can only be called by the contract owner.
     * The contract must be funded with enough BNB to cover all prize payments.
     * @param _winners An array of winner addresses.
     * @param _amounts An array of prize amounts corresponding to each winner.
     */
    function distributePrizes(
        address[] calldata _winners,
        uint256[] calldata _amounts
    ) external onlyOwner {
        // Validate that the input arrays are not empty and have the same length
        require(
            _winners.length > 0,
            "EcommerceContract: Winners array cannot be empty."
        );
        require(
            _winners.length == _amounts.length,
            "EcommerceContract: Winners and amounts arrays must have the same length."
        );

        uint256 totalPrizeAmount = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalPrizeAmount += _amounts[i];
        }

        // Check if the contract has enough balance to pay all prizes
        require(
            address(this).balance >= totalPrizeAmount,
            "EcommerceContract: Insufficient contract balance to distribute prizes."
        );

        // Loop through and send the prize to each winner
        for (uint i = 0; i < _winners.length; i++) {
            require(
                _winners[i] != address(0),
                "EcommerceContract: Cannot send prize to the zero address."
            );
            (bool success, ) = _winners[i].call{value: _amounts[i]}("");
            require(
                success,
                "EcommerceContract: Failed to send prize to a winner."
            );
        }

        // Emit the event for tracking purposes
        emit PrizesDistributed(_winners, _amounts);
    }

    //=======================================
    // Utility Functions
    //=======================================

    /**
     * @dev Allows the owner to withdraw the contract's entire BNB balance.
     * This is for transferring the 90% share of sales revenue to the project wallet.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(
            success,
            "EcommerceContract: Failed to withdraw contract balance."
        );
    }

    // Fallback function to receive BNB directly (e.g., for funding the prize pool)
    receive() external payable {}
}
