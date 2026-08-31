// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

/// @notice Immutable catalog of contract and verifier artifacts for one protocol release.
contract ImmutableVersionRegistry {
    struct Entry {
        bytes32 component;
        uint64 version;
        address implementation;
        bytes32 artifactDigest;
    }

    mapping(bytes32 key => Entry entry) private entries;

    error InvalidEntry(bytes32 component, uint64 version, address implementation);
    error DuplicateEntry(bytes32 key);
    error UnknownEntry(bytes32 key);

    constructor(Entry[] memory initialEntries) {
        uint256 entryCount = initialEntries.length;
        for (uint256 i; i < entryCount; ++i) {
            Entry memory entry = initialEntries[i];
            if (
                entry.component == bytes32(0) || entry.version == 0
                    || entry.implementation == address(0) || entry.artifactDigest == bytes32(0)
            ) {
                revert InvalidEntry(entry.component, entry.version, entry.implementation);
            }

            bytes32 entryKey = keyFor(entry.component, entry.version);
            if (entries[entryKey].implementation != address(0)) {
                revert DuplicateEntry(entryKey);
            }
            entries[entryKey] = entry;
        }
    }

    function get(bytes32 component, uint64 version) external view returns (Entry memory entry) {
        bytes32 entryKey = keyFor(component, version);
        entry = entries[entryKey];
        if (entry.implementation == address(0)) {
            revert UnknownEntry(entryKey);
        }
    }

    function keyFor(bytes32 component, uint64 version) public pure returns (bytes32) {
        return keccak256(abi.encode(component, version));
    }
}

