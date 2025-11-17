// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TrustedIssuersRegistry} from "../src/TrustedIssuersRegistry.sol";

contract TrustedIssuersRegistryTest is Test {
    TrustedIssuersRegistry public registry;
    address public owner;
    address public issuer1;
    address public issuer2;
    address public issuer3;

    uint256 constant KYC_TOPIC = 1;
    uint256 constant AML_TOPIC = 2;
    uint256 constant ACCREDITED_TOPIC = 3;
    uint256 constant TAX_TOPIC = 4;

    function setUp() public {
        owner = address(this);
        issuer1 = makeAddr("issuer1");
        issuer2 = makeAddr("issuer2");
        issuer3 = makeAddr("issuer3");

        registry = new TrustedIssuersRegistry(owner);
    }

    function test_Constructor() public {
        assertEq(registry.owner(), owner);
        assertEq(registry.getTrustedIssuersCount(), 0);
    }

    function test_AddTrustedIssuer() public {
        uint256[] memory topics = new uint256[](2);
        topics[0] = KYC_TOPIC;
        topics[1] = AML_TOPIC;

        vm.expectEmit(true, false, false, true);
        emit TrustedIssuersRegistry.TrustedIssuerAdded(issuer1, topics);

        registry.addTrustedIssuer(issuer1, topics);

        assertTrue(registry.isTrustedIssuer(issuer1));
        assertEq(registry.getTrustedIssuersCount(), 1);
        
        uint256[] memory issuerTopics = registry.getIssuerClaimTopics(issuer1);
        assertEq(issuerTopics.length, 2);
    }

    function test_RevertWhen_AddTrustedIssuerInvalidAddress() public {
        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        vm.expectRevert("Invalid issuer address");
        registry.addTrustedIssuer(address(0), topics);
    }

    function test_RevertWhen_AddTrustedIssuerEmptyTopics() public {
        uint256[] memory topics = new uint256[](0);

        vm.expectRevert("Must specify at least one claim topic");
        registry.addTrustedIssuer(issuer1, topics);
    }

    function test_RevertWhen_AddTrustedIssuerAlreadyAdded() public {
        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        registry.addTrustedIssuer(issuer1, topics);

        vm.expectRevert("Issuer already trusted");
        registry.addTrustedIssuer(issuer1, topics);
    }

    function test_RemoveTrustedIssuer() public {
        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        registry.addTrustedIssuer(issuer1, topics);
        assertTrue(registry.isTrustedIssuer(issuer1));

        vm.expectEmit(true, false, false, true);
        emit TrustedIssuersRegistry.TrustedIssuerRemoved(issuer1);

        registry.removeTrustedIssuer(issuer1);

        assertFalse(registry.isTrustedIssuer(issuer1));
        assertEq(registry.getTrustedIssuersCount(), 0);
    }

    function test_RevertWhen_RemoveTrustedIssuerNotTrusted() public {
        vm.expectRevert("Issuer not trusted");
        registry.removeTrustedIssuer(issuer1);
    }

    function test_UpdateIssuerClaimTopics() public {
        uint256[] memory initialTopics = new uint256[](2);
        initialTopics[0] = KYC_TOPIC;
        initialTopics[1] = AML_TOPIC;

        registry.addTrustedIssuer(issuer1, initialTopics);

        uint256[] memory newTopics = new uint256[](3);
        newTopics[0] = KYC_TOPIC;
        newTopics[1] = AML_TOPIC;
        newTopics[2] = ACCREDITED_TOPIC;

        vm.expectEmit(true, false, false, true);
        emit TrustedIssuersRegistry.ClaimTopicsUpdated(issuer1, newTopics);

        registry.updateIssuerClaimTopics(issuer1, newTopics);

        uint256[] memory updatedTopics = registry.getIssuerClaimTopics(issuer1);
        assertEq(updatedTopics.length, 3);
    }

    function test_RevertWhen_UpdateIssuerClaimTopicsNotTrusted() public {
        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        vm.expectRevert("Issuer not trusted");
        registry.updateIssuerClaimTopics(issuer1, topics);
    }

    function test_GetIssuerClaimTopics() public {
        uint256[] memory topics = new uint256[](3);
        topics[0] = KYC_TOPIC;
        topics[1] = AML_TOPIC;
        topics[2] = ACCREDITED_TOPIC;

        registry.addTrustedIssuer(issuer1, topics);

        uint256[] memory issuerTopics = registry.getIssuerClaimTopics(issuer1);
        assertEq(issuerTopics.length, 3);
        assertEq(issuerTopics[0], KYC_TOPIC);
        assertEq(issuerTopics[1], AML_TOPIC);
        assertEq(issuerTopics[2], ACCREDITED_TOPIC);
    }

    function test_HasClaimTopic() public {
        uint256[] memory topics = new uint256[](2);
        topics[0] = KYC_TOPIC;
        topics[1] = AML_TOPIC;

        registry.addTrustedIssuer(issuer1, topics);

        assertTrue(registry.hasClaimTopic(issuer1, KYC_TOPIC));
        assertTrue(registry.hasClaimTopic(issuer1, AML_TOPIC));
        assertFalse(registry.hasClaimTopic(issuer1, ACCREDITED_TOPIC));
    }

    function test_HasClaimTopic_NotTrusted() public {
        assertFalse(registry.hasClaimTopic(issuer1, KYC_TOPIC));
    }

    function test_GetTrustedIssuers() public {
        uint256[] memory topics1 = new uint256[](1);
        topics1[0] = KYC_TOPIC;
        
        uint256[] memory topics2 = new uint256[](1);
        topics2[0] = AML_TOPIC;

        registry.addTrustedIssuer(issuer1, topics1);
        registry.addTrustedIssuer(issuer2, topics2);

        address[] memory issuers = registry.getTrustedIssuers();
        assertEq(issuers.length, 2);
        assertTrue(issuers[0] == issuer1 || issuers[1] == issuer1);
        assertTrue(issuers[0] == issuer2 || issuers[1] == issuer2);
    }

    function test_GetTrustedIssuersCount() public {
        assertEq(registry.getTrustedIssuersCount(), 0);

        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        registry.addTrustedIssuer(issuer1, topics);
        assertEq(registry.getTrustedIssuersCount(), 1);

        registry.addTrustedIssuer(issuer2, topics);
        assertEq(registry.getTrustedIssuersCount(), 2);

        registry.removeTrustedIssuer(issuer1);
        assertEq(registry.getTrustedIssuersCount(), 1);
    }

    function test_MultipleIssuers() public {
        uint256[] memory topics1 = new uint256[](1);
        topics1[0] = KYC_TOPIC;
        
        uint256[] memory topics2 = new uint256[](1);
        topics2[0] = AML_TOPIC;

        uint256[] memory topics3 = new uint256[](2);
        topics3[0] = KYC_TOPIC;
        topics3[1] = AML_TOPIC;

        registry.addTrustedIssuer(issuer1, topics1);
        registry.addTrustedIssuer(issuer2, topics2);
        registry.addTrustedIssuer(issuer3, topics3);

        assertEq(registry.getTrustedIssuersCount(), 3);
        assertTrue(registry.isTrustedIssuer(issuer1));
        assertTrue(registry.isTrustedIssuer(issuer2));
        assertTrue(registry.isTrustedIssuer(issuer3));
    }

    function test_GetTrustedIssuers_Empty() public {
        address[] memory issuers = registry.getTrustedIssuers();
        assertEq(issuers.length, 0);
    }

    function test_RevertWhen_OperationNotOwner() public {
        vm.startPrank(makeAddr("nonOwner"));

        uint256[] memory topics = new uint256[](1);
        topics[0] = KYC_TOPIC;

        vm.expectRevert();
        registry.addTrustedIssuer(issuer1, topics);

        vm.expectRevert();
        registry.removeTrustedIssuer(issuer1);

        vm.expectRevert();
        registry.updateIssuerClaimTopics(issuer1, topics);

        vm.stopPrank();
    }
}

