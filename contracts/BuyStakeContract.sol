// SPDX-License-Identifier: MIT
// aasanhai.pk
// TG: @leadermalang

pragma solidity ^0.8.20;

// Import necessary contracts from the OpenZeppelin library
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title INTBuyStake Contract
 * @dev A contract for a token presale with staking reward features.
 * Users can buy a specific sale token using either native currency (like ETH) or other approved ERC20 tokens.
 * It also includes a mechanism for buyers to earn rewards over time based on their purchased amount.
 */
contract INTBuyStake is Ownable {
    using SafeERC20 for IERC20;

    // Struct to store details about each buyer's purchase and rewards.
    struct BuyerTokenDetails {
        uint256 amount; // The amount of saleToken purchased.
        bool exists; // Flag to check if the user is a buyer.
        bool isClaimed; // (Note: This variable is declared but not used in the original logic).
        uint256 reward; // Accumulated rewards.
        uint lastCalculatedTime; // Timestamp of the last reward calculation.
    }

    // --- State Variables ---

    uint256 public multiplier; // Reward multiplier in basis points (e.g., 10000 = 100%).
    uint256 public rate; // The price of the saleToken in the native currency (e.g., wei per token).
    address public saleToken; // The ERC20 token being sold.
    uint public saleTokenDec; // Decimals of the sale token.
    uint256 public totalTokensforSale; // Total amount of saleToken available for the presale.
    bool public saleStatus; // True if the sale is active, false otherwise.
    address[] public buyers; // An array of all buyer addresses.
    uint256 public totalTokensSold; // Total amount of saleToken sold so far.

    // Mappings
    mapping(address => bool) public payableTokens; // Maps allowed ERC20 tokens to a boolean status.
    mapping(address => BuyerTokenDetails) public buyersDetails; // Maps a buyer's address to their details.
    mapping(address => uint256) public tokenPrices; // Maps allowed ERC20 tokens to their price.

    // --- Modifiers ---

    modifier saleEnabled() {
        require(saleStatus == true, "Presale: is not enabled");
        _;
    }

    modifier saleStoped() {
        require(saleStatus == false, "Presale: is not stopped");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender){
        saleStatus = false; // The sale is initially disabled.
    }

    // --- Owner Functions ---

    /**
     * @dev Sets the initial parameters for the presale.
     * This function transfers the total sale tokens from the owner to the contract.
     */
    function setParams(
        address _saleToken,
        uint256 _totalTokensforSale,
        uint256 _rate,
        uint _multiplier,
        bool _saleStatus
    ) external onlyOwner {
        require(_rate != 0, "Presale: Rate cannot be zero");
        rate = _rate;
        saleToken = _saleToken;
        saleStatus = _saleStatus;
        saleTokenDec = IERC20Metadata(saleToken).decimals();
        totalTokensforSale = _totalTokensforSale;
        multiplier = _multiplier;
        IERC20(saleToken).safeTransferFrom(
            msg.sender,
            address(this),
            totalTokensforSale
        );
    }

    /**
     * @dev Sets the reward multiplier.
     * It updates all existing rewards before changing the multiplier.
     */
    function setMultiplier(uint256 _multiplier) public onlyOwner {
        updateRewards();
        multiplier = _multiplier;
    }

    /**
     * @dev Increases the total number of tokens available for sale.
     */
    function increaseTotalTokensforSale(
        uint256 _totalTokensforSale
    ) external onlyOwner {
        totalTokensforSale += _totalTokensforSale;
        IERC20(saleToken).safeTransferFrom(
            msg.sender,
            address(this),
            _totalTokensforSale
        );
    }

    function stopSale() external onlyOwner {
        saleStatus = false;
    }

    function resumeSale() external onlyOwner {
        saleStatus = true;
    }

    /**
     * @dev Adds new ERC20 tokens that can be used for purchase and sets their prices.
     */
    function addPayableTokens(
        address[] memory _tokens,
        uint256[] memory _prices
    ) external onlyOwner {
        require(
            _tokens.length == _prices.length,
            "Presale: tokens & prices arrays length mismatch"
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_prices[i] != 0, "Presale: Price cannot be zero");
            payableTokens[_tokens[i]] = true;
            tokenPrices[_tokens[i]] = _prices[i];
        }
    }

    /**
     * @dev Enables or disables an ERC20 token for payment.
     */
    function payableTokenStatus(
        address _token,
        bool _status
    ) external onlyOwner {
        require(payableTokens[_token] != _status, "Presale: Status is already set to the desired value");
        payableTokens[_token] = _status;
    }

    /**
     * @dev Updates the prices of allowed ERC20 tokens and optionally the native currency rate.
     */
    function updateTokenRate(
        address[] memory _tokens,
        uint256[] memory _prices,
        uint256 _rate
    ) external onlyOwner {
        require(
            _tokens.length == _prices.length,
            "Presale: tokens & prices arrays length mismatch"
        );
        if (_rate != 0) {
            rate = _rate;
        }
        for (uint256 i = 0; i < _tokens.length; i += 1) {
            require(payableTokens[_tokens[i]] == true, "Presale: Token is not a payable token");
            require(_prices[i] != 0, "Presale: Price cannot be zero");
            tokenPrices[_tokens[i]] = _prices[i];
        }
    }

    /**
     * @dev Unlocks and sends tokens for all buyers. Can only be called by the owner when the sale is stopped.
     */
    function unlockAllTokens() external onlyOwner saleStoped {
        for (uint256 i = 0; i < buyers.length; i++) {
            unlockTokenFor(buyers[i]);
        }
    }

    /**
     * @dev Allows the owner to withdraw all remaining sale tokens from the contract.
     */
    function withdrawAllSaleTokens() external onlyOwner saleStoped {
        uint256 amt = IERC20(saleToken).balanceOf(address(this));
        IERC20(saleToken).transfer(msg.sender, amt);
        totalTokensforSale = 0;
    }

    function withdraw(address token, uint256 amt) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        uint256 amt = IERC20(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }


    // --- Public/External Functions ---

    /**
     * @dev Allows a user to buy saleToken using native currency (msg.value) or an approved ERC20 token.
     */
    function buyToken(
        address _token,
        uint256 _amount
    ) external payable saleEnabled {
        uint256 saleTokenAmt = _token != address(0)
        ? getTokenAmount(_token, _amount)
        : getTokenAmount(address(0), msg.value);
        
        require(
            (totalTokensSold + saleTokenAmt) < totalTokensforSale,
            "Presale: Not enough tokens to be sale"
        );

        if (_token != address(0)) {
            require(_amount > 0, "Presale: Amount must be greater than 0");
            IERC20(_token).safeTransferFrom(msg.sender, owner(), _amount);
        } else {
            payable(owner()).transfer(msg.value);
        }

        totalTokensSold += saleTokenAmt;
        BuyerTokenDetails storage buyerDetails = buyersDetails[msg.sender];

        if (!buyerDetails.exists) {
            buyers.push(msg.sender);
            buyerDetails.exists = true;
        } else if (buyerDetails.amount > 0) {
            // Add existing rewards before adding new amount
            buyerDetails.reward += getBuyerReward(msg.sender);
        }
        buyerDetails.amount += saleTokenAmt;
        buyerDetails.lastCalculatedTime = block.timestamp;
    }

    /**
     * @dev Allows a buyer to claim their purchased tokens and accrued rewards after the sale has stopped.
     */
    function unlockToken() external saleStoped {
        require(
            buyersDetails[msg.sender].amount > 0,
            "Presale: No tokens to claim"
        );
        unlockTokenFor(msg.sender);
    }

    // --- View/Pure Functions ---

    /**
     * @dev Calculates the amount of saleToken a user will receive for a given amount of payment token.
     * @param token The address of the payment token (address(0) for native currency).
     * @param amount The amount of the payment token.
     * @return The amount of saleToken to be received.
     */
    function getTokenAmount(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 amtOut;
        if (token != address(0)) {
            require(payableTokens[token] == true, "Presale: Token not allowed");
            uint256 price = tokenPrices[token];
            amtOut = (amount * (10 ** saleTokenDec)) / (price);
        } else {
            amtOut = (amount * (10 ** saleTokenDec)) / (rate);
        }
        return amtOut;
    }

    /**
     * @dev Calculates the pending reward for a buyer.
     */
    function getBuyerReward(address buyer) public view returns (uint256) {
        if (buyersDetails[buyer].amount == 0) return 0;

        uint daysPassed = (block.timestamp -
            buyersDetails[buyer].lastCalculatedTime) / 86400;

        uint256 reward = (buyersDetails[buyer].amount *
            multiplier *
            daysPassed) / 10000;
        return reward;
    }

    // --- Internal Functions ---

    /**
     * @dev Updates the rewards for all buyers.
     * This is called internally before changing the reward multiplier.
     */
    function updateRewards() internal {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (buyersDetails[buyers[i]].amount > 0) {
                buyersDetails[buyers[i]].reward = getBuyerReward(buyers[i]);
                buyersDetails[buyers[i]].lastCalculatedTime = block.timestamp;
            }
        }
    }

    /**
     * @dev Performs the token unlock and transfer for a specific buyer.
     * It calculates total tokens (purchased + existing rewards + new rewards) and transfers them.
     */
    function unlockTokenFor(address buyer) internal {
        if (buyersDetails[buyer].amount > 0) {
            uint256 tokensforWithdraw = buyersDetails[buyer].amount +
            buyersDetails[buyer].reward +
            getBuyerReward(buyer);
            
            buyersDetails[buyer].amount = 0;
            buyersDetails[buyer].reward = 0;
            
            IERC20(saleToken).safeTransfer(buyer, tokensforWithdraw);
        }
    }
}