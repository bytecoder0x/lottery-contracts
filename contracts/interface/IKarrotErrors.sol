// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IKarrotErrors {
    error IncorrectValue(string message);
    error IncorrectCondition(string message);
    error ActionPerformed(string message);
    error InterfaceNotSupported();
}