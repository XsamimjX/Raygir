// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import { ImmutableRoleRegistry } from "../../src/protocol/ImmutableRoleRegistry.sol";
import { ImmutableVersionRegistry } from "../../src/protocol/ImmutableVersionRegistry.sol";

contract ImmutableRegistriesTest is Test {
    bytes32 private constant ORACLE_ROLE = keccak256("ORACLE_COMMITTEE");
    bytes32 private constant CIVIC_COMPONENT = keccak256("CIVIC_POLL");
    address private constant ORACLE_ACCOUNT = address(0x5001);
    address private constant IMPLEMENTATION = address(0x5002);
    bytes32 private constant DIGEST = keccak256("artifact");

    function testRoleAssignmentsAreReadableAndEnforced() public {
        bytes32[] memory roles = new bytes32[](1);
        roles[0] = ORACLE_ROLE;
        address[] memory accounts = new address[](1);
        accounts[0] = ORACLE_ACCOUNT;
        ImmutableRoleRegistry registry = new ImmutableRoleRegistry(roles, accounts);

        assertEq(registry.accountFor(ORACLE_ROLE), ORACLE_ACCOUNT);
        registry.requireRole(ORACLE_ROLE, ORACLE_ACCOUNT);

        vm.expectRevert(
            abi.encodeWithSelector(
                ImmutableRoleRegistry.InvalidRole.selector, ORACLE_ROLE, address(this)
            )
        );
        registry.requireRole(ORACLE_ROLE, address(this));
    }

    function testDuplicateRoleReverts() public {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ORACLE_ROLE;
        roles[1] = ORACLE_ROLE;
        address[] memory accounts = new address[](2);
        accounts[0] = ORACLE_ACCOUNT;
        accounts[1] = address(0x5003);

        vm.expectRevert(
            abi.encodeWithSelector(ImmutableRoleRegistry.DuplicateRole.selector, ORACLE_ROLE)
        );
        new ImmutableRoleRegistry(roles, accounts);
    }

    function testVersionEntryIsBoundToComponentVersionAndDigest() public {
        ImmutableVersionRegistry registry = _versionRegistry();
        ImmutableVersionRegistry.Entry memory entry = registry.get(CIVIC_COMPONENT, 1);

        assertEq(entry.component, CIVIC_COMPONENT);
        assertEq(entry.version, 1);
        assertEq(entry.implementation, IMPLEMENTATION);
        assertEq(entry.artifactDigest, DIGEST);
    }

    function testUnknownVersionReverts() public {
        ImmutableVersionRegistry registry = _versionRegistry();
        bytes32 expectedKey = registry.keyFor(CIVIC_COMPONENT, 2);

        vm.expectRevert(
            abi.encodeWithSelector(ImmutableVersionRegistry.UnknownEntry.selector, expectedKey)
        );
        registry.get(CIVIC_COMPONENT, 2);
    }

    function _versionRegistry() private returns (ImmutableVersionRegistry) {
        ImmutableVersionRegistry.Entry[] memory entries = new ImmutableVersionRegistry.Entry[](1);
        entries[0] = ImmutableVersionRegistry.Entry({
            component: CIVIC_COMPONENT,
            version: 1,
            implementation: IMPLEMENTATION,
            artifactDigest: DIGEST
        });
        return new ImmutableVersionRegistry(entries);
    }
}
