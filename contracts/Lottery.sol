// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";

contract Lottery is Ownable {
    using SafeMathChainlink for uint256;
    AggregatorV3Interface internal ethUsdpriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        PROCESSING
    }
    LOTTERY_STATE public lotteryState;
    uint256 public usdEntryFee;
    address payable[] public players;
    uint256 public randomness;

    constructor(address _ethUsdpriceFeed, uint256 _usdEntryFee) public {
        ethUsdpriceFeed = AggregatorV3Interface(_ethUsdpriceFeed);
        usdEntryFee = _usdEntryFee;
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    function entry() public payable {
        require(msg.value >= getEntranceFee(), "Not Enough ETH to ENTER");
        require(lotteryState == LOTTERY_STATE.OPEN);
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 precision = 1 * 10**18;
        uint256 price = getLatestEthUsdPrice();
        uint256 costToEnter = (precision / price) * (usdEntryFee * 100000000);
        return costToEnter;
    }

    function getLatestEthUsdPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = ethUsdpriceFeed.latestRoundData();
        return uint256(price);
    }

    function startLottery() public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.CLOSED,
            "Can't start a new lottery!"
        );
        lotteryState = LOTTERY_STATE.OPEN;
        randomness = 0;
    }

    function endLottery(uint256 userProvidedSeed) public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.OPEN,
            "Can't end a non-existing lottery!"
        );
        lotteryState = LOTTERY_STATE.PROCESSING;
        pickWinner(userProvidedSeed);
    }

    function pickWinner(uint256 userProvidedSeed) private returns (bytes32) {
        require(
            lotteryState == LOTTERY_STATE.PROCESSING,
            "Lottery Should be processed"
        );
        bytes32 requestId = requestRandomness(KeyHash, fee, userProvidedSeed);
    }
}
