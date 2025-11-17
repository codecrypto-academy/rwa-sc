// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MaxBalanceCompliance} from "../src/compliance/MaxBalanceCompliance.sol";
import {MaxHoldersCompliance} from "../src/compliance/MaxHoldersCompliance.sol";
import {TransferLockCompliance} from "../src/compliance/TransferLockCompliance.sol";

/**
 * @title DeployCompliance
 * @dev Script to deploy compliance modules
 *
 * Usage (Simulation):
 * forge script script/DeployCompliance.s.sol:DeployCompliance
 *
 * Usage (Local Anvil):
 * export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 * forge script script/DeployCompliance.s.sol:DeployCompliance \
 *   --rpc-url http://localhost:8545 \
 *   --broadcast
 *
 * Usage (Testnet/Mainnet):
 * forge script script/DeployCompliance.s.sol:DeployCompliance \
 *   --rpc-url $RPC_URL \
 *   --broadcast \
 *   --verify
 */
contract DeployCompliance is Script {
    struct ComplianceContracts {
        MaxBalanceCompliance maxBalance;
        MaxHoldersCompliance maxHolders;
        TransferLockCompliance transferLock;
    }

    function run() external returns (ComplianceContracts memory contracts) {
        address deployer = msg.sender;
        
        console.log("========================================");
        console.log("  COMPLIANCE CONTRACTS DEPLOYMENT");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast();

        // 1. Deploy MaxBalanceCompliance
        console.log("[1/3] Deploying MaxBalanceCompliance...");
        // Default: 1M tokens (1,000,000 * 10^18)
        uint256 defaultMaxBalance = 1_000_000 * 10**18;
        contracts.maxBalance = new MaxBalanceCompliance(deployer, defaultMaxBalance);
        console.log("  MaxBalanceCompliance deployed at:", address(contracts.maxBalance));
        console.log("  Default max balance:", defaultMaxBalance);
        console.log("");

        // 2. Deploy MaxHoldersCompliance
        console.log("[2/3] Deploying MaxHoldersCompliance...");
        // Default: 100 holders
        uint256 defaultMaxHolders = 100;
        contracts.maxHolders = new MaxHoldersCompliance(deployer, defaultMaxHolders);
        console.log("  MaxHoldersCompliance deployed at:", address(contracts.maxHolders));
        console.log("  Default max holders:", defaultMaxHolders);
        console.log("");

        // 3. Deploy TransferLockCompliance
        console.log("[3/3] Deploying TransferLockCompliance...");
        // Default: 1 day (86400 seconds)
        uint256 defaultLockPeriod = 86400;
        contracts.transferLock = new TransferLockCompliance(deployer, defaultLockPeriod);
        console.log("  TransferLockCompliance deployed at:", address(contracts.transferLock));
        console.log("  Default lock period:", defaultLockPeriod, "seconds (1 day)");
        console.log("");

        vm.stopBroadcast();

        _printSummary(contracts, deployer);

        return contracts;
    }

    function _printSummary(ComplianceContracts memory contracts, address deployer) internal pure {
        console.log("========================================");
        console.log("      DEPLOYMENT COMPLETE");
        console.log("========================================");
        console.log("");
        
        console.log("Contract Addresses:");
        console.log("-------------------");
        console.log("MaxBalanceCompliance:    ", address(contracts.maxBalance));
        console.log("MaxHoldersCompliance:    ", address(contracts.maxHolders));
        console.log("TransferLockCompliance:  ", address(contracts.transferLock));
        console.log("");
        
        console.log("Owner/Deployer:          ", deployer);
        console.log("");

        console.log("========================================");
        console.log("         USAGE GUIDE");
        console.log("========================================");
        console.log("");
        
        console.log("Individual Compliance Modules");
        console.log("-----------------------------");
        console.log("Each module enforces a specific compliance rule");
        console.log("and can be added independently to tokens.");
        console.log("");
        console.log("Setup for each module:");
        console.log("");
        console.log("  MaxBalanceCompliance:");
        console.log("    1. module.bindToken(tokenAddress)");
        console.log("    2. module.setMaxBalance(tokenAddress, maxAmount)");
        console.log("    3. token.addComplianceModule(moduleAddress)");
        console.log("");
        console.log("  MaxHoldersCompliance:");
        console.log("    1. module.bindToken(tokenAddress)");
        console.log("    2. module.setMaxHolders(tokenAddress, maxCount)");
        console.log("    3. token.addComplianceModule(moduleAddress)");
        console.log("");
        console.log("  TransferLockCompliance:");
        console.log("    1. module.bindToken(tokenAddress)");
        console.log("    2. module.setLockPeriod(tokenAddress, seconds)");
        console.log("    3. token.addComplianceModule(moduleAddress)");
        console.log("");
        
        console.log("========================================");
        console.log("     COMPLIANCE RULES EXPLAINED");
        console.log("========================================");
        console.log("");
        console.log("MaxBalance:");
        console.log("  - Limits max tokens per wallet");
        console.log("  - Prevents concentration of ownership");
        console.log("  - Example: Max 1M tokens per investor");
        console.log("");
        console.log("MaxHolders:");
        console.log("  - Limits total number of token holders");
        console.log("  - Required for some securities regulations");
        console.log("  - Example: Max 100 investors for private securities");
        console.log("");
        console.log("TransferLock:");
        console.log("  - Enforces holding period after receiving tokens");
        console.log("  - Prevents immediate resale (lock-up period)");
        console.log("  - Example: 1-day lock after token purchase");
        console.log("");
        
        console.log("========================================");
        console.log("");
    }
}

