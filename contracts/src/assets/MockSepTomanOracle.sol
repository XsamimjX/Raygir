// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @notice Signed test oracle. Prices are whole Toman per one SEP and have no real-world claim.
contract MockSepTomanOracle is EIP712 {
    bytes32 public constant UPDATE_TYPEHASH = keccak256(
        "PriceUpdate(uint256 priceTomanPerSep,uint64 observedAt,uint64 nonce,uint64 deadline)"
    );

    address public immutable signer;
    uint64 public immutable maxAge;

    uint256 public priceTomanPerSep;
    uint64 public observedAt;
    uint64 public nonce;

    error InvalidSigner(address recovered);
    error InvalidMaxAge();
    error InvalidPrice();
    error InvalidNonce(uint64 expected, uint64 received);
    error ObservationFromFuture(uint64 observedAt);
    error ObservationOlderThanCurrent(uint64 current, uint64 received);
    error SignatureExpired(uint64 deadline);
    error StalePrice(uint64 observedAt);

    constructor(address initialSigner, uint64 maximumAge) EIP712("Sepehr Toman Mock Oracle", "1") {
        if (initialSigner == address(0)) {
            revert InvalidSigner(initialSigner);
        }
        if (maximumAge == 0) {
            revert InvalidMaxAge();
        }

        signer = initialSigner;
        maxAge = maximumAge;
    }

    function updatePrice(
        uint256 newPriceTomanPerSep,
        uint64 newObservedAt,
        uint64 newNonce,
        uint64 deadline,
        bytes calldata signature
    ) external {
        if (newPriceTomanPerSep == 0) {
            revert InvalidPrice();
        }
        if (newNonce != nonce + 1) {
            revert InvalidNonce(nonce + 1, newNonce);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (newObservedAt > block.timestamp) {
            revert ObservationFromFuture(newObservedAt);
        }
        if (newObservedAt < observedAt) {
            revert ObservationOlderThanCurrent(observedAt, newObservedAt);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (block.timestamp > deadline) {
            revert SignatureExpired(deadline);
        }

        address recovered = ECDSA.recover(
            hashPriceUpdate(newPriceTomanPerSep, newObservedAt, newNonce, deadline), signature
        );
        if (recovered != signer) {
            revert InvalidSigner(recovered);
        }

        priceTomanPerSep = newPriceTomanPerSep;
        observedAt = newObservedAt;
        nonce = newNonce;
    }

    function hashPriceUpdate(
        uint256 newPriceTomanPerSep,
        uint64 newObservedAt,
        uint64 newNonce,
        uint64 deadline
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(UPDATE_TYPEHASH, newPriceTomanPerSep, newObservedAt, newNonce, deadline)
        );
        return _hashTypedDataV4(structHash);
    }

    function currentPrice() external view returns (uint256) {
        // forge-lint: disable-next-line(block-timestamp)
        if (observedAt == 0 || block.timestamp > uint256(observedAt) + maxAge) {
            revert StalePrice(observedAt);
        }

        return priceTomanPerSep;
    }
}
