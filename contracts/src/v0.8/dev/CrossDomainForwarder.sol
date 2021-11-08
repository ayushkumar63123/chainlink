// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CrossDomainOwnable.sol";
import "./interfaces/ForwarderInterface.sol";

/**
 * @title CrossDomainForwarder - L1 xDomain account representation
 * @notice L2 Contract which receives messages from a specific L1 address and transparently forwards them to the destination.
 * @dev Any other L2 contract which uses this contract's address as a privileged position,
 *   can consider that position to be held by the `l1Owner`
 */
abstract contract CrossDomainForwarder is ForwarderInterface, CrossDomainOwnable {
  /**
   * @notice creates a new xDomain Forwarder contract
   * @dev Forwarding can be disabled by setting the L1 owner as `address(0)`.
   * @param l1OwnerAddr the L1 owner address that will be allowed to call the forward fn
   */
  constructor(address l1OwnerAddr) CrossDomainOwnable(l1OwnerAddr) {}
}