// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";

/**
 * @title DeployIdentityRegistry
 * @dev Script to deploy the IdentityRegistry contract
 *
 * Usage:
 * forge script script/DeployIdentityRegistry.s.sol:DeployIdentityRegistry \
 *   --rpc-url <RPC_URL> \
 *   --broadcast
 */
contract DeployIdentityRegistry is Script {
    function run() external returns (IdentityRegistry registry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying IdentityRegistry...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the IdentityRegistry with deployer as initial owner
        registry = new IdentityRegistry(deployer);

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("IdentityRegistry deployed at:", address(registry));
        console.log("Registry owner:", registry.owner());
        
        console.log("\nNext Steps:");
        console.log("1. Register identities:");
        console.log("   registry.registerIdentity(walletAddress, identityAddress)");
        console.log("\n2. Check registrations:");
        console.log("   registry.isRegistered(walletAddress)");
        console.log("   registry.getIdentity(walletAddress)");
        console.log("\n3. Manage identities:");
        console.log("   registry.updateIdentity(walletAddress, newIdentityAddress)");
        console.log("   registry.removeIdentity(walletAddress)");

        return registry;
    }
}

