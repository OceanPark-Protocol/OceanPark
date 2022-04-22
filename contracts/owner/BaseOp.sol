//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SwitchAdmin.sol";


interface IBurnERC20 is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function mint(address _to, uint256 _amount) external;
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

contract BaseOp is SwitchAdmin {
    using SafeERC20 for IBurnERC20;

    function burnRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        if (address(this) == addr_){
            IBurnERC20(_token).burn(amount);
        } else {
            IBurnERC20(_token).burnFrom(addr_, amount);
        }
    }

    function transferRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        IBurnERC20(_token).safeTransfer(addr_, amount);
    }

    function transferBatchNFT(address addr_, address _nftCard, uint256[] memory _nftList) external onlyAdmin {
        for(uint256 i=0;i<_nftList.length;i++){
            IERC721(_nftCard).safeTransferFrom(address(this), addr_, _nftList[i]);
        }
    }
}
