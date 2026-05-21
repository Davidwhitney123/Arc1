// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ArtemisB
 * @notice Sports prediction platform on Arc Testnet
 * @dev Supports Football and Basketball predictions with USDC staking
 * USDC on Arc Testnet: 0x3600000000000000000000000000000000000000
 */
contract ArtemisB is Ownable, ReentrancyGuard {

    // ─── STATE VARIABLES ──────────────────────────────────
    IERC20 public usdc;
    uint256 public platformFeePercent = 3; // 3% platform fee
    uint256 public matchCount;
    uint256 public betCount;

    // ─── ENUMS ────────────────────────────────────────────
    enum Sport { FOOTBALL, BASKETBALL }
    enum Outcome { HOME, DRAW, AWAY }
    enum MatchStatus { OPEN, CLOSED, RESOLVED, CANCELLED }

    // ─── STRUCTS ──────────────────────────────────────────
    struct Match {
        uint256 id;
        Sport sport;
        string homeTeam;
        string awayTeam;
        string league;
        uint256 startTime;
        MatchStatus status;
        Outcome result;
        uint256 totalStakedUSDC;
    }

    struct Bet {
        address bettor;
        uint256 matchId;
        Outcome prediction;
        uint256 amountUSDC;
        bool claimed;
    }

    // ─── MAPPINGS ─────────────────────────────────────────
    mapping(uint256 => Match) public matches;
    mapping(uint256 => Bet) public bets;
    mapping(uint256 => uint256[]) public matchBets;
    mapping(address => uint256[]) public userBets;
    mapping(address => uint256) public usdcBalance;
    mapping(uint256 => mapping(Outcome => uint256)) public usdcPerOutcome;

    // ─── EVENTS ───────────────────────────────────────────
    event MatchCreated(
        uint256 indexed matchId,
        Sport sport,
        string homeTeam,
        string awayTeam,
        string league,
        uint256 startTime
    );
    event BetPlaced(
        uint256 indexed betId,
        address indexed bettor,
        uint256 indexed matchId,
        Outcome prediction,
        uint256 amountUSDC
    );
    event MatchResolved(uint256 indexed matchId, Outcome result);
    event MatchCancelled(uint256 indexed matchId);
    event MatchClosed(uint256 indexed matchId);
    event WinningsClaimed(
        address indexed user,
        uint256 indexed betId,
        uint256 usdcAmount
    );
    event Deposited(address indexed user, uint256 usdcAmount);
    event Withdrawn(address indexed user, uint256 usdcAmount);
    event FeeUpdated(uint256 newFee);

    // ─── CONSTRUCTOR ──────────────────────────────────────
    constructor(address _usdc) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    // ─── MODIFIERS ────────────────────────────────────────
    modifier matchExists(uint256 matchId) {
        require(matchId < matchCount, "Match does not exist");
        _;
    }

    modifier matchIsOpen(uint256 matchId) {
        require(
            matches[matchId].status == MatchStatus.OPEN,
            "Match is not open"
        );
        _;
    }

    // ─── DEPOSIT ──────────────────────────────────────────

    /**
     * @notice Deposit USDC into your Artemis Bet wallet
     * @param amount Amount of USDC to deposit (6 decimals)
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed"
        );
        usdcBalance[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    // ─── WITHDRAW ─────────────────────────────────────────

    /**
     * @notice Withdraw USDC from your Artemis Bet wallet
     * @param amount Amount of USDC to withdraw (6 decimals)
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(
            usdcBalance[msg.sender] >= amount,
            "Insufficient balance"
        );
        usdcBalance[msg.sender] -= amount;
        require(
            usdc.transfer(msg.sender, amount),
            "USDC transfer failed"
        );
        emit Withdrawn(msg.sender, amount);
    }

    // ─── ADMIN: CREATE MATCH ──────────────────────────────

    /**
     * @notice Create a new match for predictions
     * @param sport 0 = Football, 1 = Basketball
     * @param homeTeam Name of home team
     * @param awayTeam Name of away team
     * @param league League name e.g. "Premier League"
     * @param startTime Unix timestamp of match start
     */
    function createMatch(
        Sport sport,
        string memory homeTeam,
        string memory awayTeam,
        string memory league,
        uint256 startTime
    ) external onlyOwner returns (uint256) {
        require(startTime > block.timestamp, "Start time must be in future");
        require(bytes(homeTeam).length > 0, "Home team required");
        require(bytes(awayTeam).length > 0, "Away team required");

        uint256 matchId = matchCount;
        matchCount++;

        matches[matchId] = Match({
            id: matchId,
            sport: sport,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            league: league,
            startTime: startTime,
            status: MatchStatus.OPEN,
            result: Outcome.HOME,
            totalStakedUSDC: 0
        });

        emit MatchCreated(
            matchId,
            sport,
            homeTeam,
            awayTeam,
            league,
            startTime
        );
        return matchId;
    }

    // ─── PLACE BET ────────────────────────────────────────

    /**
     * @notice Place a bet on a match outcome
     * @param matchId ID of the match
     * @param prediction 0 = Home, 1 = Draw, 2 = Away
     * @param usdcAmount Amount of USDC to stake (6 decimals)
     */
    function placeBet(
        uint256 matchId,
        Outcome prediction,
        uint256 usdcAmount
    ) external nonReentrant matchExists(matchId) matchIsOpen(matchId) {
        Match storage m = matches[matchId];
        require(
            block.timestamp < m.startTime,
            "Match has already started"
        );
        require(usdcAmount > 0, "Must stake more than 0");
        require(
            usdcBalance[msg.sender] >= usdcAmount,
            "Insufficient balance, please deposit first"
        );

        // Deduct from user balance
        usdcBalance[msg.sender] -= usdcAmount;

        // Update match totals
        m.totalStakedUSDC += usdcAmount;
        usdcPerOutcome[matchId][prediction] += usdcAmount;

        // Create bet record
        uint256 betId = betCount;
        betCount++;

        bets[betId] = Bet({
            bettor: msg.sender,
            matchId: matchId,
            prediction: prediction,
            amountUSDC: usdcAmount,
            claimed: false
        });

        matchBets[matchId].push(betId);
        userBets[msg.sender].push(betId);

        emit BetPlaced(betId, msg.sender, matchId, prediction, usdcAmount);
    }

    // ─── ADMIN: MATCH MANAGEMENT ──────────────────────────

    /**
     * @notice Close a match to stop new bets
     */
    function closeMatch(uint256 matchId)
        external
        onlyOwner
        matchExists(matchId)
    {
        require(
            matches[matchId].status == MatchStatus.OPEN,
            "Match is not open"
        );
        matches[matchId].status = MatchStatus.CLOSED;
        emit MatchClosed(matchId);
    }

    /**
     * @notice Resolve a match with the final result
     * @param result 0 = Home win, 1 = Draw, 2 = Away win
     */
    function resolveMatch(uint256 matchId, Outcome result)
        external
        onlyOwner
        matchExists(matchId)
    {
        require(
            matches[matchId].status == MatchStatus.OPEN ||
            matches[matchId].status == MatchStatus.CLOSED,
            "Match cannot be resolved"
        );
        matches[matchId].status = MatchStatus.RESOLVED;
        matches[matchId].result = result;
        emit MatchResolved(matchId, result);
    }

    /**
     * @notice Cancel a match and allow refunds
     */
    function cancelMatch(uint256 matchId)
        external
        onlyOwner
        matchExists(matchId)
    {
        require(
            matches[matchId].status != MatchStatus.RESOLVED,
            "Match already resolved"
        );
        matches[matchId].status = MatchStatus.CANCELLED;
        emit MatchCancelled(matchId);
    }

    // ─── CLAIM WINNINGS ───────────────────────────────────

    /**
     * @notice Claim winnings or refund for a bet
     * @param betId ID of the bet to claim
     */
    function claimWinnings(uint256 betId) external nonReentrant {
        Bet storage bet = bets[betId];
        require(bet.bettor == msg.sender, "Not your bet");
        require(!bet.claimed, "Already claimed");

        Match storage m = matches[bet.matchId];

        // Handle cancelled match — full refund
        if (m.status == MatchStatus.CANCELLED) {
            bet.claimed = true;
            usdcBalance[msg.sender] += bet.amountUSDC;
            emit WinningsClaimed(msg.sender, betId, bet.amountUSDC);
            return;
        }

        require(
            m.status == MatchStatus.RESOLVED,
            "Match not resolved yet"
        );
        require(
            bet.prediction == m.result,
            "Sorry, you lost this bet"
        );

        bet.claimed = true;

        // Calculate winnings proportionally
        uint256 winnerPool = usdcPerOutcome[bet.matchId][m.result];
        uint256 totalPool = m.totalStakedUSDC;

        uint256 grossWinnings = (bet.amountUSDC * totalPool) / winnerPool;

        // Deduct platform fee
        uint256 fee = (grossWinnings * platformFeePercent) / 100;
        uint256 netWinnings = grossWinnings - fee;

        usdcBalance[msg.sender] += netWinnings;

        emit WinningsClaimed(msg.sender, betId, netWinnings);
    }

    // ─── VIEW FUNCTIONS ───────────────────────────────────

    /**
     * @notice Get all bet IDs for a user
     */
    function getUserBets(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userBets[user];
    }

    /**
     * @notice Get all bet IDs for a match
     */
    function getMatchBets(uint256 matchId)
        external
        view
        returns (uint256[] memory)
    {
        return matchBets[matchId];
    }

    /**
     * @notice Get user USDC balance on Artemis Bet
     */
    function getBalance(address user)
        external
        view
        returns (uint256)
    {
        return usdcBalance[user];
    }

    /**
     * @notice Get total staked per outcome for a match
     */
    function getOutcomeStakes(uint256 matchId)
        external
        view
        returns (uint256 home, uint256 draw, uint256 away)
    {
        return (
            usdcPerOutcome[matchId][Outcome.HOME],
            usdcPerOutcome[matchId][Outcome.DRAW],
            usdcPerOutcome[matchId][Outcome.AWAY]
        );
    }

    /**
     * @notice Get all open matches
     */
    function getMatch(uint256 matchId)
        external
        view
        matchExists(matchId)
        returns (Match memory)
    {
        return matches[matchId];
    }

    // ─── ADMIN: FEES & TREASURY ───────────────────────────

    /**
     * @notice Update platform fee (max 10%)
     */
    function setPlatformFee(uint256 fee) external onlyOwner {
        require(fee <= 10, "Fee cannot exceed 10%");
        platformFeePercent = fee;
        emit FeeUpdated(fee);
    }

    /**
     * @notice Withdraw collected fees to owner wallet
     */
    function withdrawFees(uint256 amount) external onlyOwner {
        require(
            usdc.transfer(owner(), amount),
            "Fee withdrawal failed"
        );
    }
}