// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

/**
 * @title FuzzingTests
 * @dev Fuzzing tests to ensure fraction calculations work correctly across all possible inputs
 */
contract FuzzingTests is Test {
    FractionCalculator public calculator;

    function setUp() public {
        calculator = new FractionCalculator();
    }

    // ============ Core Fuzzing Tests ============

    /**
     * @dev Fuzz test: Verify divisibility check is correct for all amounts
     */
    function testFuzz_DivisibilityCheck(uint256 amount) public view {
        bool isDivisible = calculator.isDivisibleBy10(amount);
        uint256 remainder = calculator.getRemainderMod10(amount);

        if (isDivisible) {
            assertEq(remainder, 0, "Divisible amounts should have 0 remainder");
            assertEq(amount % 10, 0, "Divisible amounts should have last digit 0");
        } else {
            assertGt(remainder, 0, "Non-divisible amounts should have non-zero remainder");
            assertGt(amount % 10, 0, "Non-divisible amounts should have last digit 1-9");
        }
    }

    /**
     * @dev Fuzz test: Total after split should always equal original amount
     */
    function testFuzz_TotalConservation(uint256 amount) public view {
        // Prevent overflow in calculation
        vm.assume(amount < type(uint256).max / 3);

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        uint256 total = thirty + ten + remaining;

        assertEq(total, amount, "Total after split must equal original amount");
    }

    /**
     * @dev Fuzz test: 30% calculation never exceeds theoretical maximum
     */
    function testFuzz_ThirtyPercentBounds(uint256 amount) public view {
        // Prevent overflow when multiplying by 3
        vm.assume(amount < type(uint256).max / 3);

        (uint256 thirtyPercent,) = calculator.calculate30Percent(amount);

        // 30% should never exceed (amount * 3) / 10
        uint256 maxPossible = (amount * 3) / 10;
        assertLe(thirtyPercent, maxPossible, "30% should not exceed maximum");

        // 30% should be at least (amount * 3) / 10 - 1 (accounting for truncation)
        if (amount >= 10) {
            uint256 minPossible = maxPossible > 0 ? maxPossible : 0;
            assertGe(thirtyPercent, minPossible, "30% should not be less than minimum");
        }
    }

    /**
     * @dev Fuzz test: 10% calculation never exceeds theoretical maximum
     */
    function testFuzz_TenPercentBounds(uint256 amount) public view {
        (uint256 tenPercent,) = calculator.calculate10Percent(amount);

        // 10% should never exceed amount / 10
        uint256 maxPossible = amount / 10;
        assertLe(tenPercent, maxPossible, "10% should not exceed maximum");
    }

    /**
     * @dev Fuzz test: Precision loss is always less than 1 wei per calculation
     */
    function testFuzz_PrecisionLoss(uint256 amount) public view {
        // Prevent overflow
        vm.assume(amount < type(uint256).max / 3);

        (uint256 thirty, uint256 ten,,) = calculator.splitAmount(amount);

        // Calculate theoretical exact values
        uint256 exact30 = (amount * 3) / 10;
        uint256 exact10 = amount / 10;

        // Precision loss per calculation should be less than 1 wei
        uint256 loss30 = exact30 > thirty ? exact30 - thirty : 0;
        uint256 loss10 = exact10 > ten ? exact10 - ten : 0;

        assertLe(loss30, 0, "30% precision loss should be 0 or negligible");
        assertLe(loss10, 0, "10% precision loss should be 0 or negligible");
    }

    // ============ Property-Based Tests ============

    /**
     * @dev Property: Divisible amounts should have perfect splits
     */
    function testFuzz_DivisibleAmountsPerfectSplit(uint256 multiplier) public view {
        vm.assume(multiplier < type(uint256).max / 30); // Prevent overflow for both *10 and *3
        uint256 amount = multiplier * 10; // Always divisible by 10

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        assertEq(thirty, (amount * 3) / 10, "30% should be exact for divisible amounts");
        assertEq(ten, amount / 10, "10% should be exact for divisible amounts");
        assertEq(thirty + ten + remaining, amount, "Total should equal original");
        assertEq(remaining, amount - thirty - ten, "Remaining should be 60%");
    }

    /**
     * @dev Property: Adding 1 wei to divisible amount creates remainder
     */
    function testFuzz_AddingOneWeiCreatesRemainder(uint256 multiplier) public view {
        vm.assume(multiplier < (type(uint256).max - 1) / 10); // Prevent overflow
        uint256 divisibleAmount = multiplier * 10;
        uint256 nonDivisibleAmount = divisibleAmount + 1;

        assertTrue(calculator.isDivisibleBy10(divisibleAmount), "Base amount should be divisible");
        assertFalse(calculator.isDivisibleBy10(nonDivisibleAmount), "Amount + 1 should not be divisible");

        assertEq(calculator.getRemainderMod10(divisibleAmount), 0, "Divisible has 0 remainder");
        assertEq(calculator.getRemainderMod10(nonDivisibleAmount), 1, "Non-divisible has remainder 1");
    }

    /**
     * @dev Property: Amounts with same last digit have same remainder pattern
     */
    function testFuzz_SameLastDigitSamePattern(uint256 base1, uint256 base2) public view {
        vm.assume(base1 < type(uint256).max / 10);
        vm.assume(base2 < type(uint256).max / 10);

        // Create two amounts with same last digit (5)
        uint256 amount1 = base1 * 10 + 5;
        uint256 amount2 = base2 * 10 + 5;

        uint256 remainder1 = calculator.getRemainderMod10(amount1);
        uint256 remainder2 = calculator.getRemainderMod10(amount2);

        assertEq(remainder1, remainder2, "Same last digit should give same remainder");
        assertEq(remainder1, 5, "Remainder should equal last digit");
    }

    // ============ Edge Case Fuzzing ============

    /**
     * @dev Fuzz test: Extremely small amounts (< 10 wei)
     */
    function testFuzz_SmallAmounts(uint8 amount) public view {
        vm.assume(amount < 10 && amount > 0);

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(uint256(amount));

        // For amounts < 10, both 30% and 10% should truncate to 0 or very small values
        assertLe(thirty, uint256(amount), "30% cannot exceed original amount");
        assertLe(ten, uint256(amount), "10% cannot exceed original amount");
        assertEq(thirty + ten + remaining, uint256(amount), "Total must be conserved");

        // Most small amounts will have 30% and 10% as 0
        if (amount < 4) {
            assertEq(thirty, 0, "30% of amounts < 4 should be 0");
        }
        assertEq(ten, 0, "10% of amounts < 10 should be 0");
    }

    /**
     * @dev Fuzz test: Boundary values around powers of 10
     */
    function testFuzz_PowersOfTenBoundaries(uint8 power) public view {
        vm.assume(power > 0 && power < 77); // Exclude 0 and values near uint256 max

        uint256 powerOf10 = 10 ** uint256(power);

        // Test power of 10
        assertTrue(calculator.isDivisibleBy10(powerOf10), "Powers of 10 are divisible");

        // Test power of 10 - 1
        if (powerOf10 > 1) {
            uint256 justBelow = powerOf10 - 1;
            assertFalse(calculator.isDivisibleBy10(justBelow), "Power of 10 - 1 is not divisible");
            assertEq(calculator.getRemainderMod10(justBelow), 9, "Should have remainder 9");
        }

        // Test power of 10 + 1
        if (powerOf10 < type(uint256).max) {
            uint256 justAbove = powerOf10 + 1;
            assertFalse(calculator.isDivisibleBy10(justAbove), "Power of 10 + 1 is not divisible");
            assertEq(calculator.getRemainderMod10(justAbove), 1, "Should have remainder 1");
        }
    }

    /**
     * @dev Fuzz test: Maximum uint256 values
     */
    function testFuzz_MaxValues() public view {
        // Use a value that won't overflow when multiplied by 3
        uint256 maxValue = type(uint256).max / 3;

        // Check divisibility - the last digit determines this
        uint256 lastDigit = maxValue % 10;
        bool isDivisible = (lastDigit == 0);

        assertEq(calculator.isDivisibleBy10(maxValue), isDivisible, "Divisibility check");
        assertEq(calculator.getRemainderMod10(maxValue), lastDigit, "Remainder check");

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(maxValue);
        assertEq(thirty + ten + remaining, maxValue, "Total conservation at max value");
    }

    // ============ Statistical Fuzzing ============

    /**
     * @dev Statistical test: Distribution of remainders
     */
    function testFuzz_RemainderDistribution(uint256 seed) public view {
        // Generate 10 pseudo-random amounts using the seed
        uint256[10] memory amounts;
        uint256[10] memory remainders;

        for (uint256 i = 0; i < 10; i++) {
            amounts[i] = uint256(keccak256(abi.encode(seed, i)));
            remainders[i] = calculator.getRemainderMod10(amounts[i]);

            // Remainder should always be 0-9
            assertLe(remainders[i], 9, "Remainder should be 0-9");
        }

        // Log distribution for analysis
        console2.log("Remainder distribution for seed %d:", seed);
        for (uint256 i = 0; i < 10; i++) {
            console2.log("  Amount %d: remainder = %d", i, remainders[i]);
        }
    }

    /**
     * @dev Fuzz test: Monotonicity - larger amounts should give larger or equal splits
     */
    function testFuzz_Monotonicity(uint256 amount1, uint256 amount2) public view {
        vm.assume(amount1 <= amount2);
        vm.assume(amount2 < type(uint256).max / 3); // Prevent overflow when multiplying by 3

        (uint256 thirty1, uint256 ten1,,) = calculator.splitAmount(amount1);
        (uint256 thirty2, uint256 ten2,,) = calculator.splitAmount(amount2);

        assertLe(thirty1, thirty2, "30% should be monotonic");
        assertLe(ten1, ten2, "10% should be monotonic");
    }

    /**
     * @dev Fuzz test: Commutative property for same percentages
     */
    function testFuzz_PercentageConsistency(uint256 amount) public view {
        vm.assume(amount < type(uint256).max / 10);

        // Calculate 10% three times
        (uint256 ten1,) = calculator.calculate10Percent(amount);
        (uint256 ten2,) = calculator.calculate10Percent(amount);
        (uint256 ten3,) = calculator.calculate10Percent(amount);

        assertEq(ten1, ten2, "10% calculation should be deterministic");
        assertEq(ten2, ten3, "10% calculation should be consistent");

        // Calculate 30% three times
        (uint256 thirty1,) = calculator.calculate30Percent(amount);
        (uint256 thirty2,) = calculator.calculate30Percent(amount);
        (uint256 thirty3,) = calculator.calculate30Percent(amount);

        assertEq(thirty1, thirty2, "30% calculation should be deterministic");
        assertEq(thirty2, thirty3, "30% calculation should be consistent");
    }
}
