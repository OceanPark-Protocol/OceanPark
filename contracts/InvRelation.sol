//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./owner/BaseOp.sol";

interface IData {

    function getBindAcc(address _acc) external view returns (address);
    function getBeinvList(address _acc) external view returns (address[] memory _beInvited);
    function beinvLength(address _acc) external view returns (uint256);

    function addBindAcc(address _acc, address _bindAcc) external;
    function removeBindAcc(address _acc) external;
}

contract InvRelation is BaseOp {
    IData public dataObj;

    event BindAccEvent(address indexed user, address acc);

    constructor(
        IData dataObj_
    ){
        dataObj = dataObj_;
    }

    function getBindAcc(address _acc)
        public view
        returns (address)
    {
        return dataObj.getBindAcc(_acc);
    }

    function getBeinvNum(address _acc)
        public view
        returns (uint256)
    {
        return dataObj.beinvLength(_acc);
    }

    function bindAcc(address _bindAcc)
        public isOpen
    {
        require (_bindAcc != msg.sender, "Param error");
        require (dataObj.getBindAcc(msg.sender) == address(0), "It's already bound");

        // bind
        dataObj.addBindAcc(msg.sender, _bindAcc);

        emit BindAccEvent(msg.sender, _bindAcc);
    }

    // admin
    function setDataObj(address _addr) public onlyAdmin {
        dataObj = IData(_addr);
    }


}
