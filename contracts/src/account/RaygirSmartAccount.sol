// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { Account } from "@openzeppelin/contracts/account/Account.sol";
import { IEntryPoint } from "@openzeppelin/contracts/interfaces/draft-IERC4337.sol";
import { SignerECDSA } from "@openzeppelin/contracts/utils/cryptography/signers/SignerECDSA.sol";

/// @notice Classical-only ERC-4337 account for public extension-wallet funding actions.
contract RaygirSmartAccount is Account, SignerECDSA {
    IEntryPoint private immutable _entryPoint;

    error InvalidConfiguration();
    error CallFailed(bytes returnData);

    constructor(IEntryPoint initialEntryPoint, address initialSigner) SignerECDSA(initialSigner) {
        if (address(initialEntryPoint) == address(0) || initialSigner == address(0)) {
            revert InvalidConfiguration();
        }

        _entryPoint = initialEntryPoint;
    }

    function entryPoint() public view override returns (IEntryPoint) {
        return _entryPoint;
    }

    function execute(address target, uint256 value, bytes calldata data)
        external
        onlyEntryPointOrSelf
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = target.call{ value: value }(data);
        if (!success) {
            revert CallFailed(returnData);
        }
    }
}
