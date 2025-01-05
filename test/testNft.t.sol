// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console, Test} from "lib/forge-std/src/Test.sol";
import {DeployToken} from "script/DeployNFT.s.sol";
import {mintToken} from "src/mintToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract testNft is Test{
    DeployToken private deployer;
    mintToken private mint;

    //Testing properties
    address alice = msg.sender;
    address bob = address(this);
    string private tokenURI = "https://bafybeifcxovgaf7jeoi6b2j6w7plrjzzo7adgu3fppj6xjs43m37w4psha.ipfs.dweb.link?filename=SuperRedTest.JSON";
    string private rfid = "123";
    string private motherRfid = "mom123";
    string private fatherRfid = "dad123";
    uint256 private price = 0.01 ether;
    uint256 private wrongPrice = 0.005 ether;

    function setUp() public{
        deployer = new DeployToken();
        mint = deployer.run();
    }

    function testRegistered() public{
        vm.startPrank(alice);
        console.log(msg.sender);
        mint.mint(tokenURI,rfid,motherRfid,fatherRfid);

        assertEq(mint.tokenURI(0),tokenURI);
        assertEq(mint.getRfidByTokenId(0),rfid);
        
        vm.expectRevert();
        mint.mint(tokenURI,rfid,motherRfid,fatherRfid);
        
        vm.stopPrank();
    }

    function testSetFishPrice() public{
        vm.startPrank(alice);
        mint.mint(tokenURI,rfid,motherRfid,fatherRfid);
        mint.setFishPrice(0,price);
        vm.stopPrank();

        assertEq(price,mint.getFishPrice(0));
    }

    function testCorrectBuyer() public{
        vm.startPrank(alice);
        mint.mint(tokenURI,rfid,motherRfid,fatherRfid);
        mint.setFishPrice(0,price);
        vm.stopPrank();

        vm.startPrank(bob);
        mint.buyFishToken{value: price}(0);
        vm.stopPrank();

        assertEq(mint.getOwnerOfRfid(rfid),bob);
        console.log(mint.getOwnerOfRfid(rfid));
        console.log(alice);
        assertTrue(mint.ownerOf(0) != alice);
    }

    function testWrongBuyerAndWrongPrice() public {
        vm.startPrank(alice);
        mint.mint(tokenURI,rfid,motherRfid,fatherRfid);
        mint.setFishPrice(0,price);

        vm.expectRevert();
        mint.buyFishToken{value: price}(0);

        vm.expectRevert();
        mint.buyFishToken{value: wrongPrice}(0);
        vm.stopPrank();
    }

    function testRegisteredRfidInAddParents() public{
        vm.startPrank(alice);
        mint.mint(tokenURI,rfid,"","");
        mint.addParentsToOrphanFish(rfid,motherRfid,fatherRfid);
        vm.stopPrank();

        vm.expectRevert();
        mint.addParentsToOrphanFish(rfid,motherRfid,fatherRfid);
        console.log(motherRfid, fatherRfid);
        (string memory structMotherRfid, string memory structFatherRfid) = mint.getParentsByRfid(rfid);
        assertEq(motherRfid, structMotherRfid);
        assertEq(fatherRfid, structFatherRfid);
    }


} 