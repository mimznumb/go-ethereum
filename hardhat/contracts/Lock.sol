// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Lock {
    uint public unlockTime;
    address payable public owner;

    constructor() payable {
        unlockTime = block.timestamp + 1 days;
        owner = payable(msg.sender);
    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "Too soon");
        require(msg.sender == owner, "Not owner");
        owner.transfer(address(this).balance);
    }
}
