// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 */
contract PrimitiveOverflow {
    uint256 public victim;

    function plusOne(uint8 input)  public returns (uint256) {
        // 
        victim = input + 1;
        return victim;
    }
}