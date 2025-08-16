// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title FractionCalculator
 * @dev Contract to verify fraction calculations and remainder handling in Solidity
 */
contract FractionCalculator {
    /**
     * @dev Calculate 30% (3/10) of the input amount
     * @param amount The input amount in wei
     * @return share The calculated share (30% of amount)
     * @return remainder The remainder after calculation
     */
    function calculate30Percent(uint256 amount) public pure returns (uint256 share, uint256 remainder) {
        share = (amount * 3) / 10;
        remainder = amount - (share * 10 / 3);
    }

    /**
     * @dev Calculate 10% (1/10) of the input amount
     * @param amount The input amount in wei
     * @return share The calculated share (10% of amount)
     * @return remainder The remainder after calculation
     */
    function calculate10Percent(uint256 amount) public pure returns (uint256 share, uint256 remainder) {
        share = amount / 10;
        remainder = amount - (share * 10);
    }

    /**
     * @dev Split amount into 30%, 10%, and remaining portions
     * @param amount The total amount to split
     * @return thirtyPercent 30% of the amount
     * @return tenPercent 10% of the amount
     * @return remaining The remaining amount after deducting 30% and 10%
     * @return totalRemainder The total remainder from calculations
     */
    function splitAmount(uint256 amount)
        public
        pure
        returns (uint256 thirtyPercent, uint256 tenPercent, uint256 remaining, uint256 totalRemainder)
    {
        thirtyPercent = (amount * 3) / 10;
        tenPercent = amount / 10;
        remaining = amount - thirtyPercent - tenPercent;

        // Calculate actual remainder (lost wei due to integer division)
        uint256 expectedTotal = (amount * 3) / 10 + amount / 10;
        uint256 actualTotal = thirtyPercent + tenPercent;

        // If we perfectly calculated 40%, remaining should be 60%
        uint256 perfect40Percent = (amount * 4) / 10;
        totalRemainder = perfect40Percent > actualTotal ? perfect40Percent - actualTotal : 0;
    }

    /**
     * @dev Check if an amount is divisible by 10 (no remainder expected)
     * @param amount The amount to check
     * @return isDivisible True if amount is divisible by 10
     */
    function isDivisibleBy10(uint256 amount) public pure returns (bool isDivisible) {
        isDivisible = (amount % 10 == 0);
    }

    /**
     * @dev Calculate the remainder when dividing by 10
     * @param amount The amount to check
     * @return remainder The remainder when amount is divided by 10
     */
    function getRemainderMod10(uint256 amount) public pure returns (uint256 remainder) {
        remainder = amount % 10;
    }
}
