// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ClaimTopicsRegistryCloneFactory} from "../src/ClaimTopicsRegistryCloneFactory.sol";

contract DeployClaimTopicsRegistryCloneFactory is Script {
    function run() external returns (ClaimTopicsRegistryCloneFactory) {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        vm.startBroadcast();
        
        ClaimTopicsRegistryCloneFactory factory = new ClaimTopicsRegistryCloneFactory(deployer);
        
        vm.stopBroadcast();
        
        return factory;
    }
}

