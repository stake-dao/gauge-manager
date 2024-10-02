/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

interface IVoting {
    struct Vote {
        bool open;
        bool executed;
        uint64 startDate;
        uint64 snapshotBlock;
        uint64 supportRequired;
        uint64 minAcceptQuorum;
        uint256 yea;
        uint256 nay;
        uint256 votingPower;
        bytes script;
    }

    function newVote(bytes memory executionScript, string memory metadata, bool castVote, bool executesIfDecided)
        external
        returns (uint256 voteId);

    function executeVote(uint256 voteId) external;
    function votePct(uint256 voteId, uint256 yeaPct, uint256 nayPct, bool executeIfDecided) external;

    function getVote(uint256 voteId) external view returns (Vote memory);
}
