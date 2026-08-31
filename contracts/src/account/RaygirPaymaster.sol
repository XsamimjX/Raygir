// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {
    IEntryPoint,
    IPaymaster,
    PackedUserOperation
} from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import { ERC4337Utils } from "@openzeppelin/contracts/account/utils/draft-ERC4337Utils.sol";

/// @notice Sponsors only operations carrying a short-lived policy-signer authorization.
contract RaygirPaymaster is IPaymaster {
    using ERC4337Utils for PackedUserOperation;

    bytes32 public constant AUTHORIZATION_TYPEHASH = keccak256(
        "Sponsorship(address paymaster,uint256 chainId,address sender,bytes32 callDataHash,uint256 maxCost,uint48 validAfter,uint48 validUntil,bytes32 quotaId)"
    );

    IEntryPoint public immutable entryPoint;
    address public immutable policySigner;
    uint256 public immutable maximumCostPerOperation;

    mapping(bytes32 quotaId => uint256 spent) public spentByQuota;

    error InvalidConfiguration();
    error UnauthorizedCaller(address caller);
    error InvalidPaymasterData();
    error InvalidAuthorization();
    error CostLimitExceeded(uint256 requested, uint256 permitted);

    constructor(
        IEntryPoint initialEntryPoint,
        address initialPolicySigner,
        uint256 initialMaximumCostPerOperation
    ) {
        if (
            address(initialEntryPoint) == address(0) || initialPolicySigner == address(0)
                || initialMaximumCostPerOperation == 0
        ) {
            revert InvalidConfiguration();
        }

        entryPoint = initialEntryPoint;
        policySigner = initialPolicySigner;
        maximumCostPerOperation = initialMaximumCostPerOperation;
    }

    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32, uint256 maxCost)
        external
        view
        returns (bytes memory context, uint256 validationData)
    {
        _requireEntryPoint();
        if (maxCost > maximumCostPerOperation) {
            revert CostLimitExceeded(maxCost, maximumCostPerOperation);
        }

        bytes calldata data = userOp.paymasterData();
        if (data.length == 0) {
            revert InvalidPaymasterData();
        }

        (uint48 validAfter, uint48 validUntil, bytes32 quotaId, bytes memory signature) =
            abi.decode(data, (uint48, uint48, bytes32, bytes));
        if (validUntil == 0 || validUntil <= validAfter || quotaId == bytes32(0)) {
            revert InvalidPaymasterData();
        }

        bytes32 digest = authorizationDigest(
            userOp.sender, keccak256(userOp.callData), maxCost, validAfter, validUntil, quotaId
        );
        (address recovered, ECDSA.RecoverError error,) = ECDSA.tryRecover(digest, signature);
        if (error != ECDSA.RecoverError.NoError || recovered != policySigner) {
            revert InvalidAuthorization();
        }

        context = abi.encode(quotaId);
        validationData = uint256(validUntil) << 160 | uint256(validAfter) << 208;
    }

    function postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256) external {
        _requireEntryPoint();
        bytes32 quotaId = abi.decode(context, (bytes32));
        spentByQuota[quotaId] += actualGasCost;
    }

    function authorizationDigest(
        address sender,
        bytes32 callDataHash,
        uint256 maxCost,
        uint48 validAfter,
        uint48 validUntil,
        bytes32 quotaId
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                AUTHORIZATION_TYPEHASH,
                address(this),
                block.chainid,
                sender,
                callDataHash,
                maxCost,
                validAfter,
                validUntil,
                quotaId
            )
        );
    }

    function _requireEntryPoint() private view {
        if (msg.sender != address(entryPoint)) {
            revert UnauthorizedCaller(msg.sender);
        }
    }
}
