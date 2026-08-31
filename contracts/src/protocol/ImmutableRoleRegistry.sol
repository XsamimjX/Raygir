// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @notice Fixed pre-PoS role assignments. Replacing a key requires deploying a new registry.
contract ImmutableRoleRegistry {
    mapping(bytes32 role => address account) public accountFor;

    error LengthMismatch();
    error InvalidRole(bytes32 role, address account);
    error DuplicateRole(bytes32 role);
    error UnknownRole(bytes32 role);

    constructor(bytes32[] memory roles, address[] memory accounts) {
        uint256 roleCount = roles.length;
        if (roleCount != accounts.length) {
            revert LengthMismatch();
        }

        for (uint256 i; i < roleCount; ++i) {
            bytes32 role = roles[i];
            address account = accounts[i];
            if (role == bytes32(0) || account == address(0)) {
                revert InvalidRole(role, account);
            }
            if (accountFor[role] != address(0)) {
                revert DuplicateRole(role);
            }
            accountFor[role] = account;
        }
    }

    function requireRole(bytes32 role, address caller) external view {
        address account = accountFor[role];
        if (account == address(0)) {
            revert UnknownRole(role);
        }
        if (account != caller) {
            revert InvalidRole(role, caller);
        }
    }
}

