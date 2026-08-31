// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Replay-safe settlement for complementary off-chain signed outcome orders.
contract ClobSettlement is EIP712 {
    using SafeERC20 for IERC20;

    bytes32 public constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,uint256 tokenId,uint256 amount,uint256 price,uint256 nonce,uint64 expiry,bool isBuy)"
    );

    struct Order {
        address maker;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        uint256 nonce;
        uint64 expiry;
        bool isBuy;
    }

    IERC20 public immutable collateral;
    IERC1155 public immutable positions;
    address public immutable matcher;
    mapping(bytes32 orderHash => uint256 amount) public filled;
    mapping(address maker => mapping(uint256 nonce => bool cancelled)) public cancelled;

    error InvalidConfiguration();
    error Unauthorized(address caller);
    error InvalidMatch();
    error InvalidSignature();
    error OrderExpired();
    error Overfilled();

    event OrderCancelled(address indexed maker, uint256 indexed nonce);
    event MatchSettled(
        bytes32 indexed buyHash, bytes32 indexed sellHash, uint256 amount, uint256 price
    );

    constructor(IERC20 initialCollateral, IERC1155 initialPositions, address initialMatcher)
        EIP712("Sepehr CLOB", "1")
    {
        if (
            address(initialCollateral) == address(0) || address(initialPositions) == address(0)
                || initialMatcher == address(0)
        ) {
            revert InvalidConfiguration();
        }
        collateral = initialCollateral;
        positions = initialPositions;
        matcher = initialMatcher;
    }

    function cancel(uint256 nonce) external {
        cancelled[msg.sender][nonce] = true;
        emit OrderCancelled(msg.sender, nonce);
    }

    function settle(
        Order calldata buy,
        bytes calldata buySignature,
        Order calldata sell,
        bytes calldata sellSignature,
        uint256 amount,
        uint256 executionPrice
    ) external {
        if (msg.sender != matcher) {
            revert Unauthorized(msg.sender);
        }
        // forge-lint: disable-next-line(block-timestamp)
        if (buy.expiry < block.timestamp || sell.expiry < block.timestamp) {
            revert OrderExpired();
        }
        if (
            !buy.isBuy || sell.isBuy || buy.tokenId != sell.tokenId || buy.maker == sell.maker
                || amount == 0 || executionPrice > buy.price || executionPrice < sell.price
                || cancelled[buy.maker][buy.nonce] || cancelled[sell.maker][sell.nonce]
        ) {
            revert InvalidMatch();
        }

        bytes32 buyHash = hashOrder(buy);
        bytes32 sellHash = hashOrder(sell);
        if (
            ECDSA.recover(buyHash, buySignature) != buy.maker
                || ECDSA.recover(sellHash, sellSignature) != sell.maker
        ) {
            revert InvalidSignature();
        }
        if (filled[buyHash] + amount > buy.amount || filled[sellHash] + amount > sell.amount) {
            revert Overfilled();
        }

        filled[buyHash] += amount;
        filled[sellHash] += amount;
        collateral.safeTransferFrom(
            buy.maker, sell.maker, Math.mulDiv(amount, executionPrice, 1 ether)
        );
        positions.safeTransferFrom(sell.maker, buy.maker, sell.tokenId, amount, "");
        emit MatchSettled(buyHash, sellHash, amount, executionPrice);
    }

    function hashOrder(Order calldata order) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.tokenId,
                    order.amount,
                    order.price,
                    order.nonce,
                    order.expiry,
                    order.isBuy
                )
            )
        );
    }
}
