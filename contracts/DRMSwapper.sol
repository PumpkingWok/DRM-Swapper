//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/introspection/IERC165.sol";


contract DRMSwapper {
    IERC1155 public NFTContract;
    
    struct Swap {
        address creator;
        uint256[] fromTokensId;
        uint256[] fromAmounts;
        uint256[] toTokensId;
        uint256[] toAmounts;
        address reservedFor;
    }

    mapping (uint256 => Swap) swaps;
    uint256 swapId;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    
    event ProposeSwap(
        address indexed creator, 
        uint256[] fromTokensId,
        uint256[] fromAmounts,
        uint256[] toTokensId,
        uint256[] toAmounts,
        address reservedFor,
        uint256 swapId
    );

    event DeleteSwap(
        address indexed creator, 
        uint256 swapId
    );

    event AcceptSwap(
        address indexed creator, 
        address indexed accepter, 
        uint256 swapId
    );

    event MakeSwapPublic(address indexed creator, uint256 swapId);
    event MakeSwapReserved(address indexed creator, address indexed reserveFor, uint256 swapId);

    modifier checkReservedFor(uint256 _swapId) {
        address reservedFor = swaps[_swapId].reservedFor;
        if (reservedFor != address(0)) {
            require(reservedFor == msg.sender);
        }
        _;
    }
    
    constructor(address _address) {
        if (!IERC165(_address).supportsInterface(_INTERFACE_ID_ERC1155)) {
            revert();
        }
        NFTContract = IERC1155(_address);
    }

    /**
     * @notice function to set approval for all 
     */
    function setApprovalForAll(bool _approved) external {
        NFTContract.setApprovalForAll(address(this), _approved);
    }
    
    /**
     * @notice propose a reserved swap 
     */
    function proposeSwapReserved(
        uint256[] memory fromTokensId,
        uint256[] memory fromAmounts,
        uint256[] memory toTokensId,
        uint256[] memory toAmounts,
        address reservedFor
        ) external {
        _proposeSwap(fromTokensId, fromAmounts, toTokensId, toAmounts, reservedFor);
    }

    /**
     * @notice propose a swap  
     */
    function proposeSwap(
        uint256[] memory fromTokensId, 
        uint256[] memory fromAmounts, 
        uint256[] memory toTokensId, 
        uint256[] memory toAmounts
        ) external {
        _proposeSwap(fromTokensId, fromAmounts, toTokensId, toAmounts, address(0));
    }
    
    /**
     * @notice propose a swap internal function 
     */
    function _proposeSwap(
        uint256[] memory fromTokensId,
        uint256[] memory fromAmounts,
        uint256[] memory toTokensId,
        uint256[] memory toAmounts, 
        address reservedFor
        ) internal {
            require(fromTokensId.length == fromAmounts.length);
            require(toTokensId.length == toAmounts.length);
            
            Swap memory swap = Swap(msg.sender, fromTokensId, fromAmounts, toTokensId, toAmounts, reservedFor);
            swapId = swapId + 1;
            swaps[swapId] = swap;
            emit ProposeSwap(msg.sender, fromTokensId, fromAmounts, toTokensId, toAmounts, reservedFor, swapId);
    }
    
    /**
     * @notice delete swap proposed   
     */
    function deleteSwap(uint256 _swapId) external {
        require(swaps[_swapId].creator == msg.sender, "Only swap creator can delete it");
        delete swaps[_swapId];
        emit DeleteSwap(msg.sender, _swapId);
    }

    /**
     * @notice reserve swap to  
     */
    function reserveSwapTo(uint256 _swapId, address _reservedFor) external {
        require(swaps[_swapId].creator == msg.sender, "Only swap creator can reserve it");
        swaps[_swapId].reservedFor = _reservedFor;
        if (address(0) == _reservedFor) {
            emit MakeSwapPublic(msg.sender, _swapId);
        } else {
            emit MakeSwapReserved(msg.sender, _reservedFor, _swapId);
        }
    }
    
    /**
     * @notice accept swap in batch proposed  
     */
    function acceptSwap(uint256 _swapId) external checkReservedFor(_swapId) {
        if (swaps[_swapId].toTokensId.length == 1) {
            NFTContract.safeTransferFrom(msg.sender, swaps[_swapId].creator, swaps[_swapId].toTokensId[0], swaps[_swapId].toAmounts[0], "");
        } else {
            NFTContract.safeBatchTransferFrom(msg.sender, swaps[_swapId].creator, swaps[_swapId].toTokensId, swaps[_swapId].toAmounts, ""); 
        }
        if (swaps[_swapId].fromTokensId.length == 1) {
            NFTContract.safeTransferFrom(swaps[_swapId].creator, msg.sender, swaps[_swapId].fromTokensId[0], swaps[_swapId].toAmounts[0], "");
        } else {
            NFTContract.safeBatchTransferFrom(swaps[_swapId].creator, msg.sender, swaps[_swapId].fromTokensId, swaps[_swapId].toAmounts, "");
        }
        emit AcceptSwap(swaps[_swapId].creator, msg.sender, _swapId);
        //delete swaps[_swapId];
    }
    
    /**
     * @notice check if swap is still valid  
     */
    function swapIsStillValid(uint256 _swapId) public view returns(bool) {
       uint256[] memory fromTokensId = swaps[_swapId].fromTokensId;
       uint256[] memory fromAmounts = swaps[_swapId].fromAmounts;
       bool valid = true;
        for (uint256 i = 0; i < fromTokensId.length; i++) {
           if(NFTContract.balanceOf(msg.sender, fromTokensId[i]) < fromAmounts[i]) {
               valid = false;
           } 
        }
       return valid;
    }

    /**
     * @notice check if swap can be accepted
     */
    function swapCanBeAccepted(address _accepter, uint256 _swapId) public view returns(bool) {
        uint256[] memory toTokensId = swaps[_swapId].toTokensId;
        uint256[] memory toAmounts = swaps[_swapId].toAmounts;
        bool accepted = true;
        for (uint256 i = 0; i < toTokensId.length; i++) {
           if(NFTContract.balanceOf(_accepter, toTokensId[i]) < toAmounts[i]) {
               accepted = false;
           } 
        }
       return accepted;
    }

    /**
     * @notice check if swap could be concluded
     */
    function swapWillBeConclude(address _accepter, uint256 _swapId) external view returns(bool) {
        return swapIsStillValid(_swapId) && swapCanBeAccepted(_accepter, _swapId);
    }

    /**
     * @notice get swap data given a swapId
     */
    function getSwap(uint256 _swapId) external view returns(Swap memory) {
        return swaps[_swapId];
    }
}