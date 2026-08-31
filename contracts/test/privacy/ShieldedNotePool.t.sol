// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";

import { IShieldedNoteVerifier } from "../../src/privacy/IShieldedNoteVerifier.sol";
import { ShieldedNotePool } from "../../src/privacy/ShieldedNotePool.sol";

contract ShieldedAsset is ERC20 {
    constructor() ERC20("Sepehr Toman", "SPTM") { }

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

contract ShieldedVerifierFixture is IShieldedNoteVerifier {
    function verify(
        bytes calldata proof,
        bytes32 commitment,
        bytes32 nullifier,
        address recipient,
        uint128 amount
    ) external pure returns (bool) {
        return keccak256(proof) == keccak256(abi.encode(commitment, nullifier, recipient, amount));
    }
}

contract ShieldedNotePoolTest is Test {
    address private constant Depositor = address(0xA11CE);
    address private constant Recipient = address(0xB0B);
    bytes32 private constant FirstCommitment = keccak256("first-note");
    bytes32 private constant SecondCommitment = keccak256("second-note");
    bytes32 private constant Nullifier = keccak256("spent-first-note");

    ShieldedAsset private asset;
    ShieldedNotePool private pool;

    function setUp() public {
        asset = new ShieldedAsset();
        pool = new ShieldedNotePool(asset, new ShieldedVerifierFixture());
        asset.mint(Depositor, 100 ether);
        vm.prank(Depositor);
        asset.approve(address(pool), type(uint256).max);
    }

    function testBatchesDepositsAndWithdrawsWithProof() public {
        bytes32[] memory commitments = new bytes32[](2);
        commitments[0] = FirstCommitment;
        commitments[1] = SecondCommitment;
        uint128[] memory amounts = new uint128[](2);
        amounts[0] = 40 ether;
        amounts[1] = 60 ether;

        vm.prank(Depositor);
        pool.deposit(commitments, amounts);

        bytes memory proof = abi.encode(FirstCommitment, Nullifier, Recipient, uint128(40 ether));
        pool.withdraw(proof, FirstCommitment, Nullifier, Recipient, 40 ether);

        assertEq(asset.balanceOf(Recipient), 40 ether);
        assertEq(asset.balanceOf(address(pool)), 60 ether);
        assertEq(pool.depositedAmount(FirstCommitment), 0);
        assertTrue(pool.nullifierUsed(Nullifier));
    }

    function testRejectsDuplicateCommitmentForgedProofAndReplay() public {
        bytes32[] memory commitments = new bytes32[](2);
        commitments[0] = FirstCommitment;
        commitments[1] = SecondCommitment;
        uint128[] memory amounts = new uint128[](2);
        amounts[0] = 40 ether;
        amounts[1] = 40 ether;
        vm.prank(Depositor);
        pool.deposit(commitments, amounts);

        vm.expectRevert(
            abi.encodeWithSelector(ShieldedNotePool.DuplicateCommitment.selector, FirstCommitment)
        );
        vm.prank(Depositor);
        pool.deposit(commitments, amounts);

        vm.expectRevert(ShieldedNotePool.InvalidProof.selector);
        pool.withdraw("forged", FirstCommitment, Nullifier, Recipient, 40 ether);

        bytes memory proof = abi.encode(FirstCommitment, Nullifier, Recipient, uint128(40 ether));
        pool.withdraw(proof, FirstCommitment, Nullifier, Recipient, 40 ether);

        bytes memory replayProof =
            abi.encode(SecondCommitment, Nullifier, Recipient, uint128(40 ether));
        vm.expectRevert(
            abi.encodeWithSelector(ShieldedNotePool.NullifierAlreadyUsed.selector, Nullifier)
        );
        pool.withdraw(replayProof, SecondCommitment, Nullifier, Recipient, 40 ether);
    }
}
