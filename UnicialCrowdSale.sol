// contracts/UnicialCrowdsale.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./CappedCrowdSale.sol";
import "./WhitelistedCrowdsale.sol";
import "./FinalizableCrowdsale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";


/**
 * @title UnicialCrowdsale
 * @dev This is an example of a fully fledged crowdsale.
 */
contract UnicialCrowdsale is CappedCrowdsale, WhitelistedCrowdsale, FinalizableCrowdsale {
  using SafeMath for uint256;

  uint256 public constant TOTAL_SHARE = 100;
  uint256 public constant CROWDSALE_SHARE = 40;
  uint256 public constant FOUNDATION_SHARE = 60;

  // Track investor contributions
  uint256 public investorMinCap = 1000000000000000000; // 1 znx
  uint256 public investorHardCap = 100000000000000000000000; // 1000000 znx
  mapping(address => uint256) public contributions;

  // events
  event StageChange(uint256 turningPoint);
  event WalletChange(address wallet);
  event PreferentialRateChange(address indexed buyer, uint256 rate);


  // Crowdsale Stages
  enum CrowdsaleStage { PreICO, ICO }
  CrowdsaleStage public stage = CrowdsaleStage.PreICO;

  // pre ico rate that pre ico customers can buy
  uint256 public preferentialRate;

  // customize the rate for each whitelisted buyer
  mapping (address => uint256) public buyerRate;

  // initial rate at which tokens are offered
  uint256 public initialRate;

  // end rate at which tokens are offered
  uint256 public endRate;

  // turning point from pre ico to ico
  uint256 public turningPoint;

  constructor(
        uint256 _initialRate,
        uint256 _endRate,
        uint256 _preferentialRate,
        address payable _wallet,
        ERC20PresetMinterPauser _token,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime
    ) Crowdsale(_preferentialRate, _wallet, _token)
      CappedCrowdsale(_cap)
      TimedCrowdsale(_openingTime, _closingTime)
     {
        require(_initialRate > 0);
        require(_endRate > 0);
        require(_preferentialRate > 0);

        initialRate = _initialRate;
        endRate = _endRate;
        preferentialRate = _preferentialRate;
     }


  /**
  * @dev Set individual buyer's rate before ICO
  */
  function setBuyerRate(address _buyer, uint256 _rate) onlyOwner public {
      require(_rate != 0);
      require(isWhitelisted(_buyer));
      require(block.timestamp < openingTime);

      buyerRate[_buyer] = _rate;

      emit PreferentialRateChange(_buyer, _rate);
  }

  /**
    * @dev Get current rate
    * @return Returns current rate
    */
  function getRate() public view returns (uint256) {

    // some early buyers are offered a discount on the crowdsale price
    if (buyerRate[_msgSender()] != 0) {
        return buyerRate[_msgSender()];
    }

    // in case of PreICO stage should return preferential ICO
    if (stage == CrowdsaleStage.PreICO) {
      return preferentialRate;
    } 
    
    // otherwise compute the price for the auction
    uint256 elapsed = block.timestamp - turningPoint;
    uint256 deltaRate = initialRate - endRate;
    uint256 deltaTime = closingTime - turningPoint;

    return initialRate.sub(deltaRate.mul(elapsed).div(deltaTime));
  }

  /**
    * @dev Override to extend the way in which ether is converted to tokens.
    ** Change the token rate as time elaspes
    * @param weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
  function _getTokenAmount(uint256 weiAmount) internal override view returns (uint256) {
      return weiAmount.mul(getRate());
  }

  /**
  * @dev Returns the amount contributed so far by a sepecific user.
  * @param _beneficiary Address of contributor
  * @return User contribution so far
  */
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }     

  /**
  * @dev Allows admin to update the crowdsale stage
  */
  function setIcoTurningPoint() public onlyOwner {
      require(stage == CrowdsaleStage.PreICO, "UnicialCrowdsale: Already in ICO stage.");
      require(openingTime < block.timestamp && block.timestamp < closingTime, "UnicialCrowdsale: Ico turning point must be between openingTime and closingTime.");
      
      stage = CrowdsaleStage.ICO;
      turningPoint = block.timestamp;

    emit StageChange(turningPoint);
  }

   /**
  * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
  * @param _beneficiary Token purchaser
  * @param _weiAmount Amount of wei contributed
  */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal override(Crowdsale, CappedCrowdsale) onlyWhileOpen {
    CappedCrowdsale._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    contributions[_beneficiary] = _newContribution;
  }

  /**
  * @dev Make the crowdsale to be mintable crowdsale.
  * @param beneficiary Address performing the token purchase
  * @param tokenAmount Number of tokens to be emitted
  */
  function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
      token.mint(beneficiary, tokenAmount);
  }

  /**
  * @dev Set fund wallet.
  * @param _wallet Address performing the token purchase
  */
  function setWallet(address _wallet) onlyOwner public {
      require(_wallet != address(0));
      wallet = payable(_wallet);
      // continuousSale.setWallet(_wallet);
      emit WalletChange(_wallet);
  }

  /**
   * @dev enables token transfers, called when owner calls finalize()
  */
  function _finalization() internal override {
    uint256 totalSupply = token.totalSupply();
    uint256 finalSupply = TOTAL_SHARE.mul(totalSupply).div(CROWDSALE_SHARE);

    // emit tokens for the foundation
    token.mint(wallet, FOUNDATION_SHARE.mul(finalSupply).div(TOTAL_SHARE));

    super._finalization();
  }
}