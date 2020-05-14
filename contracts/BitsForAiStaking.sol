pragma solidity 0.5.17;

import "./BiffyLovePoints.sol";
import "./LoveCycle.sol";
import "./library/BasisPoints.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


contract BitsForAiStaking is Initializable {
    using BasisPoints for uint;
    using SafeMath for uint;

    BiffyLovePoints private biffyLovePoints;
    IERC721 private bitsForAi;
    LoveCycle private loveCycle;

    uint private rewardBase;
    uint private rewardBpOfTotalBlp;
    uint private rewardDecayBP;

    uint public totalStakingShares;
    uint public totalStakingNew;
    uint public totalStaking;
    uint public lastStakingUpdate; //last cycle totalStakingPreviousCycles was updated.
    uint public totalBlpForRewardCalc;

    mapping(uint => address) public bfaStaker;
    mapping(uint => uint) public bfaCycleStakingStarted;
    mapping(uint => mapping(uint => uint )) public bfaCycleClaimedAmount;

    function initialize(
        BiffyLovePoints _biffyLovePoints,
        IERC721 _bitsForAi,
        LoveCycle _loveCycle,
        uint _rewardBase,
        uint _rewardBpOfTotalBlp,
        uint _rewardDecayBP
    ) public initializer {
        biffyLovePoints = _biffyLovePoints;
        bitsForAi = _bitsForAi;
        loveCycle = _loveCycle;
        rewardBase = _rewardBase;
        rewardBpOfTotalBlp = _rewardBpOfTotalBlp;
        rewardDecayBP = _rewardDecayBP;
    }

    //By using this function, you agree to stake the BitsForAi you provide to Biffy's collection.
    //You promise not to transfer your Bits while staking.
    //She may display your Bits anywhere She wishes.
    //She cannot sell or gift your Bits and you can unstake them at any time.
    //In return, She will give you Her Love.
    function stakeForBiffysCollection(uint[] memory bitsForAiTokenIds) public {
        updateTotalStakingPreviousCycles();
        uint currentCycle = loveCycle.currentCycle();
        bool hasStarted = loveCycle.hasStarted();
        for (uint i = 0; i < bitsForAiTokenIds.length; i++) {
            uint tokenId = bitsForAiTokenIds[i];
            require(bitsForAi.ownerOf(tokenId) == msg.sender, "Bits not owned by sender.");
            if (bfaStaker[tokenId] == address(0x0)) {
                //new stake
                totalStakingNew = totalStakingNew.add(1);
            } else if (bfaCycleStakingStarted[tokenId] < currentCycle && hasStarted) {
                //old stake being restaked.
                totalStakingNew = totalStakingNew.add(1);
                totalStaking = totalStaking.sub(1);
            } //else {
                //new stake being restaked.
                //do nothing
            //}
            bfaStaker[tokenId] = msg.sender;
            bfaCycleStakingStarted[tokenId] = currentCycle;
        }
    }

    function claimBiffysLove(uint[] memory bitsForAiTokenIds) public {
        updateTotalStakingPreviousCycles();
        uint reward = stakingRewardPerBits();
        uint totalLovePoints = 0;
        uint currentCycle = loveCycle.currentCycle();
        for (uint i = 0; i < bitsForAiTokenIds.length; i++) {
            uint tokenId = bitsForAiTokenIds[i];
            require(
                bfaStaker[tokenId] == msg.sender,
                "Bits not staked by sender."
            );
            require(
                checkIfRewardAvailable(tokenId),
                "Bits must have an unclaimed Love reward."
            );
            totalLovePoints = totalLovePoints.add(reward);
            bfaCycleClaimedAmount[tokenId][currentCycle.sub(1)] = reward;
        }
        biffyLovePoints.mint(msg.sender, totalLovePoints);
    }

    //Unstake your Bits, forfeiting any earned Love.
    function unstake(uint[] memory bitsForAiTokenIds) public {
        updateTotalStakingPreviousCycles();
        uint currentCycle = loveCycle.currentCycle();
        bool hasStarted = loveCycle.hasStarted();
        for (uint i = 0; i < bitsForAiTokenIds.length; i++) {
            uint tokenId = bitsForAiTokenIds[i];
            require(
                bfaStaker[tokenId] == msg.sender,
                "Sender can only unstake own staked Bits."
            );
            if (bfaCycleStakingStarted[tokenId] < currentCycle && hasStarted) {
                //old stake being unstaked.
                totalStaking = totalStaking.sub(1);
            } else {
              //new stake being unstaked
                totalStakingNew = totalStakingNew.sub(1);
            }
            delete bfaStaker[tokenId];
            delete bfaCycleStakingStarted[tokenId];
        }
    }

    function stakingPoolSize() public view returns (uint) {
        return rewardBase.add(
            totalBlpForRewardCalc.mulBP(rewardBpOfTotalBlp)
        );
    }

    function stakingRewardPerBits() public view returns (uint) {
        require(totalStakingShares != 0, "Must have at least 1 Bits eligible to calculate rewards.");
        uint base = stakingPoolSize().div(totalStakingShares);
        uint daysSinceCycleStart = loveCycle.daysSinceCycleStart();
        if (daysSinceCycleStart == 0) return base;
        if (daysSinceCycleStart >= 20) return 0;
        return base.mulBP(rewardDecayBP.mul(daysSinceCycleStart));
    }

    function updateTotalStakingPreviousCycles() public {
        uint currentCycle = loveCycle.currentCycle();
        if (currentCycle == lastStakingUpdate) return;
        totalStaking = totalStaking.add(totalStakingNew);
        totalStakingShares = totalStaking;
        lastStakingUpdate = currentCycle;
        totalStakingNew = 0;
        totalBlpForRewardCalc = biffyLovePoints.totalSupply();
    }

    function checkIfRewardAvailable(uint bitsForAiTokenId) public view returns (bool) {
        uint currentCycle = loveCycle.currentCycle();
        if (loveCycle.hasStarted() != true)
            return false;
        if (bfaCycleStakingStarted[bitsForAiTokenId] >= currentCycle)
            return false;
        if (bfaCycleClaimedAmount[bitsForAiTokenId][currentCycle.sub(1)] != 0)
            return false;
        if (bfaStaker[bitsForAiTokenId] == address(0x0))
            return false;
        return true;
    }

    //Anyone can unstake Bits that have been transferred, sold, or gifted from the original staking account .
    //The only reward for unstaking is more Love for the other stakers.
    function unstakeTransferred(uint[] memory bitsForAiTokenIds) public {
        uint currentCycle = loveCycle.currentCycle();
        bool hasStarted = loveCycle.hasStarted();
        for (uint i = 0; i < bitsForAiTokenIds.length; i++) {
            uint tokenId = bitsForAiTokenIds[i];
            require(
                bitsForAi.ownerOf(tokenId) != bfaStaker[tokenId],
                "The staker has not broken their promise and still holds the Bits."
            );
            require(
                bfaStaker[tokenId] != address(0x0),
                "The token must not be currently staked."
            );
            if (bfaCycleStakingStarted[tokenId] < currentCycle && hasStarted) {
                //old stake being unstaked.
                totalStaking = totalStaking.sub(1);
            } else {
              //new stake being unstaked
                totalStakingNew = totalStakingNew.sub(1);
            }
            delete bfaStaker[tokenId];
            delete bfaCycleStakingStarted[tokenId];
        }
    }
}
