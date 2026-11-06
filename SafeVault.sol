// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IVaultToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract SafeVault {
    struct Position {
        uint256 amount;
        uint64 lockedAt;
        uint64 unlockAt;
    }

    error InvalidToken();
    error InvalidAmount();
    error InvalidDuration();
    error PositionExists();
    error NoPosition();
    error StillLocked(uint64 unlockAt);
    error TokenTransferFailed();
    error UnsupportedTokenBehavior();
    error ReentrantCall();

    event TokensLocked(address indexed owner, uint256 amount, uint64 unlockAt);
    event TokensUnlocked(address indexed owner, uint256 amount, uint256 calculatedReward);

    uint256 public constant ANNUAL_REWARD_BPS = 500;
    uint256 public constant MAX_DURATION = 365 days;
    IVaultToken public immutable token;
    mapping(address => Position) private positions;
    bool private entered;

    constructor(IVaultToken token_) {
        if (address(token_).code.length == 0) revert InvalidToken();
        token = token_;
    }

    modifier nonReentrant() {
        if (entered) revert ReentrantCall();
        entered = true;
        _;
        entered = false;
    }

    function lock(uint256 amount, uint256 duration) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        if (duration == 0 || duration > MAX_DURATION) revert InvalidDuration();
        if (positions[msg.sender].amount != 0) revert PositionExists();

        uint64 unlockAt = uint64(block.timestamp + duration);
        positions[msg.sender] = Position(amount, uint64(block.timestamp), unlockAt);
        uint256 beforeBalance = token.balanceOf(address(this));
        if (!token.transferFrom(msg.sender, address(this), amount)) revert TokenTransferFailed();
        if (token.balanceOf(address(this)) != beforeBalance + amount) revert UnsupportedTokenBehavior();

        emit TokensLocked(msg.sender, amount, unlockAt);
    }

    function unlock() external nonReentrant {
        Position memory position = positions[msg.sender];
        if (position.amount == 0) revert NoPosition();
        if (block.timestamp < position.unlockAt) revert StillLocked(position.unlockAt);
        delete positions[msg.sender];

        uint256 beforeBalance = token.balanceOf(msg.sender);
        if (!token.transfer(msg.sender, position.amount)) revert TokenTransferFailed();
        if (token.balanceOf(msg.sender) != beforeBalance + position.amount) revert UnsupportedTokenBehavior();

        emit TokensUnlocked(msg.sender, position.amount, _reward(position));
    }

    function myPosition() external view returns (
        uint256 amount, uint64 lockedAt, uint64 unlockAt, uint256 calculatedReward
    ) {
        Position memory position = positions[msg.sender];
        return (position.amount, position.lockedAt, position.unlockAt, _reward(position));
    }

    function _reward(Position memory position) private view returns (uint256) {
        if (position.amount == 0) return 0;
        uint256 end = block.timestamp < position.unlockAt ? block.timestamp : position.unlockAt;
        uint256 numerator = (end - position.lockedAt) * ANNUAL_REWARD_BPS;
        uint256 denominator = MAX_DURATION * 10_000;
        // Split the amount before multiplying to avoid overflow with large balances.
        return position.amount / denominator * numerator
            + position.amount % denominator * numerator / denominator;
    }
}
