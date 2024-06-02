// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import {AggregatorV3Interface} from "../src/interfaces/AggregatorV3Interface.sol";

contract MarketDataProvider is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 public optimalFees;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor() {
        setPublicChainlinkToken();
        oracle = YOUR_ORACLE_ADDRESS; // Set your oracle address
        jobId = YOUR_JOB_ID; // Set your job id
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    function getEthUsdPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getEthUsdVol() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x31D04174D0e1643963b38d87f26b0675Bb7dC96e);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getGasPrice() public view returns (uint256) {
        AggregatorV3Interface gasPriceFeed = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E); // Replace with the actual Chainlink Gas Price Oracle address
        (, int256 answer,,,) = gasPriceFeed.latestRoundData();
        return uint256(answer);
    }

    function requestOptimalFees(string memory volume, string memory liquidity, string memory gasPrice) public returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        request.add("volume", volume);
        request.add("liquidity", liquidity);
        request.add("gasPrice", gasPrice);

        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _optimalFees) public recordChainlinkFulfillment(_requestId) {
        optimalFees = _optimalFees;
    }

    function getOptimalFees() public view returns (uint256) {
        return optimalFees;
    }
}
