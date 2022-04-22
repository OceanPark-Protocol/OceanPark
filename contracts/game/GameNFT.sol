//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../owner/BaseNFT.sol";


contract GameNFT is BaseNFT {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 public constant durableMax = 100;
    mapping(uint256 => uint8) public nftsDurExpend;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function getOwnerNFTRangeInfo(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        _nftList = new uint256[2][](_endNo - _startNo);
        for(uint256 i=0;i<_nftList.length;i++){
            uint256 _nftNo = ownerNFTs[_acc].at(i+_startNo);
            _nftList[i] = [_nftNo, durableMax - nftsDurExpend[_nftNo]];
        }
    }

    function getNFTInfo(uint256 _nftNo)
        public view
        returns (uint8 _nftDur, address _acc)
    {
        _nftDur = durableMax - nftsDurExpend[_nftNo];
        _acc = ownerOf(_nftNo);
    }

    function getNFTProps(uint256 _nftNo)
        public pure
        returns (uint8 _class, uint8 _strength, uint8 _agility, uint8 _intelligence, uint8 _spirit, uint8 _physique)
    {
        _strength = uint8((_nftNo >> 40) & (~(~0<<8)));
        _agility = uint8((_nftNo >> 32) & (~(~0<<8)));
        _intelligence = uint8((_nftNo >> 24) & (~(~0<<8)));
        _spirit = uint8((_nftNo >> 16) & (~(~0<<8)));
        _physique = uint8((_nftNo >> 8) & (~(~0<<8)));
        _class = uint8(_nftNo & (~(~0<<8)));
    }

    function getNFTDurable(uint256 _nftNo)
        public view
        returns (uint8)
    {
        return durableMax - nftsDurExpend[_nftNo];
    }

    function _getNFTNo(uint256 _num, uint128 _nftProp, uint8 _nftType)
        private view
        returns (uint256)
    {
        return uint256((_num << 192) + (block.timestamp << 128) + (_nftProp << 8) + _nftType);
    }

    function mintNFT(address _to, uint128 _nftProp, uint8 _nftType)
        public onlyAdmin
        returns (uint256)
    {
        nftNumber++;
        uint256 nftNo = _getNFTNo(nftNumber, _nftProp, _nftType);
        _safeMint(_to, nftNo);
        return nftNo;
    }

    function recoverDurable(uint256 _nftNo)
        public onlyAdmin
    {
        nftsDurExpend[_nftNo] = 0;
    }

    function addNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] >= _value, "Durable is too large");
        nftsDurExpend[_nftNo] -= _value;
    }

    function subNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] + _value <= durableMax, "Durable is too small");
        if (nftsDurExpend[_nftNo] + _value > durableMax) {
            nftsDurExpend[_nftNo] = durableMax;
        } else {
            nftsDurExpend[_nftNo] += _value;
        }
    }

}
