// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

/**
 * @title GasOptimizationTests
 * @dev Tests focused on gas consumption and optimization opportunities
 */
contract GasOptimizationTests is Test {
    FractionCalculator public calculator;

    function setUp() public {
        calculator = new FractionCalculator();
    }

    // ============ Gas Measurement Tests ============

    /**
     * @dev Measure gas for divisibility check
     */
    function test_GasCost_DivisibilityCheck() public view {
        uint256 gasBefore = gasleft();
        calculator.isDivisibleBy10(123456789);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Gas used for isDivisibleBy10: %d", gasUsed);
        assertLt(gasUsed, 10000, "Divisibility check should be cheap");
    }

    /**
     * @dev Measure gas for 30% calculation
     */
    function test_GasCost_Calculate30Percent() public view {
        uint256 gasBefore = gasleft();
        calculator.calculate30Percent(1 ether);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Gas used for calculate30Percent: %d", gasUsed);
        assertLt(gasUsed, 10000, "30% calculation should be cheap");
    }

    /**
     * @dev Measure gas for 10% calculation
     */
    function test_GasCost_Calculate10Percent() public view {
        uint256 gasBefore = gasleft();
        calculator.calculate10Percent(1 ether);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Gas used for calculate10Percent: %d", gasUsed);
        assertLt(gasUsed, 10000, "10% calculation should be cheap");
    }

    /**
     * @dev Measure gas for full split operation
     */
    function test_GasCost_SplitAmount() public view {
        uint256 gasBefore = gasleft();
        calculator.splitAmount(1 ether);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Gas used for splitAmount: %d", gasUsed);
        assertLt(gasUsed, 15000, "Split operation should be reasonably cheap");
    }

    /**
     * @dev Compare gas costs for different amount sizes
     */
    function test_GasScaling_DifferentAmounts() public view {
        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 1 wei;
        amounts[1] = 1000 wei;
        amounts[2] = 1 gwei;
        amounts[3] = 1 ether;
        amounts[4] = 1000 ether;

        console2.log("Gas costs for different amounts:");
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 gasBefore = gasleft();
            calculator.splitAmount(amounts[i]);
            uint256 gasUsed = gasBefore - gasleft();
            console2.log("  Amount %d: %d gas", amounts[i], gasUsed);
        }

        // Gas should be constant regardless of amount size
        // (Since we're just doing arithmetic operations)
    }

    // ============ Optimization Comparison Tests ============

    /**
     * @dev Test inline calculation vs function call overhead
     */
    function test_OptimizationComparison_InlineVsFunction() public {
        uint256 amount = 1 ether;

        // Method 1: Using functions
        uint256 gasBefore1 = gasleft();
        (uint256 thirty1,) = calculator.calculate30Percent(amount);
        (uint256 ten1,) = calculator.calculate10Percent(amount);
        uint256 remaining1 = amount - thirty1 - ten1;
        uint256 gasMethod1 = gasBefore1 - gasleft();

        // Method 2: Inline calculation
        uint256 gasBefore2 = gasleft();
        uint256 thirty2 = (amount * 3) / 10;
        uint256 ten2 = amount / 10;
        uint256 remaining2 = amount - thirty2 - ten2;
        uint256 gasMethod2 = gasBefore2 - gasleft();

        console2.log("Gas comparison:");
        console2.log("  Function calls: %d gas", gasMethod1);
        console2.log("  Inline calculation: %d gas", gasMethod2);
        console2.log("  Overhead: %d gas", gasMethod1 > gasMethod2 ? gasMethod1 - gasMethod2 : 0);

        // Verify same results
        assertEq(thirty1, thirty2, "Results should match");
        assertEq(ten1, ten2, "Results should match");
        assertEq(remaining1, remaining2, "Results should match");
    }

    /**
     * @dev Test different multiplication/division orders
     */
    function test_OptimizationComparison_OperationOrder() public view {
        uint256 amount = 123456789;

        // Method 1: Multiply then divide
        uint256 gasBefore1 = gasleft();
        uint256 result1 = (amount * 3) / 10;
        uint256 gas1 = gasBefore1 - gasleft();

        // Method 2: Divide then multiply (loses precision!)
        uint256 gasBefore2 = gasleft();
        uint256 result2 = (amount / 10) * 3;
        uint256 gas2 = gasBefore2 - gasleft();

        console2.log("Operation order comparison:");
        console2.log("  (amount * 3) / 10: %d gas, result: %d", gas1, result1);
        console2.log("  (amount / 10) * 3: %d gas, result: %d", gas2, result2);

        // Note: Method 2 loses precision but might save gas
        assertGe(result1, result2, "Multiply-first should give equal or better precision");
    }

    /**
     * @dev Test caching vs recalculation
     */
    function test_OptimizationComparison_CachingVsRecalculation() public {
        uint256 amount = 1 ether;

        // Without caching
        uint256 gasBefore1 = gasleft();
        uint256 thirty1 = (amount * 3) / 10;
        uint256 ten1 = amount / 10;
        uint256 remaining1 = amount - (amount * 3) / 10 - amount / 10; // Recalculate
        uint256 gas1 = gasBefore1 - gasleft();

        // With caching
        uint256 gasBefore2 = gasleft();
        uint256 thirty2 = (amount * 3) / 10;
        uint256 ten2 = amount / 10;
        uint256 remaining2 = amount - thirty2 - ten2; // Use cached values
        uint256 gas2 = gasBefore2 - gasleft();

        console2.log("Caching comparison:");
        console2.log("  Without caching: %d gas", gas1);
        console2.log("  With caching: %d gas", gas2);
        console2.log("  Savings: %d gas", gas1 > gas2 ? gas1 - gas2 : 0);

        assertEq(remaining1, remaining2, "Results should match");
    }

    // ============ Batch Operation Tests ============

    /**
     * @dev Test gas cost for batch operations
     */
    function test_BatchOperations_GasScaling() public {
        uint256[] memory amounts = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            amounts[i] = (i + 1) * 1 ether;
        }

        // Single operations
        uint256 totalGasSingle = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 gasBeforeSingle = gasleft();
            calculator.splitAmount(amounts[i]);
            totalGasSingle += gasBeforeSingle - gasleft();
        }

        // Batch operation (simulated)
        uint256 gasBefore = gasleft();
        for (uint256 i = 0; i < amounts.length; i++) {
            calculator.splitAmount(amounts[i]);
        }
        uint256 totalGasBatch = gasBefore - gasleft();

        console2.log("Batch operations:");
        console2.log("  Total gas (individual): %d", totalGasSingle);
        console2.log("  Total gas (batch): %d", totalGasBatch);
        console2.log("  Average per operation: %d", totalGasBatch / amounts.length);
    }

    // ============ Alternative Implementation Tests ============

    /**
     * @dev Test alternative implementation using bit shifting for division by 10
     */
    function test_AlternativeImplementation_BitShifting() public view {
        uint256 amount = 1000;

        // Standard division by 10
        uint256 gasBefore1 = gasleft();
        uint256 result1 = amount / 10;
        uint256 gas1 = gasBefore1 - gasleft();

        // Approximation using bit shifting (not exact!)
        // Note: This is for comparison only, not accurate for 10
        uint256 gasBefore2 = gasleft();
        uint256 result2 = (amount >> 3) + (amount >> 4); // ≈ amount / 8 + amount / 16 ≈ amount / 10.67
        uint256 gas2 = gasBefore2 - gasleft();

        console2.log("Division methods:");
        console2.log("  Standard division: %d gas, result: %d", gas1, result1);
        console2.log("  Bit shifting approx: %d gas, result: %d", gas2, result2);
        console2.log("  Accuracy loss: %d", result1 > result2 ? result1 - result2 : result2 - result1);
    }

    /**
     * @dev Test using modulo vs manual remainder calculation
     */
    function test_OptimizationComparison_ModuloVsManual() public view {
        uint256 amount = 123456789;

        // Using modulo operator
        uint256 gasBefore1 = gasleft();
        uint256 remainder1 = amount % 10;
        uint256 gas1 = gasBefore1 - gasleft();

        // Manual calculation
        uint256 gasBefore2 = gasleft();
        uint256 quotient = amount / 10;
        uint256 remainder2 = amount - (quotient * 10);
        uint256 gas2 = gasBefore2 - gasleft();

        console2.log("Remainder calculation:");
        console2.log("  Modulo operator: %d gas", gas1);
        console2.log("  Manual calculation: %d gas", gas2);

        assertEq(remainder1, remainder2, "Results should match");
    }

    /**
     * @dev Benchmark repeated operations for gas estimation
     */
    function test_Benchmark_RepeatedOperations() public {
        uint256 iterations = 100;
        uint256 amount = 1 ether;

        uint256 gasBefore = gasleft();
        for (uint256 i = 0; i < iterations; i++) {
            calculator.splitAmount(amount + i);
        }
        uint256 totalGas = gasBefore - gasleft();

        console2.log("Benchmark results:");
        console2.log("  Iterations: %d", iterations);
        console2.log("  Total gas: %d", totalGas);
        console2.log("  Average gas per operation: %d", totalGas / iterations);
    }
}
