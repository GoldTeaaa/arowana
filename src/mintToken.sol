// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract mintToken is ERC721, Ownable{
    uint256 private s_tokenCounter;

    //error statements
    error priceCannotBeLowerThanZero(uint256 price);
    error notTheTokenOwner(address tokenOwner);
    error incorrectPriceInput(uint256 price);
    error tokenNotForSale(uint256 tokenCounter);
    error cannotBuyYourOwnToken(address tokenOwner);
    error fishRfidNotRegistered(string childRfid);
    error fishMotherRfidNotRegistered(string motherRfid);
    error fishFatherRfidNotRegistered(string fatherRfid);

    //the fish identity
    mapping(uint256 => string) private s_tokenUriByTokenCounter;
    mapping(uint256 => string) private s_rfidByTokenCounter;
    mapping(string => uint256) private s_tokenCounterByRfid;

    //fish parent
    struct FishParents{
        string motherRfid;
        string fatherRfid;
    }
    mapping (string => FishParents) public s_RfidToParentUri;

    //Track Owner
    mapping(uint256 => address[]) private s_ownerHistory;

    //Check if the rfid or tokenUri is registered
    mapping(string => bool) private s_registeredRfid;
    mapping(string => bool) private s_registeredTokenUri;
    mapping(string => bool) private s_checkOwnerByRfid;
 
    //Check if the token are sold or not
    mapping(uint256 => bool) private s_isTokenForSale;

    //Buying and selling the token
    mapping(uint256 => uint256) private s_setFishPrice;

    event tokenMinted(uint256 indexed tokenCounter,string indexed rfid,string tokenUri,string motherRfid,string fatherRfid);
    event parentAdded(string indexed rfid,string motherRfid,string fatherRfid);
    event tokenPriceForSale(uint256 indexed tokenCounter, uint256 indexed price);
    
    event tokenBought(uint256 indexed tokenCounter, address owner ,address indexed buyer, uint256 indexed tokenPrice);

    constructor()ERC721("ArowanaFish","ARW") Ownable(msg.sender) {
        s_tokenCounter = 0;
    }

    function tokenURI(uint256 tokenCounter) public view override returns(string memory){
        return s_tokenUriByTokenCounter[tokenCounter];
    }
     
    function mint(string memory tokenUri, string memory rfid, string memory motherRFID, string memory fatherRFID) external onlyOwner{
        require(!s_registeredRfid[rfid],"Rfid already registered");
        require(!s_registeredTokenUri[tokenUri],"TokenUri already exist!");

        //set the fish identity
        s_tokenUriByTokenCounter[s_tokenCounter] = tokenUri;
        s_rfidByTokenCounter[s_tokenCounter] = rfid;
        s_registeredRfid[rfid] = true;
        s_registeredTokenUri[tokenUri] = true;

        //set the owner fo the fish by Rfid
        s_checkOwnerByRfid[rfid] = true;
        s_tokenCounterByRfid[rfid] = s_tokenCounter;

        //set the parents information (if any)
        s_RfidToParentUri[rfid] = FishParents(motherRFID,fatherRFID);

        _safeMint(msg.sender,s_tokenCounter);

        emit tokenMinted(s_tokenCounter,rfid,tokenUri,motherRFID,fatherRFID);
        s_tokenCounter++;
    }

    function setFishPrice(uint256 tokenCounter, uint256 price) external{
        if(ownerOf(tokenCounter) != msg.sender)
            revert notTheTokenOwner(ownerOf(tokenCounter));
        
        if(price >= 0){
            s_setFishPrice[tokenCounter] = price;
            emit tokenPriceForSale(tokenCounter, price);
        }else{
            revert priceCannotBeLowerThanZero(price);
        }
    }

    function buyFishToken(uint256 tokenCounter) external payable{
        uint256 price = s_setFishPrice[tokenCounter];
        address owner = ownerOf(tokenCounter);

        if(s_setFishPrice[tokenCounter] == 0)
            revert tokenNotForSale(tokenCounter);

        if(msg.value != price)
            revert incorrectPriceInput(price);
        
        if(owner == msg.sender)
            revert cannotBuyYourOwnToken(owner);
        
        //Payment
        payable(owner).transfer(msg.value);
        //Safely transfer the token
        _transfer(owner, msg.sender, tokenCounter);

        //Record the previous owner
        s_ownerHistory[tokenCounter].push(owner);

        //reset the price mapping
        s_setFishPrice[tokenCounter] = 0;

        emit tokenBought(tokenCounter, owner, msg.sender, price);
    }

    function addParentsToOrphanFish(string memory childRfid, string memory motherRfid, string memory fatherRfid) external onlyOwner{
        if(!s_registeredRfid[childRfid])
            revert fishRfidNotRegistered(childRfid);
        
        else if(keccak256(bytes(s_RfidToParentUri[motherRfid].motherRfid)) == keccak256(bytes(motherRfid)))
            revert fishMotherRfidNotRegistered(motherRfid);
        
        else if(keccak256(bytes(s_RfidToParentUri[fatherRfid].fatherRfid)) == keccak256(bytes(fatherRfid)))
            revert fishFatherRfidNotRegistered(fatherRfid);

        require(keccak256(bytes(s_RfidToParentUri[childRfid].motherRfid)) != keccak256(bytes(motherRfid)),"Mother has already been set for this fish");
        require(keccak256(bytes(s_RfidToParentUri[childRfid].fatherRfid)) != keccak256(bytes(fatherRfid)),"Father has already been set for this fish");
        
        s_RfidToParentUri[childRfid] = FishParents(motherRfid,fatherRfid);
        emit parentAdded(childRfid, motherRfid, fatherRfid);
    }
    

    function getRfidByTokenId(uint256 tokenID) external view returns(string memory){
        require(_exists(tokenID),"Fish token does not exist"); //Check if the tokenID is exist
        //The basic ERC721 does not have _exists function, it added manually
        return s_rfidByTokenCounter[tokenID];
    }

    function getOwnerOfRfid(string memory fishRfid) external view returns(address){
        uint256 tokenCounter = s_tokenCounterByRfid[fishRfid];
        require(s_checkOwnerByRfid[fishRfid],"Rfid Not Found");
        return ownerOf(tokenCounter);
    }

    function getParentsByRfid(string memory fishRfid) external view returns(string memory, string memory){
        // require(_existsRfid(fishRfid),"Parent Token does not exist"); //Check if the tokenID is exist
        // //The basic ERC721 does not have _existsRfid function, it added manually
        if(!s_registeredRfid[fishRfid])
            revert fishRfidNotRegistered(fishRfid);
        
        return(s_RfidToParentUri[fishRfid].motherRfid, s_RfidToParentUri[fishRfid].fatherRfid); //still suspect error because the parent info is not bind with the mapping. Remove if the testing is succeed
    }

    function getFishPrice(uint256 tokenCounter) external view returns(uint256){
        return s_setFishPrice[tokenCounter];
    }

}

contract TrackFish{

}

contract fishTrade{

}