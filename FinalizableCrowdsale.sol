// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./TimedCrowdsale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FinalizableCrowdsale
 * @dev Extension of TimedCrowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
abstract contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
    using SafeMath for uint256;

    bool public finalized;

    event CrowdsaleFinalized();

    constructor () {
        finalized = false;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() onlyOwner public {
        require(!finalized, "FinalizableCrowdsale: already finalized");
        require(hasClosed(), "FinalizableCrowdsale: not closed");

        finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super._finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function _finalization() internal virtual  {
        // solhint-disable-previous-line no-empty-blocks
    }
}
