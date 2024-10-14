// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VestingContract is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    // Vesting schedule struct for each recipient
    struct Vesting {
        uint256 start; // start time of vesting
        uint256 total; // total amount of vested tokens
        uint256 released; // amount of tokens already released
        uint256[] times; // timestamps of release periods
        uint256[] percents; // corresponding percentages to release at each timestamp
        bool active; // flag to track if the participant is still active
    }

    IERC20 public token; // Token to be vested
    mapping(address => Vesting) public vestings; // Mapping of addresses to vesting schedules
    
    event TokensReleased(address recipient, uint256 amount);
    event VestingAdded(address recipient, uint256 total);
    event VestingTransferred(address oldRecipient, address newRecipient);
    event EmergencyStop();

    // Replaces constructor
    /// @dev Initializes the vesting contract with the token
    function initialize(IERC20 _token) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        token = _token;
    }

    /// @dev Admin can set a custom vesting schedule for a recipient
    /// @param recipient Address of the beneficiary
    /// @param start Start time of the vesting schedule
    /// @param times Timestamps of when tokens will be released
    /// @param percents Percentages of the total amount to release at each timestamp
    /// @param amount The total amount to be vested for the recipient
    function setVesting(
        address recipient,
        uint256 start,
        uint256[] memory times,
        uint256[] memory percents,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        require(times.length == percents.length, "Times and percents must match");

        uint256 totalPercent = 0;
        for (uint256 i = 0; i < percents.length; i++) {
            totalPercent += percents[i];
        }
        require(totalPercent == 100, "Total percent must equal 100%");

        vestings[recipient] = Vesting({
            start: start,
            total: amount,
            released: 0,
            times: times,
            percents: percents,
            active: true
        });
        emit VestingAdded(recipient, amount);
    }

    /// @dev Function to release vested tokens for a user
    function releaseTokens() external nonReentrant whenNotPaused {
        Vesting storage vesting = vestings[msg.sender];
        require(block.timestamp >= vesting.start, "Vesting not started");

        uint256 releasable = _calcReleasable(vesting);

        require(releasable > 0, "No tokens available for release");

        uint256 balance = token.balanceOf(address(this));
        require(balance >= releasable, "Insufficient contract balance");

        vesting.released += releasable;
        token.transfer(msg.sender, releasable);

        emit TokensReleased(msg.sender, releasable);
    }

    /// @dev Optimized function to calculate the releasable amount based on the schedule
    /// @param vesting The vesting schedule for the recipient
    /// @return The total releasable amount of tokens
    function _calcReleasable(Vesting memory vesting) internal view returns (uint256) {
        if (!vesting.active) return 0;

        if (block.timestamp >= vesting.times[vesting.times.length - 1]) {
            return vesting.total - vesting.released;
        }

        uint256 totalPercent = 0;
        for (uint256 i = 0; i < vesting.times.length; i++) {
            if (block.timestamp >= vesting.times[i]) {
                totalPercent += vesting.percents[i];
            }
        }

        uint256 releasable = (vesting.total * totalPercent) / 100;
        return releasable - vesting.released;
    }

    /// @dev Function to transfer vesting schedule from one address to another
    /// @param oldRecipient The current address of the vesting schedule
    /// @param newRecipient The new address to transfer the vesting schedule to
    function transferVesting(address oldRecipient, address newRecipient) external onlyOwner whenNotPaused {
        require(vestings[oldRecipient].total > 0, "No vesting schedule exists for the original address");
        require(vestings[newRecipient].total == 0, "Recipient already has a vesting schedule");

        vestings[newRecipient] = vestings[oldRecipient];
        delete vestings[oldRecipient];

        emit VestingTransferred(oldRecipient, newRecipient);
    }

    /// @dev Admin can stop payments for a participant by marking them inactive
    /// @param recipient The address of the participant
    function stopPayments(address recipient) external onlyOwner whenNotPaused {
        require(vestings[recipient].total > 0, "No vesting schedule exists");
        vestings[recipient].active = false;
    }

    /// @dev Admin can deposit tokens into the contract for vesting
    /// @param amount Amount of tokens to deposit
    function depositTokens(uint256 amount) external onlyOwner whenNotPaused {
        token.transferFrom(msg.sender, address(this), amount);
    }

    /// @dev View vested balance and release times for a recipient
    /// @param recipient The address of the recipient
    /// @return The releasable tokens and the array of release times
    function viewAssets(address recipient) external view returns (uint256, uint256[] memory) {
        Vesting memory vesting = vestings[recipient];
        uint256 releasable = _calcReleasable(vesting);
        return (releasable, vesting.times);
    }

    /// @dev Emergency function to pause all token releases
    function emergencyStop() external onlyOwner {
        _pause();
        emit EmergencyStop();
    }

    /// @dev Function to resume token release after emergency stop
    function resume() external onlyOwner {
        _unpause();
    }
}