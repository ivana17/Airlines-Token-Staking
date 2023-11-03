// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TransferFailed();
error NoStakedToken();
error InvalidToken();
error LockedPeriod(string message);

contract StakeContract is Ownable {
    struct Stake {
        bool hasStaked;
        bool hasClaimed;
        uint256 amount;
        uint256 stakingTime;
    }

    mapping(address => mapping(address => Stake)) public balances;
    mapping(address => bool) public allowedTokens;
    mapping(address => uint8) public APYs;
    uint32 public constant LOCKED_PERIOD = 2629743 * 3;

    constructor(address tokenAddress, uint8 tokenAPY) {
        addStakingToken(tokenAddress, tokenAPY);
    }

    function stake(uint256 amount, address token) external returns (bool) {
        require(amount > 0, "Amount must be greater than 0.");
        if (token == address(0x0) || !allowedTokens[token])
            revert InvalidToken();

        address user = msg.sender;
        if (balances[user][token].hasStaked) {
            if (!isLockedPeriod(user, token))
                revert LockedPeriod("Tokens should be collected first.");
            balances[user][token].amount =
                balances[user][token].amount +
                amount;
            balances[user][token].stakingTime = block.timestamp;
        } else {
            balances[user][token] = Stake(true, false, amount, block.timestamp);
        }

        bool success = IERC20(token).transferFrom(user, address(this), amount);
        if (!success) revert TransferFailed();

        return success;
    }

    function withdraw(address token) external {
        if (token == address(0x0) || !allowedTokens[token])
            revert InvalidToken();
        if (!balances[msg.sender][token].hasStaked) revert NoStakedToken();

        address user = msg.sender;
        uint256 amount = balances[user][token].amount;
        if (isLockedPeriod(user, token)) {
            amount = amount / 2;
        } else {
            require(
                balances[user][token].hasClaimed,
                "The reward hasn't been claimed."
            );
        }

        delete balances[user][token];

        bool success = IERC20(token).transfer(user, amount);
        if (!success) revert TransferFailed();
    }

    function claim(address token) external {
        require(!balances[msg.sender][token].hasClaimed, "Already claimed.");
        if (token == address(0x0) || !allowedTokens[token])
            revert InvalidToken();
        if (!balances[msg.sender][token].hasStaked) revert NoStakedToken();
        if (isLockedPeriod(msg.sender, token))
            revert LockedPeriod("The locked period hasn't expired yet.");

        address user = msg.sender;
        balances[user][token].hasClaimed = true;

        bool success = IERC20(token).transfer(
            user,
            calculateReward(user, token)
        );
        if (!success) revert TransferFailed();
    }

    function addStakingToken(address tokenAddress, uint8 tokenAPY)
        public
        onlyOwner
    {
        allowedTokens[tokenAddress] = true;
        APYs[tokenAddress] = tokenAPY;
    }

    function isLockedPeriod(address user, address token)
        internal
        view
        returns (bool)
    {
        return (block.timestamp - balances[user][token].stakingTime <
            LOCKED_PERIOD);
    }

    function calculateReward(address user, address token)
        internal
        view
        returns (uint256)
    {
        return ((((balances[user][token].amount * (APYs[token] / 10**2))) /
            12) * 3);
    }
}
