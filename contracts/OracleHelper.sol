// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from 'forge-std/console.sol';
import {SD59x18, sd, abs, convert, intoUint256} from 'prb-math/SD59x18.sol';

interface ISortedOracles {
    enum MedianRelation {
        Undefined,
        Lesser,
        Greater,
        Equal
    }

    function getRates(
        address token
    )
        external
        view
        returns (address[] memory, uint256[] memory, MedianRelation[] memory);
}

contract OracleHelper {
    address public immutable sortedOracles;

    constructor(address _sortedOracles) {
        sortedOracles = _sortedOracles;
    }

    /**
     * @notice Get the deviation of the median rate of a rate feed from the mean of all rates.
     */
    function deviation(address token) external view returns (uint256, uint256) {
        (
            address[] memory tokens,
            uint256[] memory rates,
            ISortedOracles.MedianRelation[] memory medianRelation
        ) = ISortedOracles(sortedOracles).getRates(token);
        if (rates.length == 0) {
            return (0, 0);
        }
        SD59x18 mean;
        for (uint256 i = 0; i < rates.length; i++) {
            mean = mean.add(sd(int256(rates[i])));
        }
        mean = mean.div(convert(int256(rates.length)));
        SD59x18 maxDiff = sd(0);

        for (uint256 i = 0; i < rates.length; i++) {
            SD59x18 diff = sd(int256(rates[i])).div(mean).sub(convert(1)).abs();
            if (diff.gt(maxDiff)) {
                maxDiff = diff;
            }
        }

        return (intoUint256(maxDiff), 1e18);
    }
}
