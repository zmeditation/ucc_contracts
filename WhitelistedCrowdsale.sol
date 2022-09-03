// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Crowdsale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WhitelistedCrowdsale
 * @dev Extension of Crowsdale where an owner can whitelist addresses
 * which can buy in crowdsale before it opens to the public 
 */
abstract contract WhitelistedCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    // list of addresses that can purchase before crowdsale opens
    mapping (address => bool) public whitelist;

    function addToWhitelist(address _buyer) public onlyOwner {
        require(_buyer != address(0));
        whitelist[_buyer] = true; 
    }

    // @return true if _buyer is whitelisted
    function isWhitelisted(address _buyer) public view returns (bool) {
        return whitelist[_buyer];
    }
}
