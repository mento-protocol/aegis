// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISortedOracles {
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
    uint256 median = rates[rates.length / 2];
    uint256 sum = 0;
    for (uint256 i = 0; i < rates.length; i++) {
      if (median > rates[i]) {
        sum += median - rates[i];
      } else {
        sum += rates[i] - median;
      }
    }
    return (sum / rates.length, 1e24);
  }
}
