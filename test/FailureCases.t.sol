// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

/**
 * @title FailureCasesTest
 * @dev Test cases that demonstrate when fraction calculations fail (produce remainders)
 */
contract FailureCasesTest is Test {
    FractionCalculator public calculator;

    function setUp() public {
        calculator = new FractionCalculator();
    }

    // ============ Tests that SHOULD FAIL (amounts with remainders) ============

    function test_Fail_1Wei_HasRemainder() public view {
        uint256 amount = 1; // 1 wei - smallest unit

        // This amount is NOT divisible by 10
        assertFalse(calculator.isDivisibleBy10(amount), "1 wei should NOT be divisible by 10");

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        // 30% of 1 = 0.3 -> truncated to 0
        // 10% of 1 = 0.1 -> truncated to 0
        assertEq(thirty, 0, "30% of 1 wei should be 0 (lost 0.3 wei)");
        assertEq(ten, 0, "10% of 1 wei should be 0 (lost 0.1 wei)");
        assertEq(remaining, 1, "All 1 wei goes to remaining");

        // Verify that we lost precision
        uint256 totalAfterSplit = thirty + ten + remaining;
        assertEq(totalAfterSplit, amount, "Total should still equal original (but distribution is wrong)");

        console2.log("FAILURE CASE: 1 wei");
        console2.log("  Expected 30%%: 0.3 wei -> Got: 0 wei (LOST 0.3 wei)");
        console2.log("  Expected 10%%: 0.1 wei -> Got: 0 wei (LOST 0.1 wei)");
    }

    function test_Fail_7Wei_HasRemainder() public view {
        uint256 amount = 7; // 7 wei

        assertFalse(calculator.isDivisibleBy10(amount), "7 wei should NOT be divisible by 10");

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        // 30% of 7 = 2.1 -> truncated to 2
        // 10% of 7 = 0.7 -> truncated to 0
        assertEq(thirty, 2, "30% of 7 wei = 2.1 -> 2 (lost 0.1 wei)");
        assertEq(ten, 0, "10% of 7 wei = 0.7 -> 0 (lost 0.7 wei)");
        assertEq(remaining, 5, "Remaining should be 5 wei");

        console2.log("FAILURE CASE: 7 wei");
        console2.log("  Expected 30%%: 2.1 wei -> Got: 2 wei (LOST 0.1 wei)");
        console2.log("  Expected 10%%: 0.7 wei -> Got: 0 wei (LOST 0.7 wei)");
        console2.log("  Total precision lost: 0.8 wei");
    }

    function test_Fail_123Wei_HasRemainder() public view {
        uint256 amount = 123; // 123 wei

        assertFalse(calculator.isDivisibleBy10(amount), "123 wei should NOT be divisible by 10");
        assertEq(calculator.getRemainderMod10(amount), 3, "123 mod 10 = 3");

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        // 30% of 123 = 36.9 -> truncated to 36
        // 10% of 123 = 12.3 -> truncated to 12
        assertEq(thirty, 36, "30% of 123 wei = 36.9 -> 36 (lost 0.9 wei)");
        assertEq(ten, 12, "10% of 123 wei = 12.3 -> 12 (lost 0.3 wei)");
        assertEq(remaining, 75, "Remaining should be 75 wei");

        console2.log("FAILURE CASE: 123 wei");
        console2.log("  Expected 30%%: 36.9 wei -> Got: 36 wei (LOST 0.9 wei)");
        console2.log("  Expected 10%%: 12.3 wei -> Got: 12 wei (LOST 0.3 wei)");
        console2.log("  Total precision lost: 1.2 wei");
    }

    function test_Fail_LargeAmountPlusOddWei() public view {
        uint256 amount = 1 ether + 7; // 1 ETH + 7 wei

        assertFalse(calculator.isDivisibleBy10(amount), "1 ETH + 7 wei should NOT be divisible by 10");

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        // The 7 wei at the end causes precision loss
        uint256 expectedThirty = 300000000000000002; // 0.3 ETH + 2.1 wei -> loses 0.1 wei
        uint256 expectedTen = 100000000000000000; // 0.1 ETH + 0.7 wei -> loses 0.7 wei

        assertEq(thirty, expectedThirty, "30% calculation loses precision");
        assertEq(ten, expectedTen, "10% calculation loses precision");

        console2.log("FAILURE CASE: 1 ETH + 7 wei");
        console2.log("  Total: %d wei", amount);
        console2.log("  30%% loses precision due to the 7 wei remainder");
        console2.log("  10%% loses precision due to the 7 wei remainder");
    }

    // ============ Demonstrating the pattern of failures ============

    function test_FailurePattern_OnlyLastDigitMatters() public view {
        console2.log("\n=== FAILURE PATTERN: Only the last digit of wei matters ===\n");

        uint256[] memory amounts = new uint256[](9);
        // All these amounts end in 1-9, so they ALL fail
        amounts[0] = 1; // ends in 1
        amounts[1] = 12; // ends in 2
        amounts[2] = 123; // ends in 3
        amounts[3] = 1234; // ends in 4
        amounts[4] = 12345; // ends in 5
        amounts[5] = 123456; // ends in 6
        amounts[6] = 1234567; // ends in 7
        amounts[7] = 12345678; // ends in 8
        amounts[8] = 123456789; // ends in 9

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 lastDigit = amount % 10;
            (uint256 thirty, uint256 ten,,) = calculator.splitAmount(amount);

            // Calculate expected values with decimals
            uint256 expectedThirtyWhole = (amount * 3) / 10;
            uint256 expectedThirtyRemainder = (amount * 3) % 10;
            uint256 expectedTenWhole = amount / 10;
            uint256 expectedTenRemainder = amount % 10;

            console2.log("Amount: %d wei (last digit: %d)", amount, lastDigit);
            console2.log("  Divisible by 10: %s", divisible ? "YES" : "NO (FAILS!)");
            console2.log("  30%%: %d wei (loses 0.%d wei)", thirty, expectedThirtyRemainder);
            console2.log("  10%%: %d wei (loses 0.%d wei)", ten, expectedTenRemainder);

            // All of these should NOT be divisible by 10
            assertFalse(divisible, "Amount ending in 1-9 should NOT be divisible by 10");
        }
    }

    function test_ComparisonTable_SuccessVsFailure() public view {
        console2.log("\n=== SUCCESS vs FAILURE Comparison ===\n");
        console2.log("SUCCESS CASES (divisible by 10):");
        console2.log("  10 wei:  30%% = 3 wei (exact),  10%% = 1 wei (exact)");
        console2.log("  100 wei: 30%% = 30 wei (exact), 10%% = 10 wei (exact)");
        console2.log("  1000 wei: 30%% = 300 wei (exact), 10%% = 100 wei (exact)");
        console2.log("");
        console2.log("FAILURE CASES (NOT divisible by 10):");
        console2.log("  11 wei:  30%% = 3 wei (loses 0.3), 10%% = 1 wei (loses 0.1)");
        console2.log("  101 wei: 30%% = 30 wei (loses 0.3), 10%% = 10 wei (loses 0.1)");
        console2.log("  1001 wei: 30%% = 300 wei (loses 0.3), 10%% = 100 wei (loses 0.1)");
        console2.log("");
        console2.log("PATTERN: Adding just 1 wei to any 'success' amount makes it fail!");
    }

    function test_RealWorldFailureScenario() public view {
        console2.log("\n=== REAL WORLD FAILURE SCENARIO ===\n");

        // Simulate a user sending a "weird" amount
        uint256 userAmount = 0.123456789123456789 ether; // Odd amount in ETH

        console2.log("User sends: 0.123456789123456789 ETH");
        console2.log("In wei: %d", userAmount);
        console2.log("Last digit: %d (NOT 0, so will have remainder!)", userAmount % 10);

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(userAmount);

        console2.log("Distribution:");
        console2.log("  30%%: %d wei", thirty);
        console2.log("  10%%: %d wei", ten);
        console2.log("  Remaining: %d wei", remaining);

        // Check if any wei was lost due to truncation
        uint256 perfectThirty = userAmount * 30 / 100;
        uint256 perfectTen = userAmount * 10 / 100;

        console2.log("Perfect calculation would be:");
        console2.log("  30%%: %d.%d wei", perfectThirty, (userAmount * 30) % 100);
        console2.log("  10%%: %d.%d wei", perfectTen, (userAmount * 10) % 100);

        // This amount should NOT be divisible by 10
        assertFalse(calculator.isDivisibleBy10(userAmount), "Odd ETH amount should not be divisible by 10");
    }

    function test_CriticalFailure_SmallAmounts() public view {
        console2.log("\n=== CRITICAL: Small amounts lose ALL value ===\n");

        // These amounts are so small that 30% and 10% both round to 0
        uint256[] memory criticalAmounts = new uint256[](3);
        criticalAmounts[0] = 1; // 1 wei
        criticalAmounts[1] = 2; // 2 wei
        criticalAmounts[2] = 3; // 3 wei

        for (uint256 i = 0; i < criticalAmounts.length; i++) {
            uint256 amount = criticalAmounts[i];
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

            console2.log("%d wei:", amount);
            console2.log("  30%% = %d (should be 0.%d)", thirty, (amount * 3) % 10);
            console2.log("  10%% = %d (should be 0.%d)", ten, amount % 10);
            console2.log("  Remaining = %d", remaining);
            console2.log("  CRITICAL: Receivers get NOTHING from fee split!");
            console2.log("");

            // Both 30% and 10% should be 0 for these small amounts
            assertEq(thirty, 0, "30% of small amount truncates to 0");
            assertEq(ten, 0, "10% of small amount truncates to 0");
            assertEq(remaining, amount, "All wei goes to remaining");
        }
    }
}
