const RewardShare = artifacts.require("RewardShare");

module.exports = function (deployer) {
  let multi = "0x0000000000000000000000000000000000000000"
  let ve = "0x0000000000000000000000000000000000000000"
  let vereward = "0x0000000000000000000000000000000000000000"
  deployer.deploy(RewardShare, multi, ve, vereward, "multi ve reward share", "mvrs");
};
