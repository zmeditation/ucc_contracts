// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param _cap Max amount of wei to be contributed
     */
    constructor (uint256 _cap) {
        require(_cap > 0, "CappedCrowdsale: cap is 0");
        cap = _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual override {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= cap, "CappedCrowdsale: cap exceeded");
    }
}
