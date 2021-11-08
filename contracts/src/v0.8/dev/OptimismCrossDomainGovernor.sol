// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/DelegateForwarderInterface.sol";
import "./vendor/@eth-optimism/contracts/0.4.7/contracts/optimistic-ethereum/iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";
import "./vendor/openzeppelin-solidity/v4.3.1/contracts/utils/Address.sol";
import "./OptimismCrossDomainForwarder.sol";

/**
 * @title OptimismCrossDomainGovernor - L1 xDomain account representation (with delegatecall support) for Optimism
 * @notice L2 Contract which receives messages from a specific L1 address and transparently forwards them to the destination.
 * @dev Any other L2 contract which uses this contract's address as a privileged position,
 *   can be considered to be owned by the `l1Owner`
 */
contract OptimismCrossDomainGovernor is DelegateForwarderInterface, OptimismCrossDomainForwarder {
  /**
   * @notice creates a new Optimism xDomain Forwarder contract
   * @param crossDomainMessengerAddr the xDomain bridge messenger (Optimism bridge L2) contract address
   * @param l1OwnerAddr the L1 owner address that will be allowed to call the forward fn
   */
  constructor(address crossDomainMessengerAddr, address l1OwnerAddr)
    OptimismCrossDomainForwarder(crossDomainMessengerAddr, l1OwnerAddr)
  {}

  /**
   * @notice versions:
   *
   * - OptimismCrossDomainForwarder 0.1.0: initial release
   *
   * @inheritdoc TypeAndVersionInterface
   */
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "OptimismCrossDomainGovernor 0.1.0";
  }

  /**
   * @dev forwarded only if L2 Messenger calls with `xDomainMessageSender` being the L1 owner address
   * @inheritdoc ForwarderInterface
   */
  function forward(address target, bytes memory data) external override onlyCrossDomainOwners {
    Address.functionCall(target, data, "Governor call reverted");
  }

  /**
   * @dev forwarded only if L2 Messenger calls with `xDomainMessageSender` being the L1 owner address
   * @inheritdoc DelegateForwarderInterface
   */
  function forwardDelegate(address target, bytes memory data) external override onlyCrossDomainOwners {
    Address.functionDelegateCall(target, data, "Governor delegatecall reverted");
  }

  /**
   * @notice The call MUST come from either the L1 owner (via cross-chain message) or the L2 owner. Reverts otherwise.
   */
  modifier onlyCrossDomainOwners() {
    // 1. The delegatecall MUST come from either the L1 owner (via cross-chain message) or the L2 owner
    require(msg.sender == crossDomainMessenger() || msg.sender == owner(), "Sender is not the L2 messenger or owner");
    // 2. The L2 Messenger's caller MUST be the L1 Owner
    if (msg.sender == crossDomainMessenger()) {
      require(
        iOVM_CrossDomainMessenger(crossDomainMessenger()).xDomainMessageSender() == l1Owner(),
        "xDomain sender is not the L1 owner"
      );
    }
    _;
  }
}