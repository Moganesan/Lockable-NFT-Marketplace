// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    uint256 _nextTokenId;
    address owner;

    constructor(uint256 initialSupply) ERC20("LOCKREW", "L-REW") {
        _mint(msg.sender, initialSupply);
    }
}
