// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeUSD is ERC20 {
    constructor() ERC20("Testnet USD", "TUSD") {
        _mint(msg.sender, 10 * 10**decimals());
    }

    // goes public
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// s_tokenPayment.approve(spender // CONTRACT PROFILE, amount);



// subscription,
// update store payout
// social 


//
//
//
//
