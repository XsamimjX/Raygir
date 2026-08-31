// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { GovernmentElection } from "./GovernmentElection.sol";

/// @notice Deploys research elections only after a 3-of-5 authority manifest approval.
contract GovernmentElectionFactory {
    uint256 public constant AUTHORITY_COUNT = 5;
    uint256 public constant SIGNATURE_THRESHOLD = 3;

    struct ElectionConfig {
        bytes32 pollId;
        bytes32 manifestHash;
        uint64 opensAt;
        uint64 closesAt;
        uint64 revealClosesAt;
        uint32 optionCount;
        uint32 creditLimit;
    }

    address public immutable proofRelay;
    mapping(address authority => bool trusted) public isAuthority;
    mapping(bytes32 pollId => address election) public electionFor;

    error InvalidConfiguration();
    error DuplicateAuthority(address authority);
    error DuplicateElection(bytes32 pollId);
    error InvalidManifestSignatures();

    event GovernmentElectionCreated(
        bytes32 indexed pollId, address indexed election, bytes32 indexed manifestHash
    );

    constructor(address initialProofRelay, address[AUTHORITY_COUNT] memory authorities) {
        if (initialProofRelay == address(0)) {
            revert InvalidConfiguration();
        }
        proofRelay = initialProofRelay;

        for (uint256 i; i < AUTHORITY_COUNT; ++i) {
            address authority = authorities[i];
            if (authority == address(0)) {
                revert InvalidConfiguration();
            }
            if (isAuthority[authority]) {
                revert DuplicateAuthority(authority);
            }
            isAuthority[authority] = true;
        }
    }

    function createElection(ElectionConfig calldata config, bytes[] calldata signatures)
        external
        returns (GovernmentElection election)
    {
        if (electionFor[config.pollId] != address(0)) {
            revert DuplicateElection(config.pollId);
        }
        if (!_hasThreshold(manifestDigest(config), signatures)) {
            revert InvalidManifestSignatures();
        }

        election = new GovernmentElection{ salt: config.pollId }(
            config.pollId,
            config.manifestHash,
            proofRelay,
            config.opensAt,
            config.closesAt,
            config.revealClosesAt,
            config.optionCount,
            config.creditLimit
        );
        electionFor[config.pollId] = address(election);
        emit GovernmentElectionCreated(config.pollId, address(election), config.manifestHash);
    }

    function manifestDigest(ElectionConfig calldata config) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                "sepehr-government-election-manifest-v1",
                block.chainid,
                address(this),
                proofRelay,
                config
            )
        );
    }

    function _hasThreshold(bytes32 digest, bytes[] calldata signatures)
        private
        view
        returns (bool)
    {
        if (signatures.length < SIGNATURE_THRESHOLD || signatures.length > AUTHORITY_COUNT) {
            return false;
        }

        address[] memory approved = new address[](signatures.length);
        for (uint256 i; i < signatures.length; ++i) {
            address signer = ECDSA.recover(digest, signatures[i]);
            if (!isAuthority[signer]) {
                return false;
            }
            for (uint256 previous; previous < i; ++previous) {
                if (approved[previous] == signer) {
                    return false;
                }
            }
            approved[i] = signer;
        }

        return true;
    }
}
