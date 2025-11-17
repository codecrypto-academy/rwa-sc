// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {TrustedIssuersRegistry} from "../src/TrustedIssuersRegistry.sol";

/**
 * @title DeployTrustedIssuersRegistry
 * @dev Script to deploy the TrustedIssuersRegistry contract
 *
 * Usage:
 * forge script script/DeployTrustedIssuersRegistry.s.sol:DeployTrustedIssuersRegistry \
 *   --rpc-url <RPC_URL> \
 *   --broadcast
 */
contract DeployTrustedIssuersRegistry is Script {
    function run() external returns (TrustedIssuersRegistry registry) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying TrustedIssuersRegistry...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the TrustedIssuersRegistry with deployer as initial owner
        registry = new TrustedIssuersRegistry(deployer);

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("TrustedIssuersRegistry deployed at:", address(registry));
        console.log("Registry owner:", registry.owner());
        
        console.log("\nNext Steps:");
        console.log("1. Add trusted issuers:");
        console.log("   uint256[] memory claimTopics = new uint256[](1);");
        console.log("   claimTopics[0] = 1; // e.g., KYC claim");
        console.log("   registry.addTrustedIssuer(issuerAddress, claimTopics)");
        console.log("\n2. Check issuer status:");
        console.log("   registry.isTrustedIssuer(issuerAddress)");
        console.log("   registry.getIssuerClaimTopics(issuerAddress)");
        console.log("   registry.hasClaimTopic(issuerAddress, claimTopic)");
        console.log("\n3. View all trusted issuers:");
        console.log("   registry.getTrustedIssuers()");
        console.log("   registry.getTrustedIssuersCount()");
        console.log("\n4. Manage issuers:");
        console.log("   registry.updateIssuerClaimTopics(issuerAddress, newClaimTopics)");
        console.log("   registry.removeTrustedIssuer(issuerAddress)");

        return registry;
    }
}

