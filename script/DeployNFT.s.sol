// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src/Script.sol";
import {mintToken} from "src/mintToken.sol";

contract DeployToken is Script{
    function run() public returns(mintToken){
        vm.startBroadcast();
        mintToken MintToken = new mintToken();
        vm.stopBroadcast();
        return MintToken;
    }
}