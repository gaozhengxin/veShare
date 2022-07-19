const RewardShare = artifacts.require("RewardShare");

module.exports = function (deployer) {
  let multi = "0x93bb21A55fa0598F28FF04117A8b683779D538E5"
  let ve = "0x8a5967592A0EA779d189028e7f2ABe490081a438"
  let vereward = "0x7b6Ae47c8a1F83EF3AcbbD03f502808A29011d66"
  deployer.deploy(RewardShare, multi, ve, vereward, "multi ve reward share", "mvrs");
};
