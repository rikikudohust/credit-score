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

const domain = {
  name: "Credit Scoring",
  version: "1",
  chainId: 4,
  verifyingContract: "0xd7Cf47c98DE30332d9d90bB3Afd96753649E641C",
};
const rankData = {
  user: "0xcd295383a4a4fA71342F8b05DEEA60548a707bF7",
  expiration: ((Date.now() / 1000) | 0) + 86400,
  rank: 3,
};

const typedData = {
  types: {
    EIP712Domain,
    RankData,
  },
  primaryType: "RankData",
  domain,
  message: rankData,
};

const privateKey = new Buffer.from(process.env.PRIVATE_KEY, "hex");
const messageHash = utils.sign(typedData);
const sig = ethUtil.ecsign(messageHash, privateKey);

console.log("r:", ethUtil.bufferToHex(sig.r));
console.log("s:", ethUtil.bufferToHex(sig.s));
console.log("v:", ethUtil.bufferToInt(sig.v));

const dataRank =
  '["' +
  typedData.message.user +
  '",' +
  typedData.message.expiration +
  "," +
  typedData.message.rank +
  "]";
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
