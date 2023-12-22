// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is Ownable {
    IERC721Enumerable public nftContract;
    IERC20 public paymentToken;

    uint256 public auctionDuration;
    uint256 public startingPrice;
    uint256 public endTime;

    mapping(uint256 => uint256) public currentBid;

    event BidPlaced(address bidder, uint256 tokenId, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 winningBid);

    modifier onlyValidBid(uint256 tokenId, uint256 bidAmount) {
        require(block.timestamp <= endTime, "Auction has ended");
        require(
            bidAmount > currentBid[tokenId],
            "Bid must be higher than the current bid"
        );
        _;
    }

    constructor(
        IERC721Enumerable _nftContract,
        IERC20 _paymentToken,
        uint256 _auctionDuration,
        uint256 _startingPrice
    ) {
        nftContract = _nftContract;
        paymentToken = _paymentToken;
        auctionDuration = _auctionDuration;
        startingPrice = _startingPrice;
    }

    function startAuction(uint256 tokenId) external onlyOwner {
        require(!nftContract.isLocked(tokenId), "NFT is locked");
        require(
            nftContract.ownerOf(tokenId) == address(this),
            "Contract is not the owner"
        );

        endTime = block.timestamp + auctionDuration;
        currentBid[tokenId] = _startingPrice;
    }

    function placeBid(
        uint256 tokenId,
        uint256 bidAmount
    ) external onlyValidBid(tokenId, bidAmount) {
        paymentToken.transferFrom(msg.sender, address(this), bidAmount);
        currentBid[tokenId] = bidAmount;

        emit BidPlaced(msg.sender, tokenId, bidAmount);
    }

    function endAuction(uint256 tokenId, address _winner) external onlyOwner {
        require(block.timestamp >= endTime, "Auction has not ended yet");

        address winner = _winner;
        uint256 winningBid = currentBid[tokenId];

        // Distribute the NFT and winning bid to the winner
        nftContract.transferFrom(address(this), winner, tokenId);
        paymentToken.transfer(winner, winningBid);

        // Reset auction data
        delete currentBid[tokenId];
        endTime = 0;

        emit AuctionEnded(tokenId, winner, winningBid);
    }
}
