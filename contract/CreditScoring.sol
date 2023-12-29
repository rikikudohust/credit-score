// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

// @Trava Credit Score

interface ICreditScoring {
    function getUserRank(address user) external view returns (uint256);

    function setUserRank(address user, uint256 rank) external;

    function setBatchUserRank(address[] calldata user, uint256[] calldata rank)
        external;
}

contract CreditScoring is ICreditScoring {
    event ChangeGovernance(address oldGovernance, address newGovernance);

    event ChangeCreditScoreAdmin(
        address oldCreditScoreAdmin,
        address newCreditScoreAdmin
    );

    struct RankPoll {
        address user;
        uint64 ts;
        uint16 score;
        bytes[65] sig;
    }

    struct RankData {
        address user;
        uint64 expiration;
        uint16 rank;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    //Variable
    mapping(address => uint256) public userRank;
    address public CreditScoreAdmin;
    address public GOVERNANCE;
    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant RANKDATA_TYPEHASH =
        keccak256("RankData(address user,uint64 expiration,uint16 rank)");
    bytes32 constant BATCHRANKDATA_TYPEHASH =
        keccak256(
            "RankDatas(RankData[] rankDatas)RankData(address user,uint64 expiration,uint16 rank)"
        );
    bytes32 DOMAIN_SEPARATOR;

    /*=========MODIFIER=========== */
    modifier onlyGovernance() {
        require(msg.sender == GOVERNANCE, "ONLY_GOVERNANCE");
        _;
    }

    modifier onlyCreditScoreAdmin() {
        require(msg.sender == CreditScoreAdmin, "ONLY_CREDIT SCORE ADMIN");
        _;
    }

    /*=============CONSTRUCTOR=========== */

    constructor(address governance, address _CreditScoreAdmin) {
        require(governance != address(0), "INVALID_ADDRESS");
        require(_CreditScoreAdmin != address(0), "INVALID_ADDRESS");
        GOVERNANCE = governance;
        CreditScoreAdmin = _CreditScoreAdmin;

        DOMAIN_SEPARATOR = hashEIP712Domain(
            EIP712Domain({
                name: "Credit Scoring",
                version: "1",
                chainId: 4,
                verifyingContract: address(this)
            })
        );
    }

    function hashEIP712Domain(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function hashRankData(RankData memory rankData)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    RANKDATA_TYPEHASH,
                    rankData.user,
                    rankData.expiration,
                    rankData.rank
                )
            );
    }

    function hashBatchRankData(RankData[] memory rankDatas)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory rankDataHash = new bytes32[](rankDatas.length);
        for (uint256 i = 0; i < rankDatas.length; i++) {
            rankDataHash[i] = hashRankData(rankDatas[i]);
        }

        return
            keccak256(
                abi.encode(
                    BATCHRANKDATA_TYPEHASH,
                    keccak256(abi.encodePacked(rankDataHash))
                )
            );
    }

    function setGovernance(address governance) external onlyGovernance {
        require(governance != address(0), "zero address");
        GOVERNANCE = governance;
        emit ChangeGovernance(msg.sender, governance);
    }

    function setCreditScoreAdmin(address _CreditScoreAdmin)
        external
        onlyCreditScoreAdmin
    {
        require(_CreditScoreAdmin != address(0), "zero address");
        CreditScoreAdmin = _CreditScoreAdmin;
        emit ChangeCreditScoreAdmin(msg.sender, _CreditScoreAdmin);
    }

    /*================USER RANK================== */

    function getUserRank(address user)
        external
        view
        override
        returns (uint256)
    {
        return userRank[user];
    }

    function setUserRank(address user, uint256 rank)
        public
        override
        onlyCreditScoreAdmin
    {
        require(rank >= 0 && rank < 5, "INVALID_RANK");
        userRank[user] = rank;
    }

    function setBatchUserRank(address[] calldata user, uint256[] calldata rank)
        external
        override
        onlyCreditScoreAdmin
    {
        require(user.length == rank.length, "INVALID_DATA");
        for (uint256 i = 0; i < user.length; i++) {
            require(rank[i] >= 0 && rank[i] < 5, "INVALID_RANK");
            userRank[user[i]] = rank[i];
        }
    }

    /*==========SET RANK WITH SIGNED DATA============== */
    function setUserRankWithData(
        RankData memory rankData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 messageHash = prefixed(hashRankData(rankData));

        require(ecrecover(messageHash, v, r, s) == CreditScoreAdmin, "sig!");

        require(block.timestamp <= rankData.expiration, "exp!");

        setUserRank(rankData.user, rankData.rank);
    }

    function setBatchUserRankWithData(
        RankData[] memory rankDatas,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 messageHash = prefixed(hashBatchRankData(rankDatas));

        require(ecrecover(messageHash, v, r, s) == CreditScoreAdmin, "sig!");

        for (uint256 i = 0; i < rankDatas.length; i++) {
            require(block.timestamp <= rankDatas[i].expiration, "exp");
            require(
                rankDatas[i].rank >= 0 && rankDatas[i].rank < 5,
                "INVALID_RANK"
            );

            userRank[rankDatas[i].user] = rankDatas[i].rank;
        }
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash));
    }
}
