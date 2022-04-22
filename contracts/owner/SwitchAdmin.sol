// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./AdminRole.sol";

contract SwitchAdmin is AdminRole {
    using Address for address;

    uint8 public isPause;
    mapping(address => bool) public senderCtPermit;

    modifier isOpen() {
        require(isPause == 0, "Pause!");
        _;
    }

    modifier isPermit(address _acc) {
        if (_acc.isContract()){
            require(senderCtPermit[_acc], "Error!");
        }
        _;
    }

    function setPause(uint8 _isPause) public onlyAdmin {
        isPause = _isPause;
    }

    function setCtPermit(address _ctAcc, bool _isOk) public onlyAdmin {
        senderCtPermit[_ctAcc] = _isOk;
    }

}
