// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Fixidity/FixidityLib.sol";

interface ISortedOracles {
  using FixidityLib for int256;

  enum MedianRelation {
    Undefined,
    Lesser,
    Greater,
    Equal
  }

  function getRates(address token)
    external
    view
    returns (
      address[] memory,
      uint256[] memory,
      MedianRelation[] memory
    );
}

contract OracleHelper {
  address public immutable sortedOracles;
  
  constructor(address _sortedOracles) { 
    sortedOracles = _sortedOracles;
  }

  function deviation(address token) external view returns (uint256, uint256) {
    (address[] memory tokens, uint256[] memory rates, ISortedOracles.MedianRelation[] memory medianRelation) = ISortedOracles(sortedOracles).getRates(token);
    if (rates.length == 0) {
      return (0, 0);
    }
    int256 _mean;
    for (uint256 i = 0; i < rates.length; i++) {
      mean += int256(rates[i]);
    }
    mean = mean.div(rate.length);
    int256 maxDiff = 0;

    for (uint256 i = 0; i < rates.length; i++) {
      int256 diff = FixidityLib.abs(rates[i].div(mean) - FixidityLib.fixed1());
      if (diff > maxDiff) {
        maxDiff = diff;
      }
    }

    return (maxDiff, FixidityLib.fixed1());
  }
}
