//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./owner/BaseOp.sol";


interface IGNFTCard {
    function mintNFT(address _to, uint128 _nftProp, uint8 _nftType) external returns (uint256);
}

interface IRandom {
    function getRandomHInt() external returns (uint16 value);
    function getRandomMultiHInt(uint32 _num) external returns (uint16[] memory valueList);
    function getRandomRangeInt(uint16 _leftV, uint16 _rightV) external returns (uint16 value);
}

interface IData {
    function getCodeUseInfo(uint32 code, uint32 _codeIdx) external view returns (bool, bool);

    function useCode(uint32 _code) external;
}

contract MysteryBox is BaseOp {
    using SafeERC20 for IBurnERC20;

    IData public dataObj;
    IGNFTCard public nftCard;
    IBurnERC20 public coralToken;
    IBurnERC20 public algaToken;
    IRandom public randomObj;

    uint8[3] public typeRates = [80, 15, 5];
    uint16[2] public algaRange = [21, 100];
    uint16[2] public coralRange = [1, 5];

    uint8 public immutable maxProp = 80;
    uint8[5] public nftTypeList = [0, 1, 2, 3, 4];

    uint256[3] public openedNum = [0, 0, 0];

    event OpenBoxEvent(address indexed user, uint8 boxType, uint256 value);

    constructor(IData dataObj_, IGNFTCard nftCard_, IBurnERC20 coralToken_, IBurnERC20 algaToken_, IRandom randomObj_){
        dataObj = dataObj_;
        nftCard = nftCard_;
        coralToken = coralToken_;
        algaToken = algaToken_;
        randomObj = randomObj_;

    }

    function _getHeroProps()
        private
        returns (uint64 _propV, uint8 _nftType)
    {
        uint16[] memory randomVList = randomObj.getRandomMultiHInt(6);
        _propV = 0;
        uint64 _propVT = 0;
        for(uint64 i=0;i<5;i++){
            uint64 _value = uint64(randomVList[i]) * maxProp / 100;
            _propV += uint64(_value << (32 - i*8));
            _propVT += _value;
        }
        _propV += (_propVT << 40);
        _nftType = nftTypeList[uint64(randomVList[5])%nftTypeList.length];
    }

    function _getCode(uint8[] memory _cList)
        private pure
        returns (uint32 code, uint32 codeIdx)
    {
        code = 0;
        codeIdx = 0;
        for(uint32 i=0;i<_cList.length;i++){
            if (i>=4){
                code += uint32(uint32(_cList[i]) << ((i-4)*5));
            } else {
                codeIdx += uint32(uint32(_cList[i]) << (i*5));
            }
        }
        codeIdx -= 100000;
    }

    function getCode(uint8[] memory _cList)
        public pure
        returns (uint32 code, uint32 codeIdx)
    {
        return _getCode(_cList);
    }

    function openBox(uint8[] memory _codeList)
        public isOpen
    {
        (uint32 code, uint32 codeIdx) = _getCode(_codeList);
        (bool isRealCode, bool isNoUsed) = dataObj.getCodeUseInfo(code, codeIdx);
        require (isRealCode, "Code error");
        require (isNoUsed, "Code is used");

        dataObj.useCode(code);
        uint8 _type = _getBoxType();

        uint256 _value = 0;
        if (_type == 1){
            _value = uint256(randomObj.getRandomRangeInt(algaRange[0], algaRange[1])) * 1e18;
            algaToken.safeTransfer(msg.sender, _value);
        } else if (_type == 2){
            _value = uint256(randomObj.getRandomRangeInt(coralRange[0], coralRange[1])) * 1e18;
            coralToken.safeTransfer(msg.sender, _value);
        } else {
            (uint64 _propV, uint8 _nftType) = _getHeroProps();
            _value = nftCard.mintNFT(msg.sender, _propV, _nftType);
        }
        openedNum[_type] += 1;

        emit OpenBoxEvent(msg.sender, _type, _value);
    }

    function _getBoxType()
        private
        returns (uint8)
    {
        uint16 randV = randomObj.getRandomHInt();
        uint8 _type = 0;
        for(uint8 i=0;i<typeRates.length;i++){
            if (randV <= typeRates[i]){
                _type = i;
                break;
            }
            randV -= typeRates[i];
        }
        return _type;
    }

    // admin
    function setTypeRates(uint8[2][] memory _typeRList, uint16[2][] memory _algaRangeList, uint16[2][] memory _coralRangeList)
        public onlyAdmin
    {
        for(uint256 i=0;i<_typeRList.length;i++){
            typeRates[_typeRList[i][0]] = _typeRList[i][1];
        }
        for(uint256 i=0;i<_algaRangeList.length;i++){
            algaRange[_algaRangeList[i][0]] = _algaRangeList[i][1];
        }
        for(uint256 i=0;i<_coralRangeList.length;i++){
            coralRange[_coralRangeList[i][0]] = _coralRangeList[i][1];
        }
    }

    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("coralToken")) {
            coralToken = IBurnERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("algaToken")) {
            algaToken = IBurnERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("nftCard")) {
            nftCard = IGNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("randomObj")) {
            randomObj = IRandom(_addr);
        }
    }


}
