// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

contract FractionCalculatorTest is Test {
    FractionCalculator public calculator;
    
    function setUp() public {
        calculator = new FractionCalculator();
    }
    
    // ============ Test cases for divisible amounts (no remainder) ============
    
    function test_DivisibleBy10_10Wei() public view {
        uint256 amount = 10; // 10 wei - divisible by 10
        
        // Check if divisible
        assertTrue(calculator.isDivisibleBy10(amount), "10 wei should be divisible by 10");
        
        // Calculate 30%
        (uint256 thirtyPercent,) = calculator.calculate30Percent(amount);
        assertEq(thirtyPercent, 3, "30% of 10 wei should be 3 wei");
        
        // Calculate 10%
        (uint256 tenPercent,) = calculator.calculate10Percent(amount);
        assertEq(tenPercent, 1, "10% of 10 wei should be 1 wei");
        
        // Split amount
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        assertEq(thirty + ten + remaining, amount, "Split should equal original amount");
        
        console2.log("10 wei: 30% = %d wei, 10% = %d wei, remaining = %d wei", thirty, ten, remaining);
    }
    
    function test_DivisibleBy10_100Wei() public view {
        uint256 amount = 100; // 100 wei - divisible by 10
        
        assertTrue(calculator.isDivisibleBy10(amount), "100 wei should be divisible by 10");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        assertEq(thirty, 30, "30% of 100 wei should be 30 wei");
        assertEq(ten, 10, "10% of 100 wei should be 10 wei");
        assertEq(remaining, 60, "Remaining should be 60 wei");
        assertEq(thirty + ten + remaining, amount, "Split should equal original amount");
        
        console2.log("100 wei: 30% = %d wei, 10% = %d wei, remaining = %d wei", thirty, ten, remaining);
    }
    
    function test_DivisibleBy10_1Ether() public view {
        uint256 amount = 1 ether; // 1 ETH = 10^18 wei - divisible by 10
        
        assertTrue(calculator.isDivisibleBy10(amount), "1 ether should be divisible by 10");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        assertEq(thirty, 0.3 ether, "30% of 1 ether should be 0.3 ether");
        assertEq(ten, 0.1 ether, "10% of 1 ether should be 0.1 ether");
        assertEq(remaining, 0.6 ether, "Remaining should be 0.6 ether");
        assertEq(thirty + ten + remaining, amount, "Split should equal original amount");
        
        console2.log("1 ether: 30% = %d wei, 10% = %d wei", thirty, ten);
    }
    
    // ============ Test cases for non-divisible amounts (with remainder) ============
    
    function test_NotDivisibleBy10_1Wei() public view {
        uint256 amount = 1; // 1 wei - NOT divisible by 10
        
        assertFalse(calculator.isDivisibleBy10(amount), "1 wei should NOT be divisible by 10");
        assertEq(calculator.getRemainderMod10(amount), 1, "Remainder should be 1");
        
        (uint256 thirtyPercent,) = calculator.calculate30Percent(amount);
        assertEq(thirtyPercent, 0, "30% of 1 wei should be 0 (truncated)");
        
        (uint256 tenPercent,) = calculator.calculate10Percent(amount);
        assertEq(tenPercent, 0, "10% of 1 wei should be 0 (truncated)");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        console2.log("1 wei: 30% = %d wei, 10% = %d wei, remaining = %d wei", thirty, ten, remaining);
        console2.log("Lost wei due to truncation: %d", amount - (thirty + ten + remaining));
    }
    
    function test_NotDivisibleBy10_3Wei() public view {
        uint256 amount = 3; // 3 wei - NOT divisible by 10
        
        assertFalse(calculator.isDivisibleBy10(amount), "3 wei should NOT be divisible by 10");
        assertEq(calculator.getRemainderMod10(amount), 3, "Remainder should be 3");
        
        (uint256 thirtyPercent,) = calculator.calculate30Percent(amount);
        assertEq(thirtyPercent, 0, "30% of 3 wei = 0.9 wei -> 0 (truncated)");
        
        (uint256 tenPercent,) = calculator.calculate10Percent(amount);
        assertEq(tenPercent, 0, "10% of 3 wei = 0.3 wei -> 0 (truncated)");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        console2.log("3 wei: 30% = %d wei, 10% = %d wei, remaining = %d wei", thirty, ten, remaining);
        console2.log("All 3 wei goes to remaining due to truncation");
    }
    
    function test_NotDivisibleBy10_15Wei() public view {
        uint256 amount = 15; // 15 wei - NOT divisible by 10
        
        assertFalse(calculator.isDivisibleBy10(amount), "15 wei should NOT be divisible by 10");
        assertEq(calculator.getRemainderMod10(amount), 5, "Remainder should be 5");
        
        (uint256 thirtyPercent,) = calculator.calculate30Percent(amount);
        assertEq(thirtyPercent, 4, "30% of 15 wei = 4.5 wei -> 4 (truncated)");
        
        (uint256 tenPercent,) = calculator.calculate10Percent(amount);
        assertEq(tenPercent, 1, "10% of 15 wei = 1.5 wei -> 1 (truncated)");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        assertEq(thirty, 4, "30% should be 4 wei");
        assertEq(ten, 1, "10% should be 1 wei");
        assertEq(remaining, 10, "Remaining should be 10 wei");
        
        console2.log("15 wei: 30% = %d wei, 10% = %d wei, remaining = %d wei", thirty, ten, remaining);
        console2.log("Lost 1 wei due to truncation (4.5 + 1.5 = 6, but got 5)");
    }
    
    function test_NotDivisibleBy10_0_015Ether() public view {
        uint256 amount = 0.015 ether; // 0.015 ETH = 15 * 10^15 wei - NOT divisible by 10
        
        assertFalse(calculator.isDivisibleBy10(amount), "0.015 ether should NOT be divisible by 10");
        
        (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
        
        // 30% of 0.015 ETH = 0.0045 ETH = 4.5 * 10^15 wei -> 4 * 10^15 wei (truncated)
        assertEq(thirty, 4 * 10**15, "30% should be 4 * 10^15 wei (0.004 ETH)");
        
        // 10% of 0.015 ETH = 0.0015 ETH = 1.5 * 10^15 wei -> 1 * 10^15 wei (truncated)
        assertEq(ten, 1 * 10**15, "10% should be 1 * 10^15 wei (0.001 ETH)");
        
        console2.log("0.015 ETH:");
        console2.log("  30% = %d wei", thirty);
        console2.log("  10% = %d wei", ten);
        console2.log("  Remaining = %d wei", remaining);
        console2.log("  Lost wei: %d", amount - (thirty + ten + remaining));
    }
    
    // ============ Test various amounts to show pattern ============
    
    function test_ShowPattern() public view {
        console2.log("\n=== Pattern Analysis: Divisibility by 10 ===\n");
        
        uint256[] memory testAmounts = new uint256[](10);
        testAmounts[0] = 1;      // Not divisible
        testAmounts[1] = 3;      // Not divisible
        testAmounts[2] = 5;      // Not divisible
        testAmounts[3] = 7;      // Not divisible
        testAmounts[4] = 10;     // Divisible
        testAmounts[5] = 15;     // Not divisible
        testAmounts[6] = 20;     // Divisible
        testAmounts[7] = 33;     // Not divisible
        testAmounts[8] = 100;    // Divisible
        testAmounts[9] = 123;    // Not divisible
        
        for (uint i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 remainder = calculator.getRemainderMod10(amount);
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
            uint256 totalAfterSplit = thirty + ten + remaining;
            uint256 lostWei = amount - totalAfterSplit;
            
            console2.log("Amount: %d wei", amount);
            console2.log("  Divisible by 10: %s", divisible ? "true" : "false");
            console2.log("  Remainder (mod 10): %d", remainder);
            console2.log("  30%%: %d wei", thirty);
            console2.log("  10%%: %d wei", ten);
            console2.log("  Remaining: %d wei", remaining);
            if (lostWei > 0) {
                console2.log("  Lost wei: %d", lostWei);
            }
            console2.log("");
        }
    }
    
    // ============ Test with ETH amounts ============
    
    function test_EthAmounts() public view {
        console2.log("\n=== Testing with ETH amounts ===\n");
        
        uint256[] memory amounts = new uint256[](6);
        string[] memory descriptions = new string[](6);
        
        amounts[0] = 0.01 ether;
        descriptions[0] = "0.01 ETH";
        
        amounts[1] = 0.015 ether;
        descriptions[1] = "0.015 ETH";
        
        amounts[2] = 0.03 ether;
        descriptions[2] = "0.03 ETH";
        
        amounts[3] = 0.1 ether;
        descriptions[3] = "0.1 ETH";
        
        amounts[4] = 1 ether;
        descriptions[4] = "1 ETH";
        
        amounts[5] = 1.234 ether;
        descriptions[5] = "1.234 ETH";
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
            uint256 lostWei = amount - (thirty + ten + remaining);
            
            console2.log("%s = %d wei", descriptions[i], amount);
            console2.log("  Divisible by 10: %s", divisible ? "true" : "false");
            console2.log("  30%%: %d wei", thirty);
            console2.log("  10%%: %d wei", ten);
            console2.log("  Remaining: %d wei", remaining);
            if (lostWei > 0) {
                console2.log("  Lost wei: %d (truncation error)", lostWei);
            }
            console2.log("");
        }
    }
}