//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./owner/BaseOp.sol";


interface IData {
    function getSellNFTInfo(address _nftAddr, uint256 _nftNo) external view returns (bool, uint256, address);
    function getAccSoldNFTRecords(address _nftAddr, address _acc, uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _records);
    function getAccSellNFTList(address _nftAddr, address _acc) external view returns (uint256[2][] memory _nftList);
    function getAllSellNFTList(address _nftAddr, uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _nftList);
    function allNFTsLength(address _nftAddr) external view returns (uint256);

    function addSellNFT(address _nftAddr, address _acc, uint256 _nftNo, uint256 _price) external;
    function cancelSellNFT(address _nftAddr, address _acc, uint256 _nftNo) external;
    function buySellNFT(address _nftAddr, uint256 _nftNo) external;

}

interface INFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}


contract Market is BaseOp, ERC721Holder {
    using SafeERC20 for IBurnERC20;

    IData public dataObj;
    IBurnERC20 public payToken;

    mapping(address => uint32) public sellFeeRate;
    mapping(address => address) public sellFeeAddr;
    mapping(address => bool) public nftOpSwitch;

    event SellNFTEvent(address indexed user, address _nftAddr, uint256 nftNo, uint256 price);
    event CancelSellNFTEvent(address indexed user, address _nftAddr, uint256 nftNo);
    event BuyNFTEvent(address indexed user, address _nftAddr, uint256 nftNo);

    constructor(
        IData dataObj_,
        IBurnERC20 payToken_,
        address[] memory nftAddrList_
    ){
        dataObj = dataObj_;
        payToken = payToken_;

        for(uint256 i=0;i<nftAddrList_.length;i++){
            nftOpSwitch[nftAddrList_[i]] = true;
            sellFeeRate[nftAddrList_[i]] = 5;
        }
    }

    modifier isNFTOpState(address _nftAddr) {
        require(nftOpSwitch[_nftAddr] == true, "Stop!");
        _;
    }

    function getSoldNFTRecords(address _nftAddr, address _acc)
        public view
        returns (uint256[2][] memory _records)
    {
        return dataObj.getAccSoldNFTRecords(_nftAddr, _acc, 0, 50);
    }

    function getAccSellNFTList(address _nftAddr, address _acc)
        public view
        returns (uint256[2][] memory _nftsList)
    {
        _nftsList = dataObj.getAccSellNFTList(_nftAddr, _acc);
    }

    function getAllSellNFTList(address _nftAddr, uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = dataObj.getAllSellNFTList(_nftAddr, _startIdx, _endIdx);
    }

    function getAllSellNFTsLength(address _nftAddr)
        public view
        returns (uint256)
    {
        return dataObj.allNFTsLength(_nftAddr);
    }

    function sellNFT(address _nftAddr, uint256 _nftNo, uint256 _price)
        public isOpen isNFTOpState(_nftAddr) isPermit(msg.sender)
    {
        require(_price > 0, "Price error");
        address _nftAcc = INFTCard(_nftAddr).ownerOf(_nftNo);
        require (_nftAcc == msg.sender, "NFTNFT tokenId error");
        // 卖多少钱
        dataObj.addSellNFT(_nftAddr, msg.sender, _nftNo, _price);

        INFTCard(_nftAddr).safeTransferFrom(msg.sender, address(this), _nftNo);

        emit SellNFTEvent(msg.sender, _nftAddr, _nftNo, _price);
    }

    function cancelSellNFT(address _nftAddr, uint256 _nftNo)
        public isOpen isNFTOpState(_nftAddr) isPermit(msg.sender)
    {
        (bool _exist, , address _nftFrom) = dataObj.getSellNFTInfo(_nftAddr, _nftNo);
        require(_exist && _nftFrom == msg.sender, "Param error");

        dataObj.cancelSellNFT(_nftAddr, msg.sender, _nftNo);
        INFTCard(_nftAddr).safeTransferFrom(address(this), msg.sender, _nftNo);

        emit CancelSellNFTEvent(msg.sender, _nftAddr, _nftNo);
    }

    function buyNFT(address _nftAddr, uint256 _nftNo)
        public isOpen isNFTOpState(_nftAddr) isPermit(msg.sender)
    {
        (bool _exist, uint256 _price, address _nftFrom) = dataObj.getSellNFTInfo(_nftAddr, _nftNo);
        require(_exist, "It's sold out");
        require(_nftFrom != msg.sender, "It's yours");

        dataObj.buySellNFT(_nftAddr, _nftNo);
        // 转钱
        uint256 _feeV = _price * sellFeeRate[_nftAddr] / 100;
        if (_feeV > 0) {
            if (sellFeeAddr[_nftAddr] == address(0)){ payToken.burnFrom(msg.sender, _feeV); }
            else { payToken.safeTransferFrom(msg.sender, sellFeeAddr[_nftAddr], _feeV); }
        }
        payToken.safeTransferFrom(msg.sender, _nftFrom, _price-_feeV);

        INFTCard(_nftAddr).safeTransferFrom(address(this), msg.sender, _nftNo);

        emit BuyNFTEvent(msg.sender, _nftAddr, _nftNo);
    }

    // admin
    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("payToken")) {
            payToken = IBurnERC20(_addr);
        }
    }

    function setSellFee(address[] memory _addrsList, uint32[] memory _rateList, address[] memory _feeAddrList) public onlyAdmin {
        for (uint256 i = 0; i < _addrsList.length; i++) {
            sellFeeRate[_addrsList[i]] = _rateList[i];
            sellFeeAddr[_addrsList[i]] = _feeAddrList[i];
        }
    }

    function setNFTOpSwitch(address[] memory _addrsList, bool[] memory _valueList) public onlyAdmin {
        for (uint256 i = 0; i < _addrsList.length; i++) {
            nftOpSwitch[_addrsList[i]] = _valueList[i];
        }
    }

}
