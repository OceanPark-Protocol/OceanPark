//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./owner/AdminRole.sol";


contract MysteryData is AdminRole {
    uint256[] private _codePool;
    mapping(uint32 => uint8) private _codeDict;

    function _getCode(uint8[] memory _cList)
        private view
        returns (uint32 code, uint32 codeIdx, uint32 poolCode)
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
        poolCode = uint32((_codePool[codeIdx/8] >> (codeIdx % 8 * 32)) & (~(~0<<32)));
    }

    function _getPoolCode(uint32 codeIdx)
        private view
        returns (uint32 poolCode)
    {
        poolCode = uint32((_codePool[codeIdx/8] >> (codeIdx % 8 * 32)) & (~(~0<<32)));
    }

    function getPoolCode(uint32 codeIdx)
        public view onlyAdmin
        returns (uint32 poolCode)
    {
        poolCode = _getPoolCode(codeIdx);
    }

    function getCode(uint8[] memory _cList)
        public view onlyAdmin
        returns (uint32 code, uint32 codeIdx, uint32 poolCode)
    {
        return _getCode(_cList);
    }

    function getCode1(uint8[] memory _cList)
        public onlyAdmin view
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
    }

    function getCode2(uint32 codeIdx)
        public onlyAdmin view
        returns (uint32 poolCode)
    {
        poolCode = uint32((_codePool[codeIdx/8] << (codeIdx % 8 * 32)) & (~(~0<<32)));
    }

    function getCodeUseInfo(uint32 code, uint32 _codeIdx)
        public view onlyAdmin
        returns (bool, bool)
    {
        uint32 poolCode = _getPoolCode(_codeIdx);
        return (code == poolCode, _codeDict[code] == 0);
    }

    function useCode(uint32 _code)
        public onlyAdmin
    {
        _codeDict[_code] = 1;
    }

    function getCodeInfo(uint32[] memory _codeList)
        public onlyAdmin view
        returns (uint8[] memory _infoList)
    {
        _infoList = new uint8[](_codeList.length);
        for(uint256 i=0;i<_codeList.length;i++){
            _infoList[i] = _codeDict[_codeList[i]];
        }
    }

    function getCodePool(uint32[] memory _idxList)
        public onlyAdmin view
        returns (uint256[] memory _infoList)
    {
        _infoList = new uint256[](_idxList.length);
        for(uint256 i=0;i<_idxList.length;i++){
            _infoList[i] = _codePool[_idxList[i]];
        }
    }

    function addCodePool(uint256[] memory _codeP)
        public onlyAdmin
    {
        for(uint256 i=0;i<_codeP.length;i++){
            _codePool.push(_codeP[i]);
        }
    }

    function setCodePool(uint32[] memory _idxList, uint256[] memory _codeP)
        public onlyAdmin
    {
        for(uint256 i=0;i<_idxList.length;i++){
            _codePool[_idxList[i]] = _codeP[i];
        }
    }

    function setCodeDict(uint32[2][] memory _codeInfo)
        public onlyAdmin
    {
        for(uint256 i=0;i<_codeInfo.length;i++){
            _codeDict[_codeInfo[i][0]] = uint8(_codeInfo[i][1]);
        }
    }

}
