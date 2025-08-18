// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

/**
 * @title EdgeCaseTests
 * @dev Comprehensive edge case testing for fraction calculations
 */
contract EdgeCaseTests is Test {
    FractionCalculator public calculator;

    function setUp() public {
        calculator = new FractionCalculator();
    }

    // ============ Zero Value Tests ============

    /**
     * @dev Test with zero amount
     */
    function test_EdgeCase_ZeroAmount() public view {
        uint256 amount = 0;

        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

        assertEq(thirty, 0, "30% of 0 should be 0");
        assertEq(ten, 0, "10% of 0 should be 0");
        assertEq(remaining, 0, "Remaining of 0 should be 0");

        assertTrue(calculator.isDivisibleBy10(0), "0 is divisible by 10");
        assertEq(calculator.getRemainderMod10(0), 0, "0 has remainder 0");
    }

    // ============ Maximum Value Tests ============

    /**
     * @dev Test with maximum uint256 value
     */
    function test_EdgeCase_MaxUint256() public view {
        uint256 maxAmount = type(uint256).max;

        console2.log("Testing max uint256: %d", maxAmount);

        // This should not overflow since we're dividing
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(maxAmount);

        // Verify no overflow occurred
        assertLe(thirty, maxAmount, "30% should not exceed max");
        assertLe(ten, maxAmount, "10% should not exceed max");
        assertLe(remaining, maxAmount, "Remaining should not exceed max");
        assertEq(thirty + ten + remaining, maxAmount, "Total should equal max");

        // Max uint256 ends in 5, so not divisible by 10
        assertFalse(calculator.isDivisibleBy10(maxAmount), "Max uint256 not divisible by 10");
    }

    /**
     * @dev Test values that might cause overflow in intermediate calculations
     */
    function test_EdgeCase_NearOverflowValues() public view {
        // This value * 3 would overflow if not handled carefully
        uint256 dangerousAmount = type(uint256).max / 3 + 1;

        // This should handle overflow correctly by dividing after multiplication
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(dangerousAmount);

        assertEq(thirty + ten + remaining, dangerousAmount, "Total should be preserved");
        console2.log("Near-overflow amount handled correctly");
    }

    // ============ Special Pattern Tests ============

    /**
     * @dev Test repeating pattern numbers
     */
    function test_EdgeCase_RepeatingPatterns() public view {
        uint256[] memory patterns = new uint256[](5);
        patterns[0] = 111111111111111111; // All 1s
        patterns[1] = 222222222222222222; // All 2s
        patterns[2] = 555555555555555555; // All 5s
        patterns[3] = 999999999999999999; // All 9s
        patterns[4] = 101010101010101010; // Alternating

        console2.log("Testing repeating patterns:");
        for (uint256 i = 0; i < patterns.length; i++) {
            uint256 amount = patterns[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 lastDigit = amount % 10;

            console2.log("Pattern: %s", divisible ? "divisible" : "not divisible");

            // Only patterns ending in 0 are divisible
            if (lastDigit == 0) {
                assertTrue(divisible, "Should be divisible");
            } else {
                assertFalse(divisible, "Should not be divisible");
            }
        }
    }

    /**
     * @dev Test prime numbers
     */
    function test_EdgeCase_PrimeNumbers() public view {
        uint256[] memory primes = new uint256[](10);
        primes[0] = 2;
        primes[1] = 3;
        primes[2] = 5;
        primes[3] = 7;
        primes[4] = 11;
        primes[5] = 13;
        primes[6] = 17;
        primes[7] = 19;
        primes[8] = 23;
        primes[9] = 29;

        console2.log("Testing prime numbers:");
        for (uint256 i = 0; i < primes.length; i++) {
            uint256 prime = primes[i];
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(prime);

            // All these primes are not divisible by 10
            assertFalse(calculator.isDivisibleBy10(prime), "Prime should not be divisible by 10");
            assertEq(thirty + ten + remaining, prime, "Total should equal prime");
        }
    }

    // ============ Boundary Tests ============

    /**
     * @dev Test boundaries where truncation changes
     */
    function test_EdgeCase_TruncationBoundaries() public view {
        console2.log("Testing truncation boundaries:");

        // Test where 30% truncation changes
        for (uint256 i = 0; i < 10; i++) {
            uint256 amount = i;
            (uint256 thirty,) = calculator.calculate30Percent(amount);
            uint256 expected = (amount * 3) / 10;

            assertEq(thirty, expected, "30% calculation should match");
        }

        // Find the smallest amount where 30% is non-zero
        uint256 smallestNonZero30 = 4; // 30% of 4 = 1.2 -> 1
        (uint256 result30,) = calculator.calculate30Percent(smallestNonZero30);
        assertEq(result30, 1, "30% of 4 should be 1");

        // Find the smallest amount where 10% is non-zero
        uint256 smallestNonZero10 = 10; // 10% of 10 = 1
        (uint256 result10,) = calculator.calculate10Percent(smallestNonZero10);
        assertEq(result10, 1, "10% of 10 should be 1");
    }

    /**
     * @dev Test consecutive values around important boundaries
     */
    function test_EdgeCase_ConsecutiveValues() public view {
        uint256[] memory boundaries = new uint256[](3);
        boundaries[0] = 10; // Where 10% becomes 1
        boundaries[1] = 100; // Where 10% becomes 10
        boundaries[2] = 1000; // Where 10% becomes 100

        for (uint256 i = 0; i < boundaries.length; i++) {
            uint256 boundary = boundaries[i];
            console2.log("Testing around boundary %d:", boundary);

            for (uint256 offset = 0; offset < 3; offset++) {
                uint256 amount = boundary - 1 + offset;
                (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

                assertEq(thirty + ten + remaining, amount, "Total should match");
            }
        }
    }

    // ============ Special Wei Values ============

    /**
     * @dev Test with specific wei values that have caused issues in production
     */
    function test_EdgeCase_ProblematicWeiValues() public view {
        uint256[] memory problematic = new uint256[](7);
        problematic[0] = 3; // Minimal value with truncation issues
        problematic[1] = 33; // Double digit with remainder 3
        problematic[2] = 333; // Triple digit with remainder 3
        problematic[3] = 3333; // Repeating 3s
        problematic[4] = 9999; // Maximum 4-digit, remainder 9
        problematic[5] = 11111; // Repeating 1s
        problematic[6] = 777777; // Lucky number pattern

        console2.log("Testing problematic wei values:");
        for (uint256 i = 0; i < problematic.length; i++) {
            uint256 amount = problematic[i];
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

            assertEq(thirty + ten + remaining, amount, "Total preserved");
        }
    }

    // ============ Symmetry and Pattern Tests ============

    /**
     * @dev Test palindromic numbers
     */
    function test_EdgeCase_PalindromicNumbers() public view {
        uint256[] memory palindromes = new uint256[](6);
        palindromes[0] = 11;
        palindromes[1] = 121;
        palindromes[2] = 1221;
        palindromes[3] = 12321;
        palindromes[4] = 123321;
        palindromes[5] = 1234321;

        console2.log("Testing palindromic numbers:");
        for (uint256 i = 0; i < palindromes.length; i++) {
            uint256 amount = palindromes[i];
            bool divisible = calculator.isDivisibleBy10(amount);

            // Palindromes ending in 1 are not divisible by 10
            assertFalse(divisible, "Palindromes ending in 1 not divisible by 10");
        }
    }

    /**
     * @dev Test powers of 2
     */
    function test_EdgeCase_PowersOfTwo() public view {
        console2.log("Testing powers of 2:");
        for (uint8 power = 0; power < 20; power++) {
            uint256 amount = 2 ** uint256(power);
            bool divisible = calculator.isDivisibleBy10(amount);

            // Powers of 2 are never divisible by 10 (no factor of 5)
            assertFalse(divisible, "Powers of 2 not divisible by 10");
        }
    }

    /**
     * @dev Test Fibonacci sequence values
     */
    function test_EdgeCase_FibonacciNumbers() public view {
        uint256[] memory fibonacci = new uint256[](10);
        fibonacci[0] = 1;
        fibonacci[1] = 1;

        for (uint256 i = 2; i < 10; i++) {
            fibonacci[i] = fibonacci[i - 1] + fibonacci[i - 2];
        }

        console2.log("Testing Fibonacci numbers:");
        for (uint256 i = 0; i < fibonacci.length; i++) {
            uint256 amount = fibonacci[i];
            bool divisible = calculator.isDivisibleBy10(amount);

            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
            assertEq(thirty + ten + remaining, amount, "Total preserved");
        }
    }

    // ============ Invariant Tests ============

    /**
     * @dev Test that certain invariants always hold
     */
    function test_EdgeCase_Invariants() public view {
        uint256[] memory testAmounts = new uint256[](10);
        testAmounts[0] = 0;
        testAmounts[1] = 1;
        testAmounts[2] = 10;
        testAmounts[3] = 99;
        testAmounts[4] = 100;
        testAmounts[5] = 999;
        testAmounts[6] = 1000;
        testAmounts[7] = 1 ether;
        testAmounts[8] = type(uint128).max;
        testAmounts[9] = type(uint256).max;

        for (uint256 i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);

            // Invariant 1: Sum equals original
            assertEq(thirty + ten + remaining, amount, "Sum invariant");

            // Invariant 2: 30% >= 10% * 3 (with truncation)
            // Avoid overflow by checking if ten is large
            if (ten > 0 && ten < type(uint256).max / 3) {
                assertGe(thirty, (ten * 3) - 1, "30% relationship invariant");
            } else if (ten > 0) {
                // For very large values where ten * 3 would overflow,
                // check the relationship differently
                assertGe(thirty / 3, ten - 1, "30% relationship invariant (scaled)");
            }

            // Invariant 3: Remaining >= 0
            assertGe(remaining, 0, "Remaining non-negative");

            // Invariant 4: Each part <= original
            assertLe(thirty, amount, "30% bounded");
            assertLe(ten, amount, "10% bounded");
            assertLe(remaining, amount, "Remaining bounded");
        }

        console2.log("All invariants hold for edge cases");
    }
}
