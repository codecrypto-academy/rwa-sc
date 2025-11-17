// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IdentityCloneFactory} from "../src/IdentityCloneFactory.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {TrustedIssuersRegistry} from "../src/TrustedIssuersRegistry.sol";
import {TokenCloneFactory} from "../src/TokenCloneFactory.sol";
import {TokenCloneable} from "../src/TokenCloneable.sol";
import {IdentityCloneable} from "../src/IdentityCloneable.sol";

/**
 * @title DeployComplete
 * @dev Complete deployment script that sets up the entire system:
 * - Deploys all factories and registries
 * - Creates 3 identities using Anvil accounts
 * - Adds 3 trusted issuers
 * - Creates 1 security token
 * 
 * Usage:
 * forge script script/DeployComplete.s.sol:DeployComplete --rpc-url http://localhost:8545 --broadcast
 */
contract DeployComplete is Script {
    // Anvil default accounts (first 4)
    address constant ACCOUNT_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ACCOUNT_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant ACCOUNT_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant ACCOUNT_3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    
    // Deployed contracts
    IdentityCloneFactory public identityFactory;
    IdentityRegistry public identityRegistry;
    TrustedIssuersRegistry public trustedIssuersRegistry;
    TokenCloneFactory public tokenFactory;
    
    // Created identities
    address public identity0;
    address public identity1;
    address public identity2;
    
    // Created token
    address public token;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("================================================================================");
        console.log("COMPLETE DEPLOYMENT SCRIPT");
        console.log("================================================================================");
        console.log("Deployer:", deployer);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy all factories and registries
        console.log("Step 1: Deploying Factories and Registries...");
        deployContracts(deployer);
        
        // Step 2: Create 3 identities
        console.log("\nStep 2: Creating 3 Identities...");
        createIdentities();
        
        // Step 3: Register identities
        console.log("\nStep 3: Registering Identities...");
        registerIdentities();
        
        // Step 4: Add 3 trusted issuers
        console.log("\nStep 4: Adding 3 Trusted Issuers...");
        addTrustedIssuers();
        
        // Step 5: Create 1 security token
        console.log("\nStep 5: Creating Security Token...");
        createToken();
        
        vm.stopBroadcast();
        
        // Step 6: Print summary
        printSummary();
    }
    
    function deployContracts(address deployer) internal {
        // Deploy IdentityCloneFactory
        identityFactory = new IdentityCloneFactory(deployer);
        console.log("  IdentityCloneFactory:", address(identityFactory));
        console.log("  - Implementation:", identityFactory.implementation());
        
        // Deploy IdentityRegistry
        identityRegistry = new IdentityRegistry(deployer);
        console.log("  IdentityRegistry:", address(identityRegistry));
        
        // Deploy TrustedIssuersRegistry
        trustedIssuersRegistry = new TrustedIssuersRegistry(deployer);
        console.log("  TrustedIssuersRegistry:", address(trustedIssuersRegistry));
        
        // Deploy TokenCloneFactory
        tokenFactory = new TokenCloneFactory(deployer);
        console.log("  TokenCloneFactory:", address(tokenFactory));
        console.log("  - Implementation:", tokenFactory.implementation());
    }
    
    function createIdentities() internal {
        // Create identity for Account 0
        identity0 = identityFactory.createIdentity(ACCOUNT_0);
        console.log("  Identity 0 created:", identity0);
        console.log("    Owner: ", ACCOUNT_0);
        
        // Create identity for Account 1
        identity1 = identityFactory.createIdentity(ACCOUNT_1);
        console.log("  Identity 1 created:", identity1);
        console.log("    Owner: ", ACCOUNT_1);
        
        // Create identity for Account 2
        identity2 = identityFactory.createIdentity(ACCOUNT_2);
        console.log("  Identity 2 created:", identity2);
        console.log("    Owner: ", ACCOUNT_2);
    }
    
    function registerIdentities() internal {
        // Register all identities in the registry
        identityRegistry.registerIdentity(ACCOUNT_0, identity0);
        console.log("  Registered:", ACCOUNT_0, "->", identity0);
        
        identityRegistry.registerIdentity(ACCOUNT_1, identity1);
        console.log("  Registered:", ACCOUNT_1, "->", identity1);
        
        identityRegistry.registerIdentity(ACCOUNT_2, identity2);
        console.log("  Registered:", ACCOUNT_2, "->", identity2);
    }
    
    function addTrustedIssuers() internal {
        // Prepare claim topics (KYC, AML, Accredited Investor)
        uint256[] memory claimTopics1 = new uint256[](2);
        claimTopics1[0] = 1; // KYC
        claimTopics1[1] = 2; // AML
        
        uint256[] memory claimTopics2 = new uint256[](2);
        claimTopics2[0] = 1; // KYC
        claimTopics2[1] = 3; // Accredited Investor
        
        uint256[] memory claimTopics3 = new uint256[](3);
        claimTopics3[0] = 1; // KYC
        claimTopics3[1] = 2; // AML
        claimTopics3[2] = 3; // Accredited Investor
        
        // Add Account 0 as trusted issuer
        trustedIssuersRegistry.addTrustedIssuer(ACCOUNT_0, claimTopics1);
        console.log("  Trusted Issuer 1:", ACCOUNT_0);
        console.log("    Topics: KYC, AML");
        
        // Add Account 1 as trusted issuer
        trustedIssuersRegistry.addTrustedIssuer(ACCOUNT_1, claimTopics2);
        console.log("  Trusted Issuer 2:", ACCOUNT_1);
        console.log("    Topics: KYC, Accredited Investor");
        
        // Add Account 2 as trusted issuer
        trustedIssuersRegistry.addTrustedIssuer(ACCOUNT_2, claimTopics3);
        console.log("  Trusted Issuer 3:", ACCOUNT_2);
        console.log("    Topics: KYC, AML, Accredited Investor");
    }
    
    function createToken() internal {
        // Create a security token with registries
        token = tokenFactory.createTokenWithRegistries(
            "RWA Security Token",          // name
            "RWAST",                       // symbol
            18,                            // decimals
            ACCOUNT_0,                     // admin (Account 0)
            address(identityRegistry),     // identity registry
            address(trustedIssuersRegistry), // trusted issuers registry
            address(0)                     // claim topics registry (not used yet)
        );
        
        console.log("  Token created:", token);
        console.log("    Name: RWA Security Token");
        console.log("    Symbol: RWAST");
        console.log("    Decimals: 18");
        console.log("    Admin:", ACCOUNT_0);
    }
    
    function printSummary() internal view {
        console.log("\n");
        console.log("================================================================================");
        console.log("DEPLOYMENT SUMMARY");
        console.log("================================================================================");
        
        console.log("\n[FACTORIES]");
        console.log("IdentityCloneFactory:    ", address(identityFactory));
        console.log("  Implementation:        ", identityFactory.implementation());
        console.log("TokenCloneFactory:       ", address(tokenFactory));
        console.log("  Implementation:        ", tokenFactory.implementation());
        
        console.log("\n[REGISTRIES]");
        console.log("IdentityRegistry:        ", address(identityRegistry));
        console.log("TrustedIssuersRegistry:  ", address(trustedIssuersRegistry));
        
        console.log("\n[IDENTITIES]");
        console.log("Identity 0 (Account 0):  ", identity0);
        console.log("  Owner:                 ", ACCOUNT_0);
        console.log("Identity 1 (Account 1):  ", identity1);
        console.log("  Owner:                 ", ACCOUNT_1);
        console.log("Identity 2 (Account 2):  ", identity2);
        console.log("  Owner:                 ", ACCOUNT_2);
        
        console.log("\n[TRUSTED ISSUERS]");
        console.log("Issuer 1:                ", ACCOUNT_0);
        console.log("Issuer 2:                ", ACCOUNT_1);
        console.log("Issuer 3:                ", ACCOUNT_2);
        console.log("Total Issuers:           ", trustedIssuersRegistry.getTrustedIssuersCount());
        
        console.log("\n[TOKEN]");
        console.log("Token Address:           ", token);
        console.log("Token Admin:             ", ACCOUNT_0);
        console.log("Total Tokens Created:    ", tokenFactory.getTotalTokens());
        
        console.log("\n[ANVIL ACCOUNTS]");
        console.log("Account 0 (Admin):       ", ACCOUNT_0);
        console.log("Account 1:               ", ACCOUNT_1);
        console.log("Account 2:               ", ACCOUNT_2);
        console.log("Account 3:               ", ACCOUNT_3);
        
        console.log("\n================================================================================");
        console.log("DEPLOYMENT COMPLETE!");
        console.log("================================================================================");
    }
}

