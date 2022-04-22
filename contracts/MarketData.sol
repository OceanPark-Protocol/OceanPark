//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./owner/AdminRole.sol";


contract MarketData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => mapping(address => uint256[2][])) public soldNFTRecords;
    mapping(address => EnumerableSet.UintSet) private sellNFTList;
    mapping(address => mapping(address => EnumerableSet.UintSet)) private accNFTList;
    mapping(address => mapping(uint256 => SellProd)) public prodNFTInfo;

    struct SellProd{
        uint256 price;
        address nftFrom;
    }

    // --------------hero--------------
    function getAccSoldNFTRecords(address _nftAddr, address _acc, uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _records)
    {
        uint256 _initV = _endIdx - _startIdx + 1;
        if (soldNFTRecords[_nftAddr][_acc].length < _startIdx + 1) {
            _initV = 0;
        } else if (soldNFTRecords[_nftAddr][_acc].length < _endIdx + 1 ) {
            _initV = soldNFTRecords[_nftAddr][_acc].length - _startIdx;
        }
        _records = new uint256[2][](_initV);
        _startIdx = soldNFTRecords[_nftAddr][_acc].length - _startIdx;
        for(uint256 i=0; i<_initV; i++ ){
            _records[i] = soldNFTRecords[_nftAddr][_acc][_startIdx - 1 - i];
        }
    }

    function getAccSellNFTList(address _nftAddr, address _acc)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = new uint256[2][](accNFTList[_nftAddr][_acc].length());
        for (uint256 i=0; i< accNFTList[_nftAddr][_acc].length(); i++){
            _nftList[i] = [accNFTList[_nftAddr][_acc].at(i), prodNFTInfo[_nftAddr][accNFTList[_nftAddr][_acc].at(i)].price];
        }
    }

    function getAllSellNFTList(address _nftAddr, uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startIdx >= sellNFTList[_nftAddr].length()) {
            _endIdx = _startIdx;
        }
        if (_endIdx > sellNFTList[_nftAddr].length()) {
            _endIdx = sellNFTList[_nftAddr].length();
        }
        _nftList = new uint256[2][](_endIdx - _startIdx);
        for(uint256 i=_startIdx; i<_endIdx; i++ ){
            uint256 _nftNo = sellNFTList[_nftAddr].at(i);
            _nftList[i - _startIdx] = [_nftNo, prodNFTInfo[_nftAddr][_nftNo].price];
        }
    }

    function getSellNFTInfo(address _nftAddr, uint256 _nftNo)
        public view
        returns (bool, uint256, address)
    {   // 是否在卖，价格，出售人
        return (sellNFTList[_nftAddr].contains(_nftNo), prodNFTInfo[_nftAddr][_nftNo].price, prodNFTInfo[_nftAddr][_nftNo].nftFrom);
    }

    function addSellNFT(address _nftAddr, address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        sellNFTList[_nftAddr].add(_nftNo);
        accNFTList[_nftAddr][_acc].add(_nftNo);
        prodNFTInfo[_nftAddr][_nftNo] = SellProd({
            price: _price,
            nftFrom: _acc
        });
    }

    function cancelSellNFT(address _nftAddr, address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        sellNFTList[_nftAddr].remove(_nftNo);
        accNFTList[_nftAddr][_acc].remove(_nftNo);
        delete prodNFTInfo[_nftAddr][_nftNo];
    }

    function buySellNFT(address _nftAddr, uint256 _nftNo)
        public onlyAdmin
    {
        soldNFTRecords[_nftAddr][prodNFTInfo[_nftAddr][_nftNo].nftFrom].push([_nftNo, prodNFTInfo[_nftAddr][_nftNo].price]);
        sellNFTList[_nftAddr].remove(_nftNo);
        accNFTList[_nftAddr][prodNFTInfo[_nftAddr][_nftNo].nftFrom].remove(_nftNo);
        delete prodNFTInfo[_nftAddr][_nftNo];
    }

    function accNFTContains(address _nftAddr, address _acc, uint256 _nftNo)
        public view
        returns (bool)
    {
        return accNFTList[_nftAddr][_acc].contains(_nftNo);
    }

    function accNFTAt(address _nftAddr, address _acc, uint256 _index)
        public view
        returns (uint256)
    {
        return accNFTList[_nftAddr][_acc].at(_index);
    }

    function accNFTListLength(address _nftAddr, address _acc)
        public view
        returns (uint256)
    {
        return accNFTList[_nftAddr][_acc].length();
    }

    function allNFTsContains(address _nftAddr, uint256 _nftNo)
        public view
        returns (bool)
    {
        return sellNFTList[_nftAddr].contains(_nftNo);
    }

    function allNFTsAt(address _nftAddr, uint256 _index)
        public view
        returns (uint256)
    {
        return sellNFTList[_nftAddr].at(_index);
    }

    function allNFTsLength(address _nftAddr)
        public view
        returns (uint256)
    {
        return sellNFTList[_nftAddr].length();
    }

    // operate
    function addAccNFT(address _nftAddr, address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accNFTList[_nftAddr][_acc].add(_nftNo);
    }

    function removeAccNFT(address _nftAddr, address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accNFTList[_nftAddr][_acc].remove(_nftNo);
    }

    function addAllNFTs(address _nftAddr, uint256 _nftNo)
        public onlyAdmin
    {
        sellNFTList[_nftAddr].add(_nftNo);
    }

    function removeAllNFTs(address _nftAddr, uint256 _nftNo)
        public onlyAdmin
    {
        sellNFTList[_nftAddr].remove(_nftNo);
    }

    function setProdNFTInfo(address _nftAddr, address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        prodNFTInfo[_nftAddr][_nftNo] = SellProd({price: _price, nftFrom: _acc});
    }

}
