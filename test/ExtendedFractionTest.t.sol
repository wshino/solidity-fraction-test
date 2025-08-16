// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FractionCalculator} from "../src/FractionCalculator.sol";

contract ExtendedFractionTest is Test {
    FractionCalculator public calculator;
    
    function setUp() public {
        calculator = new FractionCalculator();
    }
    
    function test_CommonEthAmounts() public view {
        console2.log("\n=== Common ETH amounts divisibility analysis ===\n");
        
        // Common ETH amounts people might use
        uint256[] memory amounts = new uint256[](20);
        string[] memory descriptions = new string[](20);
        
        // Small amounts
        amounts[0] = 0.001 ether;
        descriptions[0] = "0.001 ETH";
        
        amounts[1] = 0.002 ether;
        descriptions[1] = "0.002 ETH";
        
        amounts[2] = 0.003 ether;
        descriptions[2] = "0.003 ETH";
        
        amounts[3] = 0.004 ether;
        descriptions[3] = "0.004 ETH";
        
        amounts[4] = 0.005 ether;
        descriptions[4] = "0.005 ETH";
        
        amounts[5] = 0.007 ether;
        descriptions[5] = "0.007 ETH";
        
        amounts[6] = 0.009 ether;
        descriptions[6] = "0.009 ETH";
        
        // Common payment amounts
        amounts[7] = 0.025 ether;
        descriptions[7] = "0.025 ETH";
        
        amounts[8] = 0.05 ether;
        descriptions[8] = "0.05 ETH";
        
        amounts[9] = 0.075 ether;
        descriptions[9] = "0.075 ETH";
        
        amounts[10] = 0.123 ether;
        descriptions[10] = "0.123 ETH";
        
        amounts[11] = 0.456 ether;
        descriptions[11] = "0.456 ETH";
        
        amounts[12] = 0.789 ether;
        descriptions[12] = "0.789 ETH";
        
        // Larger amounts
        amounts[13] = 1.5 ether;
        descriptions[13] = "1.5 ETH";
        
        amounts[14] = 2.3 ether;
        descriptions[14] = "2.3 ETH";
        
        amounts[15] = 5.55 ether;
        descriptions[15] = "5.55 ETH";
        
        amounts[16] = 10.01 ether;
        descriptions[16] = "10.01 ETH";
        
        amounts[17] = 99.99 ether;
        descriptions[17] = "99.99 ETH";
        
        amounts[18] = 100.001 ether;
        descriptions[18] = "100.001 ETH";
        
        amounts[19] = 1234.5678 ether;
        descriptions[19] = "1234.5678 ETH";
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 remainder = calculator.getRemainderMod10(amount);
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
            uint256 lostWei = amount - (thirty + ten + remaining);
            
            console2.log("%s", descriptions[i]);
            console2.log("  Wei value: %d", amount);
            console2.log("  Last digit: %d", amount % 10);
            console2.log("  Divisible by 10: %s", divisible ? "YES" : "NO");
            if (!divisible) {
                console2.log("  Remainder: %d wei", remainder);
                if (lostWei > 0) {
                    console2.log("  LOST WEI: %d", lostWei);
                }
            }
            console2.log("");
        }
    }
    
    function test_GweiAmounts() public view {
        console2.log("\n=== Gwei amounts analysis ===\n");
        
        // Test amounts in gwei (1 gwei = 10^9 wei)
        uint256[] memory gweiAmounts = new uint256[](10);
        string[] memory descriptions = new string[](10);
        
        gweiAmounts[0] = 1 gwei;
        descriptions[0] = "1 gwei";
        
        gweiAmounts[1] = 10 gwei;
        descriptions[1] = "10 gwei";
        
        gweiAmounts[2] = 15 gwei;
        descriptions[2] = "15 gwei";
        
        gweiAmounts[3] = 21 gwei;
        descriptions[3] = "21 gwei";
        
        gweiAmounts[4] = 100 gwei;
        descriptions[4] = "100 gwei";
        
        gweiAmounts[5] = 123 gwei;
        descriptions[5] = "123 gwei";
        
        gweiAmounts[6] = 1000 gwei;
        descriptions[6] = "1000 gwei";
        
        gweiAmounts[7] = 1234 gwei;
        descriptions[7] = "1234 gwei";
        
        gweiAmounts[8] = 10000 gwei;
        descriptions[8] = "10000 gwei";
        
        gweiAmounts[9] = 12345 gwei;
        descriptions[9] = "12345 gwei";
        
        for (uint i = 0; i < gweiAmounts.length; i++) {
            uint256 amount = gweiAmounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 remainder = calculator.getRemainderMod10(amount);
            
            console2.log("%s = %d wei", descriptions[i], amount);
            console2.log("  Last digit of wei: %d", amount % 10);
            console2.log("  Divisible by 10: %s", divisible ? "YES" : "NO");
            if (!divisible) {
                console2.log("  Will have remainder: %d wei", remainder);
            }
            console2.log("");
        }
    }
    
    function test_SmallWeiAmounts() public view {
        console2.log("\n=== Small wei amounts (under 1000 wei) ===\n");
        console2.log("Pattern: Only multiples of 10 have no remainder\n");
        
        uint256[] memory testAmounts = new uint256[](20);
        
        // Test various small amounts
        for (uint i = 0; i < 20; i++) {
            if (i < 10) {
                testAmounts[i] = i + 1; // 1-10
            } else {
                testAmounts[i] = (i - 9) * 10 + 3; // 13, 23, 33, ..., 113
            }
        }
        
        for (uint i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            (uint256 thirty, uint256 ten,,) = calculator.splitAmount(amount);
            
            console2.log(string.concat(
                "Amount: ", vm.toString(amount), " wei",
                " | Divisible: ", divisible ? "Y" : "N",
                " | 30%: ", vm.toString(thirty),
                " | 10%: ", vm.toString(ten)
            ));
        }
    }
    
    function test_PatternSummary() public view {
        console2.log("\n=== DIVISIBILITY PATTERN SUMMARY ===\n");
        console2.log("Rule: Amount is divisible by 10 when last digit of wei value is 0\n");
        
        console2.log("ETH amounts that ARE divisible by 10:");
        console2.log("  - 0.01 ETH  = 10,000,000,000,000,000 wei (ends in 0)");
        console2.log("  - 0.02 ETH  = 20,000,000,000,000,000 wei (ends in 0)");
        console2.log("  - 0.1 ETH   = 100,000,000,000,000,000 wei (ends in 0)");
        console2.log("  - 1 ETH     = 1,000,000,000,000,000,000 wei (ends in 0)");
        console2.log("");
        
        console2.log("ETH amounts that are NOT divisible by 10:");
        console2.log("  - 0.001 ETH = 1,000,000,000,000,000 wei (ends in 0) - DIVISIBLE!");
        console2.log("  - 0.003 ETH = 3,000,000,000,000,000 wei (ends in 0) - DIVISIBLE!");
        console2.log("  - 0.007 ETH = 7,000,000,000,000,000 wei (ends in 0) - DIVISIBLE!");
        console2.log("");
        
        console2.log("Actually NOT divisible examples:");
        console2.log("  - 1 wei (ends in 1)");
        console2.log("  - 123 wei (ends in 3)");
        console2.log("  - 1 gwei = 1,000,000,000 wei (ends in 0) - DIVISIBLE!");
        console2.log("  - 21 gwei = 21,000,000,000 wei (ends in 0) - DIVISIBLE!");
        console2.log("");
        
        console2.log("KEY INSIGHT:");
        console2.log("Most ETH/Gwei amounts ARE divisible by 10 because:");
        console2.log("  1 ETH = 10^18 wei (18 zeros)");
        console2.log("  1 Gwei = 10^9 wei (9 zeros)");
        console2.log("  0.001 ETH = 10^15 wei (15 zeros)");
        console2.log("All these have trailing zeros, making them divisible by 10!");
        console2.log("");
        console2.log("Only direct wei amounts like 1, 3, 7, 13, etc. are NOT divisible.");
    }
    
    function test_FindNonDivisibleEthAmounts() public view {
        console2.log("\n=== Finding ETH amounts that are NOT divisible by 10 ===\n");
        
        // To get non-divisible amounts in ETH, we need the wei value to end in 1-9
        // Since 1 ETH = 10^18 wei, we need to add 1-9 wei to make it non-divisible
        
        uint256[] memory amounts = new uint256[](10);
        string[] memory descriptions = new string[](10);
        
        // These will NOT be divisible by 10
        amounts[0] = 1; // 1 wei
        descriptions[0] = "0.000000000000000001 ETH (1 wei)";
        
        amounts[1] = 3; // 3 wei
        descriptions[1] = "0.000000000000000003 ETH (3 wei)";
        
        amounts[2] = 7; // 7 wei
        descriptions[2] = "0.000000000000000007 ETH (7 wei)";
        
        amounts[3] = 13; // 13 wei
        descriptions[3] = "0.000000000000000013 ETH (13 wei)";
        
        amounts[4] = 99; // 99 wei
        descriptions[4] = "0.000000000000000099 ETH (99 wei)";
        
        amounts[5] = 1 ether + 1; // 1 ETH + 1 wei
        descriptions[5] = "1.000000000000000001 ETH";
        
        amounts[6] = 1 ether + 7; // 1 ETH + 7 wei
        descriptions[6] = "1.000000000000000007 ETH";
        
        amounts[7] = 0.1 ether + 3; // 0.1 ETH + 3 wei
        descriptions[7] = "0.100000000000000003 ETH";
        
        amounts[8] = 10 ether + 123; // 10 ETH + 123 wei
        descriptions[8] = "10.000000000000000123 ETH";
        
        amounts[9] = 0.001 ether + 9; // 0.001 ETH + 9 wei
        descriptions[9] = "0.001000000000000009 ETH";
        
        console2.log("These amounts will have remainders when calculating 30%% and 10%%:\n");
        
        for (uint i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            bool divisible = calculator.isDivisibleBy10(amount);
            uint256 remainder = calculator.getRemainderMod10(amount);
            (uint256 thirty, uint256 ten, uint256 remaining,) = calculator.splitAmount(amount);
            uint256 lostWei = amount - (thirty + ten + remaining);
            
            console2.log("%s", descriptions[i]);
            console2.log("  Wei value: %d", amount);
            console2.log("  Divisible by 10: %s", divisible ? "YES" : "NO");
            console2.log("  Remainder (mod 10): %d", remainder);
            if (lostWei > 0) {
                console2.log("  Lost wei in calculation: %d", lostWei);
            }
            console2.log("");
        }
    }
}