// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";


contract Invariant is StdInvariant, Test {

    ERC20Mock weth;
    ERC20Mock poolToken;
    PoolFactory factory;
    Handler handler;
    TSwapPool pool; // pool/weth
    int256 constant STARTING_X = 100e18; // starting poolToken amount
    int256 constant STARTING_Y = 50e18; // starting weth amount

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(
            uint256(STARTING_Y), 
            uint256(STARTING_Y),  
            uint256(STARTING_X), 
            uint64(block.timestamp)
        );
        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.swapPoolTokenToWethBasedOnOutputWeth.selector;
        

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );

        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameX() public {
        assert(handler.actualDeltaX() == handler.expectedDeltaX());
    }

    function statefulFuzz_constantProductFormulaStaysTheSameY() public {
        assert(handler.actualDeltaY() == handler.expectedDeltaY());
    }
}
