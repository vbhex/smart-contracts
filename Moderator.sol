// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IEscrow.sol";
import "./IModerator.sol";
import "./opensea/ERC721Tradable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Moderator is IModerator, ERC721Tradable {
    using SafeMath for uint256;
    // max supply
    uint256 public maxSupply = 140000;

    // mod's total score
    mapping(uint256 => uint256) public modTotalScore;

    // mod's success score
    mapping(uint256 => uint256) public modSuccessScore;

    // mod's success rate
    mapping(uint256 => uint8) public modSuccessRate;

    // mint event
    event Mint(uint256 indexed modId);

    // update score event
    event UpdateScore(uint256 indexed modId, bool indexed ifSuccess);

    // escrow contract address
    address payable public escrowAddress;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Vbhex Moderator", "MOD", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure override returns (string memory) {
        return "https://savechives.com/rest/V1/vc/mod/id/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://savechives.com/rest/V1/vc/mod/contract/info";
    }

    /**
     * @dev Returns an URI for a given token ID
     */
    // function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
    //     return Strings.strConcat(baseTokenURI(), Strings.toString(_tokenId));
    // }

    // set escrow contract address
    function setEscrow(address payable _escrow) public onlyOwner {
        IEscrow EscrowContract = IEscrow(_escrow);
        require(
            EscrowContract.getModAddress() == address(this),
            "Mod: wrong escrow contract address"
        );
        escrowAddress = _escrow;
    }

    // mint a new mod
    function mint() public onlyOwner {
        uint256 tokenId = super.totalSupply().add(1);
        require(tokenId <= maxSupply, "Mod: supply reach the max limit!");
        super.mintTo(msg.sender);
        // set default mod score
        modTotalScore[tokenId] = 1;
        // emit mint event
        emit Mint(tokenId);
    }

    // get mod's total supply
    function getMaxModId() external view override returns (uint256) {
        return super.totalSupply();
    }

    // get mod's owner
    function getModOwner(uint256 modId)
        external
        view
        override
        returns (address)
    {
        require(modId <= super.totalSupply(), "Mod: illegal moderator ID!");
        return ownerOf(modId);
    }

    // update mod's score
    function updateModScore(uint256 modId, bool ifSuccess)
        external
        override
        returns (bool)
    {
        //Only Escrow contract can increase score
        require(
            escrowAddress == msg.sender,
            "Mod: only escrow contract can update mod score"
        );
        //total score add 1
        modTotalScore[modId] = modTotalScore[modId].add(1);
        if (ifSuccess) {
            // success score add 1
            modSuccessScore[modId] = modSuccessScore[modId].add(1);
        } else if (modSuccessScore[modId] > 0) {
            modSuccessScore[modId] = modSuccessScore[modId].sub(1);
        } else {
            // nothing changed
        }
        // recount mod success rate
        modSuccessRate[modId] = uint8(
            modSuccessScore[modId].mul(100).div(modTotalScore[modId])
        );
        // emit event
        emit UpdateScore(modId, ifSuccess);
        return true;
    }
}
