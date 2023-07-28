// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { OracleHelper } from "./OracleHelper.sol";

contract OracleHelperTest is Test {
  OracleHelper oracleHelper;
  address sortedOracles = 0xefB84935239dAcdecF7c5bA76d8dE40b077B7b33;
  address CELOUSD = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

  function setUp() public {
    oracleHelper = new OracleHelper(sortedOracles);
  }

  function testDeviation() public {
    (uint256 deviation, uint256 max) = OracleHelper(oracleHelper).deviation(CELOUSD);
    assertTrue(deviation < max);
  }
}
