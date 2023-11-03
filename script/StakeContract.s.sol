// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "../src/StakeContract.sol";

contract DeployStakeContract is Script {
    function run() external {
        
        vm.startBroadcast();

        new StakeContract(
            address(0x71bDd3e52B3E4C154cF14f380719152fd00362E7),
            5
        );

        vm.stopBroadcast();
    }
}
