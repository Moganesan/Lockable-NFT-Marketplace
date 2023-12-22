// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILockableNFT {
    function lock(uint256 tokenId, address locker, uint256 deadline) external;

    function unlock(uint256 tokenId) external;
}

contract LockableNFT is ERC721Enumerable, ILockableNFT {
    mapping(uint256 => address) private lockers;
    mapping(uint256 => uint256) private deadlines;

    IERC20 public RewardTokenContract;
    uint256 _nextTokenId;

    constructor(
        address _rewardTokenContractAddress
    ) ERC721("LockableNFT", "L-NFT") {
        RewardTokenContract = IERC20(_rewardTokenContractAddress);
    }

    function mint(address to) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        return tokenId;
    }

    function lock(
        uint256 tokenId,
        address unlocker,
        uint256 duration
    ) external override {
        require(duration <= block.timestamp, "Deadline Expired");
        require(tokenExists(tokenId), "Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender ||
                getApproved(tokenId) == msg.sender,
            "Not authorized"
        );
        require(lockers[tokenId] == address(0), "Token is already locked");

        lockers[tokenId] = unlocker;
        uint256 deadline = block.timestamp + duration * 1 minutes;
        deadlines[tokenId] = deadline;

        emit Locked(tokenId, unlocker);
    }

    function unlock(uint256 tokenId) external override {
        require(lockers[tokenId] != address(0), "Token is not locked");
        require(deadlines[tokenId] < block.timestamp, "Token Deadline Not End");
        require(msg.sender == lockers[tokenId], "Not authorized to unlock");
        address owner = ownerOf(tokenId);

        uint256 timeDifference = (block.timestamp - deadlines[tokenId]) / 60;

        uint256 reward = calculateReward(timeDifference);

        require(
            RewardTokenContract.balanceOf(address(this)) >= reward,
            "Insufficient balance to distribute the rewards."
        );
        RewardTokenContract.approve(address(this), reward);
        RewardTokenContract.transferFrom(address(this), owner, reward);

        delete lockers[tokenId];
        delete deadlines[tokenId];

        emit Unlocked(tokenId);
    }

    function isLocked(uint256 tokenId) {
        return lockers[tokenId] != address(0);
    }

    function getMyRewardBalance(uint256 tokenId) public view returns (uint256) {
        uint256 timeDifference = block.timestamp - deadlines[tokenId];
        return calculateReward(timeDifference);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            lockers[tokenId] == address(0),
            "Token is locked, cannot transfer"
        );
        super.transferFrom(from, to, tokenId);
    }

    function getLocker(uint256 tokenId) public view returns (address) {
        return lockers[tokenId];
    }

    event Locked(uint256 indexed tokenId, address indexed locker);
    event Unlocked(uint256 indexed tokenId);

    function tokenExists(uint256 tokenId) public view returns (bool) {
        // Check if the tokenId is within the total supply range
        return tokenId < totalSupply();
    }

    function calculateReward(
        uint256 timeDifference
    ) internal pure returns (uint256) {
        // Customize this formula based on your reward distribution model
        // For simplicity, we use a linear relationship between time and reward
        uint256 rate = 1 wei; // 1 gwei per second
        return timeDifference * rate;
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Check if the token with the given tokenId exists
    function tokenExists(uint256 tokenId) public view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }
}
