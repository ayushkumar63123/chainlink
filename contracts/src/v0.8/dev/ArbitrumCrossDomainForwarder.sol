// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/TypeAndVersionInterface.sol";
import "./vendor/arb-bridge-eth/v0.8.0-custom/contracts/libraries/AddressAliasHelper.sol";
import "./vendor/openzeppelin-solidity/v4.3.1/contracts/utils/Address.sol";
import "./CrossDomainForwarder.sol";

/**
 * @title ArbitrumCrossDomainForwarder - L1 xDomain account representation
 * @notice L2 Contract which receives messages from a specific L1 address and transparently forwards them to the destination.
 * @dev Any other L2 contract which uses this contract's address as a privileged position,
 *   can be considered to be owned by the `l1Owner`
 */
contract ArbitrumCrossDomainForwarder is TypeAndVersionInterface, CrossDomainForwarder {
  /**
   * @notice creates a new Arbitrum xDomain Forwarder contract
   * @param l1OwnerAddr the L1 owner address that will be allowed to call the forward fn
   */
  constructor(address l1OwnerAddr) CrossDomainForwarder(l1OwnerAddr) {}

  /**
   * @notice versions:
   *
   * - ArbitrumCrossDomainForwarder 0.1.0: initial release
   * - ArbitrumCrossDomainForwarder 0.2.0: Use OZ Address, CrossDomainOwnable
   *
   * @inheritdoc TypeAndVersionInterface
   */
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "ArbitrumCrossDomainForwarder 0.2.0";
  }

  /**
   * @notice The L2 xDomain `msg.sender`, generated from L1 sender address
   */
  function crossDomainMessenger() public view returns (address) {
    return AddressAliasHelper.applyL1ToL2Alias(l1Owner());
  }

  /**
   * @notice transfer ownership of this account to a new L1 owner
   * @param to new L1 owner that will be allowed to call the forward fn
   */
  function transferL1Ownership(address to) external override onlyCrossDomainMessenger {
    super._transferL1Ownership(to);
  }

  /**
   * @notice accept ownership of this account to a new L1 owner
   */
  function acceptL1Ownership() external virtual override {
    require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(s_l1PendingOwner), "Must be proposed owner");
    super._setL1Owner(s_l1PendingOwner);
  }

  /**
   * @dev forwarded only if L2 Messenger calls with `xDomainMessageSender` beeing the L1 owner address
   * @inheritdoc ForwarderInterface
   */
  function forward(address target, bytes memory data) external virtual override onlyCrossDomainMessenger {
    Address.functionCall(target, data, "Forwarder call reverted");
  }

  /**
   * @notice The call MUST come from the L1 owner (via cross-chain message.) Reverts otherwise.
   */
  modifier onlyCrossDomainMessenger() {
    require(msg.sender == crossDomainMessenger(), "Sender is not the L2 messenger");
    _;
  }
}