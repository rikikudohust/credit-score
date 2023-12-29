const ethUtil = require("ethereumjs-util");
const sigUtil = require("eth-sig-util");
const abi = require("ethereumjs-abi");
const chai = require("chai");
require("dotenv").config();

const utils = sigUtil.TypedDataUtils;
const Web3 = require("web3");

// var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
var web3 = new Web3();

const EIP712Domain = [
  { name: "name", type: "string" },
  { name: "version", type: "string" },
  { name: "chainId", type: "uint256" },
  { name: "verifyingContract", type: "address" },
];
const RankData = [
  { name: "user", type: "address" },
  { name: "expiration", type: "uint64" },
  { name: "rank", type: "uint16" },
];
const RankDatas = [{ name: "rankDatas", type: "RankData[]" }];
const domain = {
  name: "Credit Scoring",
  version: "1",
  chainId: 4,
  verifyingContract: "0xFB33A74a05d701506B9313070b28Cf9757C40aE8",
};
const rankDatas = {
  rankDatas: [
    {
      user: "0xcd295383a4a4fA71342F8b05DEEA60548a707bF7",
      expiration: ((Date.now() / 1000) | 0) + 86400,
      rank: 2,
    },
    {
      user: "0x97c1E5666B46a46C4Ef22B56aDfE1400E30853e7",
      expiration: ((Date.now() / 1000) | 0) + 86400,
      rank: 1,
    },
  ],
};

const typedData = {
  types: {
    EIP712Domain,
    RankDatas,
    RankData,
  },
  primaryType: "RankDatas",
  domain,
  message: rankDatas,
};

const privateKey = new Buffer.from(process.env.PRIVATE_KEY, "hex");
const address = ethUtil.privateToAddress(privateKey);
const messageHash = utils.sign(typedData);
const sig = ethUtil.ecsign(messageHash, privateKey);
console.log("r:", ethUtil.bufferToHex(sig.r));
console.log("s:", ethUtil.bufferToHex(sig.s));
console.log("v:", ethUtil.bufferToInt(sig.v));

var dataRank = "[";
for (let index in rankDatas.rankDatas) {
  if (index > 0) dataRank += ",";
  dataRank =
    dataRank +
    '["' +
    rankDatas.rankDatas[index].user +
    '",' +
    rankDatas.rankDatas[index].expiration +
    "," +
    rankDatas.rankDatas[index].rank +
    "]";
}
dataRank += "]";

console.log(dataRank);
const recover = async (messageHash, v, r, s) => {
  const address = await web3.eth.accounts.recover({
    messageHash,
    v,
    r,
    s,
  });

  console.log("signer:", address);
};

// verify sig
recover(
  ethUtil.bufferToHex(messageHash),
  ethUtil.bufferToHex(sig.v),
  ethUtil.bufferToHex(sig.r),
  ethUtil.bufferToHex(sig.s)
);
