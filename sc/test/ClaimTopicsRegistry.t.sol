// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ClaimTopicsRegistry} from "../src/ClaimTopicsRegistry.sol";

contract ClaimTopicsRegistryTest is Test {
    ClaimTopicsRegistry public registry;
    address public owner;
    address public nonOwner;

    uint256 constant KYC_TOPIC = 1;
    uint256 constant AML_TOPIC = 2;
    uint256 constant ACCREDITED_TOPIC = 3;
    uint256 constant TAX_TOPIC = 4;

    function setUp() public {
        owner = address(this);
        nonOwner = makeAddr("nonOwner");
        registry = new ClaimTopicsRegistry(owner);
    }

    function test_Constructor() public {
        assertEq(registry.owner(), owner);
        assertEq(registry.getClaimTopicsCount(), 0);
    }

    function test_AddClaimTopic() public {
        registry.addClaimTopic(KYC_TOPIC);

        assertTrue(registry.claimTopicExists(KYC_TOPIC));
        assertEq(registry.getClaimTopicsCount(), 1);

        uint256[] memory topics = registry.getClaimTopics();
        assertEq(topics.length, 1);
        assertEq(topics[0], KYC_TOPIC);
    }

    function test_AddClaimTopic_Event() public {
        vm.expectEmit(true, false, false, true);
        emit ClaimTopicsRegistry.ClaimTopicAdded(KYC_TOPIC);

        registry.addClaimTopic(KYC_TOPIC);
    }

    function test_RevertWhen_AddClaimTopicNotOwner() public {
        vm.startPrank(nonOwner);

        vm.expectRevert();
        registry.addClaimTopic(KYC_TOPIC);

        vm.stopPrank();
    }

    function test_RevertWhen_AddClaimTopicDuplicate() public {
        registry.addClaimTopic(KYC_TOPIC);

        vm.expectRevert("Claim topic already exists");
        registry.addClaimTopic(KYC_TOPIC);
    }

    function test_RemoveClaimTopic() public {
        registry.addClaimTopic(KYC_TOPIC);
        registry.addClaimTopic(AML_TOPIC);

        assertEq(registry.getClaimTopicsCount(), 2);

        vm.expectEmit(true, false, false, true);
        emit ClaimTopicsRegistry.ClaimTopicRemoved(KYC_TOPIC);

        registry.removeClaimTopic(KYC_TOPIC);

        assertFalse(registry.claimTopicExists(KYC_TOPIC));
        assertTrue(registry.claimTopicExists(AML_TOPIC));
        assertEq(registry.getClaimTopicsCount(), 1);
    }

    function test_RevertWhen_RemoveClaimTopicNotOwner() public {
        registry.addClaimTopic(KYC_TOPIC);

        vm.startPrank(nonOwner);
        vm.expectRevert();
        registry.removeClaimTopic(KYC_TOPIC);
        vm.stopPrank();
    }

    function test_RevertWhen_RemoveClaimTopicNotExists() public {
        vm.expectRevert("Claim topic does not exist");
        registry.removeClaimTopic(KYC_TOPIC);
    }

    function test_GetClaimTopics() public {
        registry.addClaimTopic(KYC_TOPIC);
        registry.addClaimTopic(AML_TOPIC);
        registry.addClaimTopic(ACCREDITED_TOPIC);

        uint256[] memory topics = registry.getClaimTopics();
        assertEq(topics.length, 3);
        
        // Order should be preserved
        assertEq(topics[0], KYC_TOPIC);
        assertEq(topics[1], AML_TOPIC);
        assertEq(topics[2], ACCREDITED_TOPIC);
    }

    function test_GetClaimTopics_Empty() public {
        uint256[] memory topics = registry.getClaimTopics();
        assertEq(topics.length, 0);
    }

    function test_ClaimTopicExists() public {
        assertFalse(registry.claimTopicExists(KYC_TOPIC));

        registry.addClaimTopic(KYC_TOPIC);
        assertTrue(registry.claimTopicExists(KYC_TOPIC));
    }

    function test_GetClaimTopicsCount() public {
        assertEq(registry.getClaimTopicsCount(), 0);

        registry.addClaimTopic(KYC_TOPIC);
        assertEq(registry.getClaimTopicsCount(), 1);

        registry.addClaimTopic(AML_TOPIC);
        assertEq(registry.getClaimTopicsCount(), 2);

        registry.removeClaimTopic(KYC_TOPIC);
        assertEq(registry.getClaimTopicsCount(), 1);
    }

    function test_MultipleTopics() public {
        registry.addClaimTopic(KYC_TOPIC);
        registry.addClaimTopic(AML_TOPIC);
        registry.addClaimTopic(ACCREDITED_TOPIC);
        registry.addClaimTopic(TAX_TOPIC);

        assertEq(registry.getClaimTopicsCount(), 4);
        assertTrue(registry.claimTopicExists(KYC_TOPIC));
        assertTrue(registry.claimTopicExists(AML_TOPIC));
        assertTrue(registry.claimTopicExists(ACCREDITED_TOPIC));
        assertTrue(registry.claimTopicExists(TAX_TOPIC));
    }

    function test_RemoveFromMiddle() public {
        registry.addClaimTopic(KYC_TOPIC);
        registry.addClaimTopic(AML_TOPIC);
        registry.addClaimTopic(ACCREDITED_TOPIC);

        registry.removeClaimTopic(AML_TOPIC);

        assertEq(registry.getClaimTopicsCount(), 2);
        assertTrue(registry.claimTopicExists(KYC_TOPIC));
        assertFalse(registry.claimTopicExists(AML_TOPIC));
        assertTrue(registry.claimTopicExists(ACCREDITED_TOPIC));
    }

    function test_RemoveAllTopics() public {
        registry.addClaimTopic(KYC_TOPIC);
        registry.addClaimTopic(AML_TOPIC);
        registry.addClaimTopic(ACCREDITED_TOPIC);

        registry.removeClaimTopic(KYC_TOPIC);
        registry.removeClaimTopic(AML_TOPIC);
        registry.removeClaimTopic(ACCREDITED_TOPIC);

        assertEq(registry.getClaimTopicsCount(), 0);
        assertEq(registry.getClaimTopics().length, 0);
    }
}

