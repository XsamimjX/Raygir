// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { PredictionPool } from "./PredictionPool.sol";

/// @notice Deploys immutable prediction pools from reviewed market identifiers.
contract PredictionPoolFactory {
    IERC20 public immutable asset;
    address public immutable proofRelay;
    address public immutable resolver;
    mapping(bytes32 marketId => address pool) public poolFor;

    error InvalidConfiguration();
    error DuplicateMarket(bytes32 marketId);

    event PredictionPoolCreated(
        bytes32 indexed marketId, address indexed pool, address indexed creator
    );

    constructor(IERC20 initialAsset, address initialProofRelay, address initialResolver) {
        if (
            address(initialAsset) == address(0) || initialProofRelay == address(0)
                || initialResolver == address(0)
        ) {
            revert InvalidConfiguration();
        }

        asset = initialAsset;
        proofRelay = initialProofRelay;
        resolver = initialResolver;
    }

    function createPredictionPool(
        bytes32 marketId,
        uint64 opensAt,
        uint64 closesAt,
        uint16 boostBps
    ) external returns (PredictionPool pool) {
        if (marketId == bytes32(0)) {
            revert InvalidConfiguration();
        }
        if (poolFor[marketId] != address(0)) {
            revert DuplicateMarket(marketId);
        }

        pool = new PredictionPool{ salt: marketId }(
            asset, msg.sender, proofRelay, resolver, opensAt, closesAt, boostBps
        );
        poolFor[marketId] = address(pool);
        emit PredictionPoolCreated(marketId, address(pool), msg.sender);
    }
}
