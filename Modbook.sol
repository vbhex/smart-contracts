// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IEscrow.sol";
import "./IModbook.sol";

contract Modbook is IModbook,Ownable {
    using SafeMath for uint256;
    // max supply
    uint256 public maxSupply = 4000000; 

    // total supply
    uint256 public _totalSupply;

    // ERC721 NFT struct
    struct NFT {
        address contractAddress;
        uint256 tokenId;
    }
    // modId => NFT mapping
    mapping(uint256 => NFT) public modNFT;

    // mod's total score
    mapping(uint256 => uint256) public modTotalScore;

    // mod's success score
    mapping(uint256 => uint256) public modSuccessScore;

    // mod's success rate
    mapping(uint256 => uint8) public modSuccessRate;

    // mint event
    event Mint(
        uint256 indexed modId
    );

    // update score event
    event UpdateScore(
        uint256 indexed modId,
        bool indexed ifSuccess
    );

    // escrow contract address
    address payable public escrowAddress;

    constructor()  {
        _totalSupply = 0;
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    // set escrow contract address
    function setEscrow(address payable _escrow) public onlyOwner {
        IEscrow EscrowContract = IEscrow(_escrow);
        require(EscrowContract.getModAddress()==address(this),'Mod: wrong escrow contract address');
        escrowAddress = _escrow; 
    }

    // mint a new mod
    function mint(address nftContractAddress, uint256 nftId) public onlyOwner {
        uint256 modId                     = totalSupply().add(1);
        require(modId <= maxSupply, 'Mod: supply reach the max limit!');
        // build modNFT mapping
        NFT memory _nft;
        _nft.contractAddress = nftContractAddress;
        _nft.tokenId         =  nftId;
        modNFT[modId]   =   _nft;
        // set default mod score
        modTotalScore[modId]   =   1;  
        // total supply add 1
        _totalSupply = modId;
        // emit mint event
        emit Mint(
            modId
        );
    }

    // get mod's total supply
    function getMaxModId() external view override returns(uint256) {
        return totalSupply();
    }

    // get mod's owner
    function getModOwner(uint256 modId) external view override returns(address) {
        require(modId <= totalSupply(),'Mod: illegal moderator ID!');
        IERC721 nft = IERC721(modNFT[modId].contractAddress);
        return nft.ownerOf(modNFT[modId].tokenId);
    }

    // update mod's score
    function updateModScore(uint256 modId, bool ifSuccess) external override returns(bool) {
        //Only Escrow contract can increase score
        require(escrowAddress == msg.sender,'Mod: only escrow contract can update mod score');
        //total score add 1
        modTotalScore[modId] = modTotalScore[modId].add(1);
        if(ifSuccess) {
            // success score add 1
            modSuccessScore[modId] = modSuccessScore[modId].add(1);
        } else if(modSuccessScore[modId] > 0) {
            modSuccessScore[modId] = modSuccessScore[modId].sub(1);
        } else {
            // nothing changed
        }
        // recount mod success rate
        modSuccessRate[modId] = uint8(modSuccessScore[modId].mul(100).div(modTotalScore[modId]));
        // emit event
        emit UpdateScore(
            modId,
            ifSuccess
        );
        return true;

    }

}