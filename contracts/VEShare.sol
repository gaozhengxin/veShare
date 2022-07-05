// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint balance);
}

interface IVE {
    function withdraw(uint _tokenId) external returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;
    function create_lock(uint _value, uint _lock_duration) external returns (uint);
}

interface IReward {
  function rewardToken() external view returns (address);
  function claimReward(uint tokenId, uint startEpoch, uint endEpoch) external returns (uint reward);
  function getEpochIdByTime(uint _time) view external returns (uint);
  function getEpochInfo(uint epochId) view external returns (uint, uint, uint);
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    uint256 public nextTokenId = 1;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

contract RewardShare is ERC721, Administrable {
    address public ve;
    uint256 public ve_tokenId;
    address public vereward;
    address public multi;

    constructor (address multi_, address ve_, address vereward_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        ve = ve_;
        vereward = vereward_;
        multi = multi_;
        setAdmin(msg.sender);
    }

    function createVe(uint256 amount, uint256 duration) onlyAdmin external returns (uint) {
        require(ve_tokenId == 0);
        ve_tokenId = IVE(ve).create_lock(amount, duration);
        return ve_tokenId;
    }

    // withdraw multi after expired
    function withdrawMulti(address to) onlyAdmin external {
        IVE(ve).withdraw(ve_tokenId);
        IVE(ve).withdraw(ve_tokenId);
        IERC20(multi).transferFrom(address(this), to, IERC20(multi).balanceOf(address(this)));
        ve_tokenId = 0;
    }

    function withdrawReward(address to, uint256 amount) onlyAdmin external {
        IERC20(IReward(vereward).rewardToken()).transferFrom(address(this), to, amount);
    }

    function withdrawVe(address to) onlyAdmin external {
        IVE(ve).safeTransferFrom(address(this), to, ve_tokenId);
        ve_tokenId = 0;
    }

    mapping (uint256 => uint256) public globalReward; // epochId => reward

    function collectGlobalReward(uint256 startEpochId, uint256 endEpochId) internal {
      for (uint i = startEpochId; i <= endEpochId; i++) {
        globalReward[i] += IReward(vereward).claimReward(ve_tokenId, i, i);
      }
    }

    mapping (uint256 => uint256) public lastHarvestUntil; // tokenId => time

    mapping (uint256 => TokenInfo) public tokenInfo;
    mapping (uint256 => uint256) public totalShare; // day => total share

    uint256 public day = 1 days;

    struct TokenInfo {
        uint8 share;
        uint256 startTime;
        uint256 endTime;
    }

    function harvestAll(uint256 tokenId) external {
      // user's unclaimed timespan
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      uint256 endTime = block.timestamp < tokenInfo[tokenId].endTime ? block.timestamp : tokenInfo[tokenId].endTime;
      _harvest(tokenId, startTime, endTime);
    }

    function harvest(uint256 tokenId, uint256 endTime) external {
      // user's unclaimed timespan
      uint256 startTime = lastHarvestUntil[tokenId] > tokenInfo[tokenId].startTime ? lastHarvestUntil[tokenId] : tokenInfo[tokenId].startTime;
      require(endTime <= block.timestamp && endTime <= tokenInfo[tokenId].endTime);
      _harvest(tokenId, startTime, endTime);
    }

    function _harvest(uint256 tokenId, uint256 startTime, uint256 endTime) internal {
      uint256 startEpochId = IReward(vereward).getEpochIdByTime(startTime);
      uint256 endEpochId = IReward(vereward).getEpochIdByTime(endTime);
      collectGlobalReward(startEpochId, endEpochId);
      uint256 reward = 0;
      uint256 userLockStart;
      uint256 userLockEnd;
      uint256 collectedTime;
      for (uint i = startEpochId; i <= endEpochId; i++) {
        uint256 reward_i = globalReward[i];
        (uint epochStartTime, uint epochEndTime, ) = IReward(vereward).getEpochInfo(i);
        // user's unclaimed time span in an epoch
        userLockStart = epochStartTime;
        userLockEnd = epochEndTime;
        collectedTime = epochEndTime - epochStartTime;
        if (i == startEpochId) {
          userLockStart = startTime;
        }
        if (i == endEpochId) {
          userLockEnd = endTime; // assuming endTime <= block.timestamp
          collectedTime = block.timestamp - epochStartTime;
        }
        reward_i = reward_i * (userLockEnd - userLockStart) / collectedTime;
        reward += reward_i;
      }
      // update last harvest time
      lastHarvestUntil[tokenId] = endTime;
      uint256 userReward = reward * tokenInfo[tokenId].share / 100;
      IERC20(IReward(vereward).rewardToken()).transferFrom(address(this), msg.sender, userReward);
    }

    function mint(address to, uint8 share, uint256 start, uint256 end) external onlyAdmin returns (bool success, uint256 tokenId) {
        uint startDay = start / day;
        uint endDay = end / day + 1;
        require(endDay - startDay <= 360, "duration is too long");
        for (uint i = start; i < end; i++) {
            totalShare[i] = totalShare[i] + share;
            if (totalShare[i] > 100) {
                return (false, 0);
            }
        }
        tokenId = nextTokenId;
        nextTokenId += 1;
        _mint(to, tokenId);
        tokenInfo[tokenId] = TokenInfo(share, startDay * day, endDay * day);
        return (true, tokenId);
    }
}