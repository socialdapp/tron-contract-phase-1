// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error __NotStore(address sender);
error  __AddressZero();

contract SocialPoints is ERC20, Ownable {
    address public s_storeAddress;

    event PointsIssued(address indexed sender, uint256 indexed points);
    constructor() ERC20("Social Point", "POINT") {
        _mint(msg.sender, 10 * 10**decimals());
    }

    // ---- MODIFIER
    modifier onlyStore() {
        if (msg.sender != s_storeAddress) revert __NotStore(msg.sender);
        _;
    }
    // ---- OWNER
    function setStore(address _store) external onlyOwner {
        if (_store == address(0)) revert  __AddressZero();
        s_storeAddress = _store;
    }
    function issuePoints(address to, uint256 points) external onlyStore {
        _mint(to, points * 10**18);
        emit PointsIssued(to, points);
    }

}
