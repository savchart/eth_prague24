// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {MarketDataProvider} from "./MarketDataProvider.sol";

contract VolBasedDynamicFeeHook is BaseHook {
    MarketDataProvider immutable marketDataProvider;

    constructor(IPoolManager _poolManager, MarketDataProvider _marketDataProvider) BaseHook(_poolManager) {
        marketDataProvider = _marketDataProvider;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function getVolatility() public view returns (uint256) {
        return marketDataProvider.getEthUsdVol();
    }

    function getPrice() public view returns (uint256) {
        return marketDataProvider.getEthUsdPrice();
    }

    function getOptimalFees() public view returns (uint256) {
        return marketDataProvider.getOptimalFees();
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4)
    {
        uint256 volatility = getVolatility();
        uint256 price = getPrice();
        uint256 gasPrice = marketDataProvider.getGasPrice();
        uint256 optimalFees = getOptimalFees();
        poolManager.updateDynamicSwapFee(key, optimalFees, volatility, price, gasPrice);

        return BaseHook.beforeSwap.selector;
    }

    function getFee(int256 amt) external view returns (uint24) {
        uint256 volatility = getVolatility();
        uint256 price = getPrice();
        return calculateFee(abs(amt), volatility, price);
    }
}
