// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../StakeContract.sol";
import "./mocks/MyERC20.sol";

contract StakeContractTest is Test {
    MyERC20 public myERC20;
    StakeContract public stakeContract;
    
    address public constant MVPWAIR =
        address(0x71bDd3e52B3E4C154cF14f380719152fd00362E7);

    function setUp() public {
        myERC20 = new MyERC20();
        stakeContract = new StakeContract(MVPWAIR, 5);
        stakeContract.addStakingToken(address(myERC20), 15);
        myERC20.transfer(address(stakeContract), 10e18);
    }

    function testStake() public {
        uint256 amount = 10e18;
        myERC20.approve(address(stakeContract), amount);
        bool staked = stakeContract.stake(amount, address(myERC20));
        assertTrue(staked);
    }

    function testWithdraw() public {
        uint256 amount = 10e18;
        uint256 oldBalance = myERC20.balanceOf(address(this));
        myERC20.approve(address(stakeContract), amount);
        stakeContract.stake(amount, address(myERC20));
        stakeContract.withdraw(address(myERC20));
        assertEq(oldBalance, myERC20.balanceOf(address(this)) + amount / 2);
    }

    function testClaim() public {
        uint256 amount = 10e18;
        myERC20.approve(address(stakeContract), amount);
        stakeContract.stake(amount, address(myERC20));
        (bool success, ) = address(stakeContract).call(
            abi.encodeWithSignature("claim(address)", address(myERC20))
        );
        assertEq(success, false);
    }
}
