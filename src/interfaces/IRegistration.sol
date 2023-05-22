// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistration {
    function isRegistered(address _user) external view returns (bool);

    function getReferrerAddresses(
        address _userAddress
    ) external view returns (address[] memory referrerAddresses);
}
