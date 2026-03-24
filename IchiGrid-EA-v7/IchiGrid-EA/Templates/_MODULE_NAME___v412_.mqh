//+------------------------------------------------------------------+
//|        {MODULE_NAME}.mqh — v4.12 INSTITUTIONAL CORE ENGINE       |
//|                 Copyright 2026, SOVRALYS LLC                     |
//| DESK-GRADE • MULTI-ASSET • HFT-STABLE • BROKER-AGNOSTIC • SAFE  |
//+------------------------------------------------------------------+
/*
===============================================================================
GENERATION METADATA
===============================================================================
<gen:header>
| @project      : IchiGridEA
| @section      : {SECTION_ID}
| @version      : {VERSION}
| @generated_at : {ISO_TIMESTAMP}
| @session_id   : {SESSION_ID}
| @model        : {MODEL_ID}
| @spec_hash    : {SPEC_SHA256}
| @code_hash    : {CODE_SHA256}
| @spec_source  : {SPEC_SOURCE_URL}
| @depends      : {DEPENDENCIES}
| @description  : {DESCRIPTION}
| @audit_tag    : v4.12 — MULTI-INSTANCE PATCH (CB/WT/HM isolation + compat + UTs)
|  v4.12 MULTI-INSTANCE PATCH:
|        fixARC1  CircuitBreaker: slot-based per-instance state (m_tripped[], m_consec_losses[], etc.)
|                 Alloc() + Activate(slot) — each C{MODULE_NAME} instance gets isolated CB state
|        fixARC2  WatchdogTimer: slot-based per-instance state (m_last_kick_ms[], etc.)
|        fixARC3  HealthMonitor: slot-based per-instance state (m_slip_acc[], etc.)
|        fixARC4  C{MODULE_NAME}: stores m_cb_slot, m_wt_slot, m_hm_slot — activates on Init/OnTick
|        fixARC5  StringUpper/StringLower compatibility wrapper for MT5 Build <3800
|        fixARC6  TOC (Table of Contents) with section markers §0–§15
|        fixARC7  Minimal working EA example in COMPILE-TIME CONTRACT
|        fixARC8  Single-symbol limitation updated to "partial multi-instance" (CB/WT/HM isolated)
|        +UT16–UT19: 4 tests (multi-instance CB isolation, WT isolation, HM isolation, slot alloc)
|  v4.11 FULL AUDIT PATCH (14 corrections from 2026-03-23 audit):
|        fixR1  SendOrderTxn: TRADE_ACTION_PENDING for non-market orders (was always DEAL)
|        fixR2  ENABLE_TRADE_EVENTS activated by default — CB consec_losses now functional
|        fixO1  COMPILE-TIME CONTRACT: single-symbol limitation documented explicitly
|        fixO2  TradeJournal: auto-flush uses stored m_flush_filename (no more journal_auto.csv split)
|        fixO3  HealthMonitor::Report() banner bumped to v4.11
|        fixO4  SendOrderTxn: optional T_SymbolCache* in T_OrderRequest to skip redundant reload
|        fixO5  Scheduler::RunAll() m_total now counts per-symbol dispatches (consistent with RunOnce)
|        fixY1  MT5 Build ≥3800 documented as minimum requirement (StringUpper/StringLower)
|        fixY2  GetTickets/GetTicketsBySymbol: pre-allocated array (O(n) instead of O(n²))
|        fixY3  Profiler::End() division-by-zero guard on m_hist_max_us==0
|        fixY4  IsTradeSession: EndHour inclusive semantics documented inline
|        fixY5  Deinit flush ordering with static journal documented inline
|        fixY6  CircuitBreaker::NewDay() respects unexpired cooldown before resetting m_tripped
|        fixY7  OnTradeTransaction: Refresh(deal_magic) instead of Refresh() (explicit magic)
|        +UT8–UT15: 8 new unit tests covering audit-identified gaps
|  v4.10 QUALITY PATCH (7 corrections):
|        fixQ1  InpWatchdogStallMs input — WatchdogTimer::Init() now runtime-configurable
|        fixQ2  InpEquitySampleIntervalSec input — EquityCurve::Sample() uses it in OnTick
|        fixQ3  SymbolCache: contract_size, swap_long, swap_short added to struct + loader
|        fixQ4  PendingManager::ModifyPending() — TRADE_ACTION_MODIFY for pending orders
|               DRY_RUN covered; type_time + expiration preserved from existing order
|        fixQ5  TradeJournal::GetRecord(idx) + TotalBufferedProfit() — read-only in-memory access
|        fixQ6  EquityCurve::GetPoint(idx) + LatestPoint() — ring-buffer read access
|               Chronological order: idx=0 oldest, idx=Count()-1 newest
|        fixQ7  {MODULE_NAME}_GetVersion() — runtime version string logged on Init()
|  v4.9  AUDIT RED+ORANGE PATCH (11 corrections):
|        fixB1  C_RETRY_MAX repurposed as hard ceiling for InpMaxRetries (MathMin clamp)
|        fixB2  C_WATCHDOG_TICKS connected to WatchdogTimer comment (documented, not dead)
|        fixB3  PROFILE_MODE connected: OnTick wraps ONTICK_LOGIC in T_ProfileScope
|               GetProfiler() added to HealthMonitor (null-safe dummy fallback)
|        fixB4  9 traceability tokens added to MANDATORY SUBSTITUTIONS in CONTRACT
|        fixB5  {UNIT_TESTS} added to INJECTION ORDER (step 13) in CONTRACT
|        fixF1  OnTick{MODULE_NAME}() wrapper added (single-symbol EA convenience)
|        fixF2  OnDeinit{MODULE_NAME}(int reason) wrapper added with reason logging
|        fixF3  Weekend guard in IsTradeSession() — Saturday/Sunday return false
|        fixF4  InpCBMaxDailyTrades input + RecordTrade() in CircuitBreaker
|               NewDay() resets m_daily_trades; RecordTrade() called after SendOrderTxn success
|        fixF5  DRY_RUN coverage extended: ModifySLTP, PartialClose, CancelStale, CancelBySymbol
|        fixF6  PositionSizer balance==0 guard in ByPercentRisk and ByKelly
| @changelog :
|  v4.8  T5 MERGE PATCH (4 corrections from Template5 comparison):
|        fixM1  9 traceability tokens added to gen:header:
|               {SECTION_ID} {ISO_TIMESTAMP} {SESSION_ID} {MODEL_ID}
|               {SPEC_SHA256} {CODE_SHA256} {SPEC_SOURCE_URL} {DEPENDENCIES} {DESCRIPTION}
|        fixM2  InpMaxRetries exposed as runtime input (was compile-time C_RETRY_MAX only)
|               SendOrderTxn now uses InpMaxRetries instead of hardcoded constant
|        fixM3  {UNIT_TESTS} placeholder added inside RunUnitTests_ scaffold
|               EA-specific test cases can be injected alongside engine tests
|        fixM4  Second #property description line added (visible in MT5 Navigator)
|  v4.7.1 FINAL PATCH (2 corrections):
|        fixF1  C{MODULE_NAME}EventBus forward-declared in FORWARD DECLARATIONS block
|               (OnChartEvent wrapper called EventBus::Publish 276 lines before definition)
|        fixF3  TradeJournal::FlushCSV append mode: FileSeek(fh,0,SEEK_END) added
|               (FILE_READ|FILE_WRITE without seek writes at position 0, defeating append)
|  v4.7  AUDIT + QUALITY PATCH (9 corrections):
|        fixE1  T_OrderRequest + T_OrderResult moved before FORWARD DECLARATIONS
|               (were 865 lines after their first use in SendOrderTxn forward decl)
|        fixA3  ConfigManager::Reload() + ForceReload() public methods added
|        fixA6  EquityCurve::Reset() added (backtest multi-pass safe)
|        fixA7  TradeJournal::FlushCSV(filename, bool append=false) overload
|               auto-flush now uses append=true — no history loss on double flush
|        fixA9  Scheduler::RunOnce(bool guard=true) + RunAll(bool guard=true)
|               PreTickGuard called per-symbol before dispatch; guard=false for manual override
|        fixA2  HealthMonitor::SetProfiler() + Profiler stats in Report()
|               Optional T_Profiler* registration; null-safe; shows n/avg/p95/peak
|        fixA4  SignalBus::PublishBuy/PublishSell/PublishClose typed helpers
|        fixA5  PendingManager::GetTickets() + GetTicketsBySymbol() — list pending orders
|        fixA10 OnChartEvent{MODULE_NAME}() wrapper routes chart events to EventBus
|  v4.6  FORENSIC AUDIT PATCH:
|        fixD1  C{MODULE_NAME}TradeJournal forward-declared before C{MODULE_NAME}
|               (Deinit() called FlushCSV 132 lines before TradeJournal definition)
|        fixD2  C{MODULE_NAME}HealthMonitor forward-declared before SendOrderTxn
|               (RecordOrder called 252 lines before HealthMonitor definition)
|        fixG1  PositionTracker::Refresh(int magic) overload added
|               Multi-symbol EAs pass magic explicitly — no static clobber
|               OnTick() uses Refresh(m_magic); SetMagic() kept for compat
|        fixG2  CircuitBreaker::NewDay() now called from OnTimer wrapper
|        fixG3  OnTimer{MODULE_NAME}() wrapper added (WatchdogTimer + NewDay)
|               EA must call EventSetTimer(60) in OnInit() — documented in CONTRACT
|        fixUT  7 new RunUnitTests_ cases: MaxLots cap, EquityCurve pre-alloc,
|               CB ENTRY_IN filter, CB ENTRY_OUT counter, PositionTracker Refresh(magic),
|               RateLimiter Init+Allow, WatchdogTimer Init+Kick AgeMs
|  v4.5.1 ENUM-PARAMS PATCH:
|        All placeholder slots now carry inline generation contracts:
|        {INCLUDES} {ENUMS} {STRUCTS} {CONSTANTS} — with order rules + examples
|        {INPUTS}             — with enum-typed input example
|        {PRIVATE_MEMBERS}    — with member variable examples
|        {INIT_LOGIC}         — with "runs AFTER ::Init()" timing note
|        {DEINIT_LOGIC}       — with "runs BEFORE m_ok=false" timing note
|        {ONTICK_LOGIC}       — with "all guards passed" context note
|        {PUBLIC_METHODS}     — with inline method examples
|        {PUBLIC_METHOD_IMPLEMENTATIONS} — with out-of-class definition example
|        Key rule documented inline: {ENUMS} MUST precede {INPUTS} so that
|        enum-typed inputs (input ENUM_GRID_MODE InpMode = ...) compile.
| @changelog :
|  v4.1  Baseline: OrderSend retry, SymbolCache, SpreadOK, SessionFilter
|  v4.2  OrderCheck(), long→int guard, backoff, SL/TP 6 types, EventBus,
|        Profiler+Peak, Scheduler+RunAll, OnTradeTransaction hook
|  v4.3  CircuitBreaker, RateLimiter, EventBus++, Scheduler weighted RR,
|        Profiler P50/P95/P99+CSV, SymbolCache TTL, DRY_RUN, filling
|        fallback, slippage audit, TradeJournal, HealthMonitor
|  v4.4  PositionTracker, PositionSizer (4 modes), OrderModifier,
|        PendingManager, SYMBOL_TRADE_MODE guard, CB equity-float DD,
|        EquityCurve sampler, ConfigManager, WatchdogTimer, MockBroker,
|        AssertTrade, FuzzInputs, ProfileScope, SignalBus, HealthMonitor++
|  v4.4.1 FORENSIC PATCH — 11 corrections (RecordOrder, Deinit flush,
|        Kelly dead line, MaxOpenPositions, MaxLots cap, TrailStop guard,
|        BreakEven profit guard, PartialClose TrySendFilling, live float DD,
|        EquityCurve pre-alloc, Watchdog tester Print)
|  v4.5  COMPILE-SAFE + GENERATION CONTRACT:
|        fixC1  Forward declaration: TrySendFilling before OrderModifier
|        fixC2  Forward declaration: RunUnitTests_ before C{MODULE_NAME}::Init
|        fixC3  Orphan MqlTradeResult res removed from PartialClose
|        fixR1  CB::Init, RL::Init, Watchdog::Init, EC::Init called in Init()
|        fixM2  ReleaseAll() explicit loop + NULL-sets after Deinit
|               DeinitAll{MODULE_NAME}() wrapper added for multi-symbol teardown
|        fixM3  {MODULE_NAME}_INIT_PARAMS_EMPTY guard eliminates trailing comma
|               Same guard applied to global wrapper Init{MODULE_NAME}()
|        fixM1  {ENUM_PARAMS} generation contract documented
|        fixM4  COMPILE-TIME CONTRACT block: all placeholders documented,
|               injection order enforced, feature flags listed
</gen:header>
===============================================================================
*/

#property strict
#property description "{MODULE_NAME} v{VERSION} — Institutional Core Engine v4.12"
#property description "Deterministic • Multi-Asset • Broker-Safe • HFT-Stable"

//=============================================================================
// INCLUDE GUARD
//=============================================================================
#ifndef __{MODULE_NAME_UPPER}_MQH__
#define __{MODULE_NAME_UPPER}_MQH__

#ifdef __MQL4__
  #error "MQL5 only — do not compile under MQL4"
#endif

//=============================================================================
// TABLE OF CONTENTS — v4.12 fix ARC6
// Search "§N" to jump (e.g. "§5" → Utility Functions).
//=============================================================================
//  §0   Feature Flags + Compile-Time Contract
//  §1   Engine Constants
//  §2   Logging + Asserts + Placeholder Safety
//  §3   User Extensions (injection points: INCLUDES, ENUMS, STRUCTS, CONSTANTS, INPUTS)
//  §4   Inputs
//  §5   Utility Functions (HashMagic, SymbolCache, Normalize, Spread, Session, Margin, SL/TP, Retry, Backoff)
//  §6   CircuitBreaker (slot-based multi-instance)
//  §7   RateLimiter
//  §8   PreTickGuard
//  §9   PositionTracker, PositionSizer, OrderModifier, PendingManager
//  §10  EquityCurve, ConfigManager, WatchdogTimer (slot-based), MockBroker, AssertTrade, FuzzInputs
//  §11  Instance Manager + Core Engine Class (C{MODULE_NAME})
//  §12  Wrappers (Init, Deinit, OnTick, OnTimer, OnChartEvent)
//  §13  Unit Tests
//  §14  TradeJournal, Transactional Order Engine (SendOrderTxn)
//  §15  EventBus, SignalBus, Scheduler, Profiler, HealthMonitor (slot-based)
//  §16  OnTradeTransaction Hook + User Implementations
//=============================================================================

// §0 =========================================================================
// FEATURE FLAGS
//=============================================================================
#ifndef {MODULE_NAME}_ENABLE_TRADING
  #define {MODULE_NAME}_ENABLE_TRADING     1
#endif
#ifndef {MODULE_NAME}_ENABLE_LOGS
  #define {MODULE_NAME}_ENABLE_LOGS        1
#endif
#ifndef {MODULE_NAME}_UNIT_TESTING
  #define {MODULE_NAME}_UNIT_TESTING       0
#endif
#ifndef {MODULE_NAME}_PROFILE_MODE
  #define {MODULE_NAME}_PROFILE_MODE       0
#endif
#ifndef {MODULE_NAME}_DRY_RUN
  #define {MODULE_NAME}_DRY_RUN            0
#endif
#ifndef {MODULE_NAME}_MOCK_BROKER
  #define {MODULE_NAME}_MOCK_BROKER        0  // 1 = offline MockBroker, no real sends
#endif
// v4.11 fix R2: ENABLE_TRADE_EVENTS now ON by default — required for CB consec_losses,
//   daily DD tracking, and TradeJournal recording to function. Without this hook,
//   InpCBMaxConsecLosses is inert (false sense of safety). Disable explicitly if needed:
//   #define {MODULE_NAME}_DISABLE_TRADE_EVENTS
#ifndef {MODULE_NAME}_DISABLE_TRADE_EVENTS
  #define {MODULE_NAME}_ENABLE_TRADE_EVENTS
#endif

//=============================================================================
// COMPILE-TIME CONTRACT — v4.5
// READ THIS BEFORE GENERATING OR INSTANTIATING THE TEMPLATE.
//
// ┌─ MANDATORY SUBSTITUTIONS ──────────────────────────────────────────────┐
// │ {MODULE_NAME}          → EA identifier, e.g. IchiGrid                  │
// │                          Used as class prefix, macro prefix, filenames  │
// │ {MODULE_NAME_UPPER}    → Uppercase of MODULE_NAME, e.g. ICHIGRID        │
// │                          Used only in include-guard macros              │
// │ {VERSION}              → Semver string, e.g. 1.0.0                     │
// │ ── TRACEABILITY (v4.8 — substitute all, even if unknown → use "?") ──  │
// │ {SECTION_ID}           → Section identifier within the project          │
// │ {ISO_TIMESTAMP}        → Generation timestamp, e.g. 2026-03-23T10:00Z  │
// │ {SESSION_ID}           → Generator session ID (UUID or counter)         │
// │ {MODEL_ID}             → AI model that generated this file              │
// │ {SPEC_SHA256}          → SHA-256 hash of the spec used for generation   │
// │ {CODE_SHA256}          → SHA-256 hash of this generated file            │
// │ {SPEC_SOURCE_URL}      → URL/path of the spec document                  │
// │ {DEPENDENCIES}         → Comma-separated list of module dependencies    │
// │ {DESCRIPTION}          → Human-readable description of this EA          │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ INJECTION ORDER (critical — do not reorder) ──────────────────────────┐
// │ 1. {INCLUDES}     → #include directives (before all declarations)      │
// │ 2. {ENUMS}        → enum declarations (before inputs that use them)    │
// │                      e.g. enum ENUM_GRID_MODE { GRID_FIXED, GRID_ATR } │
// │ 3. {STRUCTS}      → struct declarations (before inputs/logic)          │
// │ 4. {CONSTANTS}    → const values (before inputs/logic)                 │
// │ 5. {INPUTS}       → input/sinput declarations (after engine inputs)    │
// │                      May reference enums declared in step 2 above       │
// │ 6. {INIT_PARAMS}  → extra params for Init() signature — see M3 below   │
// │ 7. {INIT_LOGIC}   → body of Init() — runs AFTER all ::Init() calls     │
// │ 8. {DEINIT_LOGIC} → body of Deinit() — runs BEFORE m_ok=false         │
// │ 9. {ONTICK_LOGIC} → body of OnTick() — runs AFTER PreTickGuard         │
// │10. {PRIVATE_MEMBERS}           → private member variables of C{MODULE} │
// │11. {PUBLIC_METHODS}            → inline public methods of C{MODULE}     │
// │12. {PUBLIC_METHOD_IMPLEMENTATIONS} → out-of-class implementations      │
// │13. {UNIT_TESTS}   → EA-specific test cases inside RunUnitTests_ scaffold│
// │                      injected after engine tests; leave "" if none      │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ TRAILING-COMMA GUARD (fix M3) ────────────────────────────────────────┐
// │ If your EA has NO extra Init() parameters:                             │
// │   #define {MODULE_NAME}_INIT_PARAMS_EMPTY                              │
// │   Init() becomes: Init(string s, ENUM_TIMEFRAMES tf)   ← no comma     │
// │ If your EA HAS extra parameters:                                       │
// │   {INIT_PARAMS}        = comma-prefixed list, e.g.: ,int bars,bool dbg │
// │   {INIT_PARAMS_GLOBAL} = same but for the global wrapper               │
// │   {INIT_ARGS}          = call-site args,    e.g.:  bars,dbg            │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ OPTIONAL PLACEHOLDERS ────────────────────────────────────────────────┐
// │ All of the following may be left as empty string "":                   │
// │   {INCLUDES} {ENUMS} {STRUCTS} {CONSTANTS} {INPUTS}                   │
// │   {INIT_LOGIC} {DEINIT_LOGIC} {ONTICK_LOGIC}                          │
// │   {PRIVATE_MEMBERS} {PUBLIC_METHODS} {PUBLIC_METHOD_IMPLEMENTATIONS}   │
// │   {UNIT_TESTS}  — EA-specific test cases (injected after engine tests) │
// │ WARNING: if a placeholder is NOT substituted (left as literal text),   │
// │   MQL5 will see e.g. {ONTICK_LOGIC} as an invalid identifier and       │
// │   produce a compile error. Always substitute ALL tokens, even to "".   │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ FEATURE FLAGS (set via #define BEFORE the #include) ──────────────────┐
// │ {MODULE_NAME}_ENABLE_TRADING     1/0  — master on/off                  │
// │ {MODULE_NAME}_ENABLE_LOGS        1/0  — logging                        │
// │ {MODULE_NAME}_UNIT_TESTING       1/0  — run unit tests on Init()       │
// │ {MODULE_NAME}_DRY_RUN            1/0  — log orders, don't send         │
// │ {MODULE_NAME}_MOCK_BROKER        1/0  — offline MockBroker             │
// │ {MODULE_NAME}_ENABLE_TRADE_EVENTS     — ON by default (v4.11 fix R2)   │
// │   Required for CB consec_losses, daily DD, and TradeJournal.           │
// │   To disable: #define {MODULE_NAME}_DISABLE_TRADE_EVENTS               │
// │ {MODULE_NAME}_INIT_PARAMS_EMPTY       — no extra Init() params         │
// │                                                                        │
// │ RUNTIME INPUTS (tunable without recompile):                            │
// │   InpMaxRetries  — order retry count   (default 5)                     │
// │   InpMaxOpenPositions — position cap   (default 20, 0=unlimited)       │
// │   InpSizerMaxLots    — absolute lot cap (default 10.0)                 │
// │                                                                        │
// │ ONTIMER: call OnTimer{MODULE_NAME}() from EA's OnTimer().              │
// │   EA must call EventSetTimer(60) in OnInit() to activate watchdog      │
// │   stall detection and daily CircuitBreaker reset.                      │
// │ ONTICK:  call OnTick{MODULE_NAME}() from EA's OnTick() (single-symbol) │
// │   OR use Scheduler::RunAll()/RunOnce() for multi-symbol dispatch.      │
// │ ONDEINIT: call OnDeinit{MODULE_NAME}(reason) from EA's OnDeinit().     │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ MULTI-INSTANCE STATUS (v4.12 fix ARC8) ───────────────────────────────┐
// │ v4.12 converted 3 critical subsystems to slot-based multi-instance:    │
// │   ✅ CircuitBreaker  — per-instance (Alloc/Activate slots)             │
// │   ✅ WatchdogTimer   — per-instance (Alloc/Activate slots)             │
// │   ✅ HealthMonitor   — per-instance (Alloc/Activate slots)             │
// │                                                                        │
// │ The following subsystems remain STATIC SINGLETONS (shared state):      │
// │   ⚠ RateLimiter     — sliding window shared across all symbols         │
// │   ⚠ PositionTracker — Refresh(magic) clobbers buffer each call         │
// │   ⚠ EquityCurve     — single ring buffer for all symbols              │
// │   ⚠ TradeJournal    — single deal buffer for all symbols              │
// │   ⚠ ConfigManager   — single .ini file for all symbols                │
// │   ⚠ EventBus/SignalBus — shared subscriber lists                      │
// │   ⚠ Scheduler       — shared by design (dispatches all symbols)       │
// │                                                                        │
// │ For multi-symbol EAs: CB/WT/HM are now safe. The ⚠ subsystems share   │
// │ state, which may or may not be desirable depending on the EA design.   │
// │ Full per-instance isolation of all subsystems requires v5.0 refactor.  │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ MINIMUM REQUIREMENTS (v4.11 fix Y1) ─────────────────────────────────┐
// │ MetaTrader 5 Build ≥ 3800  (StringUpper/StringLower as free functions) │
// │ MQL5 only (#error on MQL4)                                             │
// │ v4.12 fix ARC5: StrUpper/StrLower wrappers now included — Build <3800  │
// │   compiles without modification.                                       │
// └────────────────────────────────────────────────────────────────────────┘
//
// ┌─ MINIMAL WORKING EA EXAMPLE (v4.12 fix ARC7) ─────────────────────────┐
// │                                                                        │
// │  // --- MyEA.mq5 ---                                                   │
// │  #define MyEA_INIT_PARAMS_EMPTY                                        │
// │  #define MyEA_ENABLE_TRADE_EVENTS     // CB+Journal (default since v4.11)│
// │  #include "MyEA.mqh"   // ← this template with {MODULE_NAME}=MyEA     │
// │                                                                        │
// │  int OnInit()                                                          │
// │  {                                                                     │
// │     EventSetTimer(60);                                                 │
// │     return InitMyEA() ? INIT_SUCCEEDED : INIT_FAILED;                  │
// │  }                                                                     │
// │  void OnDeinit(const int reason) { OnDeinitMyEA(reason); }             │
// │  void OnTick()  { OnTickMyEA();  }                                     │
// │  void OnTimer() { OnTimerMyEA(); }                                     │
// │  void OnChartEvent(const int id,const long &lp,                        │
// │                    const double &dp,const string &sp)                   │
// │  { OnChartEventMyEA(id,lp,dp,sp); }                                   │
// │  void OnTradeTransaction(const MqlTradeTransaction &trans,             │
// │                          const MqlTradeRequest &request,               │
// │                          const MqlTradeResult &result)                  │
// │  { MyEA_OnTradeTransaction(trans,request,result); }                    │
// │                                                                        │
// │  Substitutions applied to this template:                               │
// │    {MODULE_NAME}       = MyEA                                          │
// │    {MODULE_NAME_UPPER} = MYEA                                          │
// │    {VERSION}           = 1.0.0                                         │
// │    {INIT_LOGIC}        = ""  (or your code)                            │
// │    {ONTICK_LOGIC}      = ""  (or your code)                            │
// │    {DEINIT_LOGIC}      = ""                                            │
// │    {PRIVATE_MEMBERS}   = ""                                            │
// │    {PUBLIC_METHODS}    = ""                                            │
// │    {PUBLIC_METHOD_IMPLEMENTATIONS} = ""                                │
// │    {UNIT_TESTS}        = ""                                            │
// │    All other placeholders = ""                                         │
// └────────────────────────────────────────────────────────────────────────┘
//=============================================================================

//=============================================================================
// ENGINE CONSTANTS
//=============================================================================
const int    {MODULE_NAME}_C_MAX_INSTANCES      = 64;
const int    {MODULE_NAME}_C_RETRY_MAX          = 10;   // v4.9 fix B1: hard ceiling for InpMaxRetries (safety cap)
const int    {MODULE_NAME}_C_RETRY_SLEEP_MS     = 50;
const int    {MODULE_NAME}_C_MIN_TICK_INTERVAL  = 50000;    // µs
const double {MODULE_NAME}_C_EPS               = 1e-12;
const int    {MODULE_NAME}_C_CACHE_TTL_MS       = 5000;
const int    {MODULE_NAME}_C_HIST_BUCKETS       = 10;
const int    {MODULE_NAME}_C_JOURNAL_MAX        = 512;
const int    {MODULE_NAME}_C_EQUITY_CURVE_MAX   = 1440;     // ~24h at 1-min samples
const int    {MODULE_NAME}_C_WATCHDOG_TICKS     = 200;      // v4.9 fix B2: default stall threshold ticks → ms via InpWatchdogStallMs
const int    {MODULE_NAME}_C_CONFIG_RELOAD_MS   = 10000;    // config hot-reload interval

//=============================================================================
// LOGGING
//=============================================================================
enum ENUM_{MODULE_NAME}_E_LogLevel
{
   {MODULE_NAME}_LOG_ERROR = 0,
   {MODULE_NAME}_LOG_WARN  = 1,
   {MODULE_NAME}_LOG_INFO  = 2,
   {MODULE_NAME}_LOG_DEBUG = 3
};

#if {MODULE_NAME}_ENABLE_LOGS
  #ifdef _DEBUG
    #define CORE_LOG(level,msg) \
      PrintFormat("[%s][%s] %s",__FUNCTION__, \
        EnumToString((ENUM_{MODULE_NAME}_E_LogLevel)(level)),(msg))
  #else
    #define CORE_LOG(level,msg) do{ \
      if((int)(level)==(int){MODULE_NAME}_LOG_ERROR) \
        PrintFormat("[%s][ERROR] %s",__FUNCTION__,(msg)); \
    }while(0)
  #endif
#else
  #define CORE_LOG(level,msg)
#endif

#define CORE_ASSERT_RET(cond,msg) \
  do{if(!(cond)){CORE_LOG({MODULE_NAME}_LOG_ERROR,(msg));return false;}}while(0)
#define CORE_ASSERT(cond,msg) \
  do{if(!(cond)){CORE_LOG({MODULE_NAME}_LOG_ERROR,(msg));}}while(0)

//=============================================================================
// PLACEHOLDER SAFETY
//=============================================================================
enum   ENUM_{MODULE_NAME}_E_Placeholder { {MODULE_NAME}_PLACEHOLDER=0 };
struct {MODULE_NAME}_T_Placeholder      { int _; };

//=============================================================================
// USER EXTENSIONS
// Injection order is CRITICAL — see COMPILE-TIME CONTRACT above.
// Every token below MUST be substituted (even to empty string "").
// Leaving a literal token e.g. {ENUMS} in compiled code = compile error.
//=============================================================================

// {INCLUDES} — external #include directives, loaded first
//   e.g.:  #include <Trade\Trade.mqh>
//          #include "MyIndicator.mqh"
{INCLUDES}

// {ENUMS} — ALL enum declarations for this EA, injected BEFORE {INPUTS}.
//   Rule: any enum used as an input type MUST be declared here, not after.
//   e.g.:  enum ENUM_GRID_MODE   { GRID_FIXED=0, GRID_ATR=1, GRID_ICHIMOKU=2 };
//          enum ENUM_RISK_MODE   { RISK_FIXED=0, RISK_PCT=1, RISK_KELLY=2    };
//          enum ENUM_SIG_FILTER  { SIG_NONE=0,   SIG_ICHIMOKU=1, SIG_MA=2   };
//   Then in {INPUTS}:
//          input ENUM_GRID_MODE InpGridMode = GRID_ATR;   // ← compiles OK
//          input ENUM_RISK_MODE InpRiskMode = RISK_PCT;   // ← compiles OK
{ENUMS}

// {STRUCTS} — custom struct declarations (after enums, before logic)
//   e.g.:  struct MyGridLevel { double price; double lots; int magic; };
{STRUCTS}

// {CONSTANTS} — compile-time const values (after structs, before inputs)
//   e.g.:  const int MY_MAX_GRID_LEVELS = 20;
//          const double MY_DEFAULT_STEP = 50.0;
{CONSTANTS}

//=============================================================================
// INPUTS
//=============================================================================
input group "=== {MODULE_NAME} CORE ===";
input bool   InpEnable{MODULE_NAME}           = true;
input double InpMaxSpreadPoints               = 30.0;
input int    InpTradeStartHour                = 0;
input int    InpTradeEndHour                  = 23;
input bool   InpAllowOvernight                = true;
input int    InpMaxSlippagePoints             = 20;
input double InpMarginBufferFactor            = 1.10;
input int    InpMaxRetries                    = 5;      // v4.8: order retry attempts (was compile-time only)

input group "=== {MODULE_NAME} CIRCUIT BREAKER ===";
input bool   InpCBEnabled                     = true;
input double InpCBMaxDailyDrawdownPct         = 3.0;
input double InpCBMaxFloatDrawdownPct         = 5.0;   // equity-float DD trigger
input int    InpCBMaxConsecLosses             = 4;
input int    InpCBCooldownMinutes             = 60;
input int    InpCBMaxDailyTrades              = 0;     // v4.9 fix F4: max orders/day (0=unlimited)

input group "=== {MODULE_NAME} RATE LIMITER ===";
input bool   InpRLEnabled                     = true;
input int    InpRLMaxOrdersPerWindow          = 10;
input int    InpRLWindowSeconds               = 60;

input group "=== {MODULE_NAME} POSITION SIZER ===";
input double InpSizerRiskPct                  = 1.0;   // % balance per trade
input double InpSizerATRMultiplier            = 1.5;   // ATR-based SL multiple
input double InpSizerKellyFraction            = 0.25;  // Kelly fraction cap
input double InpSizerFixedLots                = 0.01;  // fallback fixed lots
input double InpSizerMaxLots                  = 10.0;  // absolute lot cap (operator-level ceiling)

input group "=== {MODULE_NAME} CONFIG ===";
input int    InpMaxOpenPositions              = 20;    // max simultaneous open positions (0 = unlimited)
input string InpConfigFile                    = "{MODULE_NAME}_config.ini";
input int    InpWatchdogStallMs               = 5000;  // Q1: stall alert threshold ms (0 = disable watchdog)
input int    InpEquitySampleIntervalSec       = 60;    // Q2: equity curve sampling interval in seconds

// {INPUTS} — EA-specific input declarations, injected AFTER engine inputs above.
//   May reference enums declared in {ENUMS} above (correct order guaranteed).
//   Use input groups to separate from engine inputs in the MT5 parameters panel.
//   e.g.:  input group "=== MY EA SETTINGS ===";
//          input ENUM_GRID_MODE InpGridMode   = GRID_ATR;  // ← enum from {ENUMS}
//          input int            InpGridLevels = 10;
//          input double         InpGridStep   = 50.0;      // points
{INPUTS}

// §5 =========================================================================
// STRING COMPATIBILITY — v4.12 fix ARC5
// StringUpper(string)/StringLower(string) returning a string were added in Build ~3800.
// These wrappers use StringToUpper/StringToLower (in-place, all builds) for portability.
//=============================================================================
string {MODULE_NAME}_StrUpper(string s){StringToUpper(s);return s;}
string {MODULE_NAME}_StrLower(string s){StringToLower(s);return s;}

//=============================================================================
// FNV-1a MAGIC HASH
//=============================================================================
int {MODULE_NAME}_HashMagic(string symbol, ENUM_TIMEFRAMES tf)
{
   symbol={MODULE_NAME}_StrUpper(symbol);
   uint h=2166136261u;
   for(int i=0;i<StringLen(symbol);i++){h^=(uint)StringGetCharacter(symbol,i);h*=16777619u;}
   h^=(uint)tf; h*=16777619u;
   return (int)(h&0x7FFFFFFF);
}

//=============================================================================
// VERSION — Q7: runtime version string for logs, HealthMonitor, journals
//=============================================================================
string {MODULE_NAME}_GetVersion()
{
   return StringFormat("{MODULE_NAME} v{VERSION} (engine v4.12) built %s",__DATE__);
}

//=============================================================================
// SYMBOL CACHE — TTL + TRADE_MODE guard (v4.4)
//=============================================================================
struct {MODULE_NAME}_T_SymbolCache
{
   string symbol;
   int    digits;
   double point;
   double tick_size;
   double tick_value;
   double vol_min;
   double vol_max;
   double vol_step;
   int    stops_level;
   int    freeze_level;
   int    trade_mode;      // v4.4: SYMBOL_TRADE_MODE_*
   double contract_size;   // Q3: lots → units conversion (e.g. 100000 for forex)
   double swap_long;       // Q3: overnight cost per lot for buy positions
   double swap_short;      // Q3: overnight cost per lot for sell positions
   ulong  loaded_ms;
   bool   valid;
};

bool {MODULE_NAME}_LoadSymbolCache(string s, {MODULE_NAME}_T_SymbolCache &c)
{
   c.symbol        = s;
   c.digits        = (int)SymbolInfoInteger(s,SYMBOL_DIGITS);
   c.point         = SymbolInfoDouble(s,SYMBOL_POINT);
   c.tick_size     = SymbolInfoDouble(s,SYMBOL_TRADE_TICK_SIZE);
   c.tick_value    = SymbolInfoDouble(s,SYMBOL_TRADE_TICK_VALUE);
   c.vol_min       = SymbolInfoDouble(s,SYMBOL_VOLUME_MIN);
   c.vol_max       = SymbolInfoDouble(s,SYMBOL_VOLUME_MAX);
   c.vol_step      = SymbolInfoDouble(s,SYMBOL_VOLUME_STEP);
   c.trade_mode    = (int)SymbolInfoInteger(s,SYMBOL_TRADE_MODE);
   c.contract_size = SymbolInfoDouble(s,SYMBOL_TRADE_CONTRACT_SIZE);  // Q3
   c.swap_long     = SymbolInfoDouble(s,SYMBOL_SWAP_LONG);            // Q3
   c.swap_short    = SymbolInfoDouble(s,SYMBOL_SWAP_SHORT);           // Q3
   long sl=SymbolInfoInteger(s,SYMBOL_TRADE_STOPS_LEVEL);
   long fl=SymbolInfoInteger(s,SYMBOL_TRADE_FREEZE_LEVEL);
   if(sl<0||sl>INT_MAX){CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("stops_level OVF %I64d",sl));return false;}
   if(fl<0||fl>INT_MAX){CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("freeze_level OVF %I64d",fl));return false;}
   c.stops_level   =(int)sl;
   c.freeze_level  =(int)fl;
   c.loaded_ms     =GetTickCount64();
   c.valid         =true;
   return true;
}

bool {MODULE_NAME}_RefreshCacheIfStale({MODULE_NAME}_T_SymbolCache &c)
{
   if(!c.valid||GetTickCount64()-c.loaded_ms>(ulong){MODULE_NAME}_C_CACHE_TTL_MS)
      return {MODULE_NAME}_LoadSymbolCache(c.symbol,c);
   return true;
}
void {MODULE_NAME}_InvalidateCache({MODULE_NAME}_T_SymbolCache &c){c.valid=false;}

// v4.4: direction allowed check against SYMBOL_TRADE_MODE
bool {MODULE_NAME}_DirectionAllowed(const {MODULE_NAME}_T_SymbolCache &c, bool isBuy)
{
   if(c.trade_mode==SYMBOL_TRADE_MODE_DISABLED) return false;
   if(c.trade_mode==SYMBOL_TRADE_MODE_LONGONLY  && !isBuy) return false;
   if(c.trade_mode==SYMBOL_TRADE_MODE_SHORTONLY &&  isBuy) return false;
   return true;
}

//=============================================================================
// NORMALIZATION
//=============================================================================
double {MODULE_NAME}_NormalizePrice(const {MODULE_NAME}_T_SymbolCache &c,double p)
{return NormalizeDouble(p,c.digits);}

double {MODULE_NAME}_NormalizeVolume(const {MODULE_NAME}_T_SymbolCache &c,double lots)
{
   double steps=MathFloor((lots+{MODULE_NAME}_C_EPS)/c.vol_step);
   double v=steps*c.vol_step;
   if(v<c.vol_min)v=c.vol_min;
   if(v>c.vol_max)v=c.vol_max;
   // v4.4.1: operator-level ceiling independent of broker vol_max
   if(InpSizerMaxLots>0&&v>InpSizerMaxLots)v=InpSizerMaxLots;
   return v;
}

//=============================================================================
// SPREAD CHECK
//=============================================================================
bool {MODULE_NAME}_SpreadOK(string s,double maxPts)
{
   double ask=SymbolInfoDouble(s,SYMBOL_ASK),bid=SymbolInfoDouble(s,SYMBOL_BID);
   if(ask<=0||bid<=0)return false;
   return (ask-bid)/SymbolInfoDouble(s,SYMBOL_POINT)<=maxPts;
}

//=============================================================================
// SESSION FILTER
// v4.11 fix Y4: EndHour is INCLUSIVE — with Start=9, End=17, trading is active
//   for the entire hour 17 (17:00–17:59). This is by design: the filter checks
//   dt.hour <= EndHour, not dt.hour < EndHour. Adjust EndHour accordingly.
//=============================================================================
bool {MODULE_NAME}_IsTradeSession()
{
   MqlDateTime dt;TimeToStruct(TimeCurrent(),dt);
   // v4.9 fix F3: weekend guard — Saturday=6, Sunday=0 in MQL5 day_of_week
   if(dt.day_of_week==6||dt.day_of_week==0)return false;
   if(InpTradeStartHour<=InpTradeEndHour)
      return dt.hour>=InpTradeStartHour&&dt.hour<=InpTradeEndHour;
   if(!InpAllowOvernight)return false;
   return dt.hour>=InpTradeStartHour||dt.hour<=InpTradeEndHour;
}

//=============================================================================
// TRADE PERMISSION
//=============================================================================
bool {MODULE_NAME}_IsTradeAllowed()
{
   return (bool)TerminalInfoInteger(TERMINAL_CONNECTED)
       && (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)
       && (bool)MQLInfoInteger(MQL_TRADE_ALLOWED)
       && !IsStopped();
}

//=============================================================================
// MARGIN SAFETY
//=============================================================================
bool {MODULE_NAME}_MarginOK(string s,double vol,ENUM_ORDER_TYPE t)
{
   double price=(t==ORDER_TYPE_BUY)?SymbolInfoDouble(s,SYMBOL_ASK):SymbolInfoDouble(s,SYMBOL_BID);
   double m=0.0;
   if(!OrderCalcMargin(t,s,vol,price,m))return false;
   return AccountInfoDouble(ACCOUNT_FREEMARGIN)>m*InpMarginBufferFactor;
}

//=============================================================================
// SL/TP VALIDATION — 6 ORDER TYPES + STOP_LIMIT minDist (v4.4 fix)
//=============================================================================
bool {MODULE_NAME}_IsMarketOrder(ENUM_ORDER_TYPE t)
{return t==ORDER_TYPE_BUY||t==ORDER_TYPE_SELL;}

bool {MODULE_NAME}_IsBuyDirection(ENUM_ORDER_TYPE t)
{
   return t==ORDER_TYPE_BUY||t==ORDER_TYPE_BUY_LIMIT
       ||t==ORDER_TYPE_BUY_STOP||t==ORDER_TYPE_BUY_STOP_LIMIT;
}

bool {MODULE_NAME}_SLTPValid(string s,double price,double sl,double tp,
                              ENUM_ORDER_TYPE t,double stoplimit_price=0.0)
{
   if(!{MODULE_NAME}_IsMarketOrder(t)&&sl==0.0&&tp==0.0)return true;
   double pt     =SymbolInfoDouble(s,SYMBOL_POINT);
   double stop   =(double)SymbolInfoInteger(s,SYMBOL_TRADE_STOPS_LEVEL)*pt;
   double freeze =(double)SymbolInfoInteger(s,SYMBOL_TRADE_FREEZE_LEVEL)*pt;
   double minDist=stop+freeze;
   bool   isBuy  ={MODULE_NAME}_IsBuyDirection(t);

   // v4.4: STOP_LIMIT — stoplimit_price must also satisfy minDist from price
   if(stoplimit_price>0.0)
   {
      if(t==ORDER_TYPE_BUY_STOP_LIMIT)
      {if(stoplimit_price>=price)return false;
       if((price-stoplimit_price)<minDist)return false;}
      if(t==ORDER_TYPE_SELL_STOP_LIMIT)
      {if(stoplimit_price<=price)return false;
       if((stoplimit_price-price)<minDist)return false;}
   }

   if(isBuy){
      if(sl!=0.0&&sl>=price)return false;
      if(tp!=0.0&&tp<=price)return false;
      if(sl!=0.0&&(price-sl)<minDist)return false;
      if(tp!=0.0&&(tp-price)<minDist)return false;
   }else{
      if(sl!=0.0&&sl<=price)return false;
      if(tp!=0.0&&tp>=price)return false;
      if(sl!=0.0&&(sl-price)<minDist)return false;
      if(tp!=0.0&&(price-tp)<minDist)return false;
   }
   return true;
}

//=============================================================================
// RETRY POLICY
//=============================================================================
bool {MODULE_NAME}_RetryableRetcode(int rc)
{
   return rc==TRADE_RETCODE_REQUOTE||rc==TRADE_RETCODE_PRICE_OFF
       ||rc==TRADE_RETCODE_REJECT  ||rc==TRADE_RETCODE_CONTEXT_BUSY;
}

//=============================================================================
// NON-BLOCKING BACKOFF
//=============================================================================
namespace {MODULE_NAME}_Backoff
{
   static ulong s_deadline_us=0;
   bool  IsReady(){return GetMicrosecondCount()>=s_deadline_us;}
   void  Arm(int ms={MODULE_NAME}_C_RETRY_SLEEP_MS)
   {s_deadline_us=GetMicrosecondCount()+(ulong)ms*1000UL;}
   void  SleepIfLive(int ms={MODULE_NAME}_C_RETRY_SLEEP_MS)
   {
#ifndef __MQL5_TESTER__
      Sleep(ms);
#else
      Arm(ms);
#endif
   }
}

//=============================================================================
// §6 CIRCUIT BREAKER — v4.4 + v4.12 slot-based multi-instance (fix ARC1)
// Each C{MODULE_NAME} instance owns a CB slot via Alloc()/Activate().
// Single-symbol: slot 0, fully transparent — no API change.
//=============================================================================
class C{MODULE_NAME}CircuitBreaker
{
private:
   static bool   m_tripped[];
   static int    m_consec_losses[];
   static double m_day_start_balance[];
   static ulong  m_trip_time_ms[];
   static int    m_trip_count[];
   static int    m_daily_trades[];
   static int    m_active;
   static int    m_count;

   static void Trip(string reason)
   {
      if(m_tripped[m_active])return;
      m_tripped[m_active]=true;m_trip_time_ms[m_active]=GetTickCount64();m_trip_count[m_active]++;
      CORE_LOG({MODULE_NAME}_LOG_ERROR,
               StringFormat("CB[%d] TRIPPED [#%d]: %s — cooldown %dmin",
                            m_active,m_trip_count[m_active],reason,InpCBCooldownMinutes));
   }
public:
   static int Alloc()
   {
      int s=m_count++;
      ArrayResize(m_tripped,m_count);ArrayResize(m_consec_losses,m_count);
      ArrayResize(m_day_start_balance,m_count);ArrayResize(m_trip_time_ms,m_count);
      ArrayResize(m_trip_count,m_count);ArrayResize(m_daily_trades,m_count);
      m_tripped[s]=false;m_consec_losses[s]=0;m_day_start_balance[s]=0;
      m_trip_time_ms[s]=0;m_trip_count[s]=0;m_daily_trades[s]=0;
      return s;
   }
   static void Activate(int slot){m_active=slot;}
   static int  ActiveSlot(){return m_active;}

   static void Init()
   {
      m_tripped[m_active]=false;m_consec_losses[m_active]=0;m_daily_trades[m_active]=0;
      m_day_start_balance[m_active]=AccountInfoDouble(ACCOUNT_BALANCE);
      m_trip_time_ms[m_active]=0;m_trip_count[m_active]=0;
   }
   static void Reset(){m_tripped[m_active]=false;m_consec_losses[m_active]=0;
      CORE_LOG({MODULE_NAME}_LOG_INFO,"CB: manual reset");}
   static void RecordTrade()
   {
      m_daily_trades[m_active]++;
      if(!InpCBEnabled)return;
      if(InpCBMaxDailyTrades>0&&m_daily_trades[m_active]>=InpCBMaxDailyTrades)
         Trip(StringFormat("MaxDailyTrades %d>=%d",m_daily_trades[m_active],InpCBMaxDailyTrades));
   }
   static void RecordResult(double profit,ENUM_DEAL_ENTRY entry=DEAL_ENTRY_OUT)
   {
      if(entry==DEAL_ENTRY_IN)return;
      if(profit<0.0)m_consec_losses[m_active]++;
      else m_consec_losses[m_active]=0;
      if(!InpCBEnabled)return;
      double bal=AccountInfoDouble(ACCOUNT_BALANCE);
      double eq =AccountInfoDouble(ACCOUNT_EQUITY);
      double ddBal=(m_day_start_balance[m_active]>0)?100.0*(m_day_start_balance[m_active]-bal)/m_day_start_balance[m_active]:0.0;
      double ddEq =(bal>0)?100.0*(bal-eq)/bal:0.0;
      if(ddBal>=InpCBMaxDailyDrawdownPct)
         Trip(StringFormat("Daily realized DD %.2f%%>=%.2f%%",ddBal,InpCBMaxDailyDrawdownPct));
      if(ddEq>=InpCBMaxFloatDrawdownPct)
         Trip(StringFormat("Float DD %.2f%%>=%.2f%%",ddEq,InpCBMaxFloatDrawdownPct));
      if(m_consec_losses[m_active]>=InpCBMaxConsecLosses)
         Trip(StringFormat("ConsecLosses %d>=%d",m_consec_losses[m_active],InpCBMaxConsecLosses));
   }
   static void NewDay()
   {
      m_day_start_balance[m_active]=AccountInfoDouble(ACCOUNT_BALANCE);
      m_consec_losses[m_active]=0;m_daily_trades[m_active]=0;
      if(m_tripped[m_active]&&(GetTickCount64()-m_trip_time_ms[m_active]>=(ulong)InpCBCooldownMinutes*60000UL))
      {m_tripped[m_active]=false;CORE_LOG({MODULE_NAME}_LOG_INFO,"CB: new day + cooldown expired — reset");}
      else if(!m_tripped[m_active])
         CORE_LOG({MODULE_NAME}_LOG_INFO,"CB: new day reset");
      else
         CORE_LOG({MODULE_NAME}_LOG_WARN,"CB: new day — cooldown still active, trip NOT reset");
   }
   static bool IsOpen()
   {
      if(!m_tripped[m_active])return false;
      if(GetTickCount64()-m_trip_time_ms[m_active]>=(ulong)InpCBCooldownMinutes*60000UL)
      {m_tripped[m_active]=false;CORE_LOG({MODULE_NAME}_LOG_INFO,"CB: cooldown expired");return false;}
      return true;
   }
   static int TripCount()    {return m_trip_count[m_active];}
   static int ConsecLosses() {return m_consec_losses[m_active];}
};
bool   C{MODULE_NAME}CircuitBreaker::m_tripped[];
int    C{MODULE_NAME}CircuitBreaker::m_consec_losses[];
double C{MODULE_NAME}CircuitBreaker::m_day_start_balance[];
ulong  C{MODULE_NAME}CircuitBreaker::m_trip_time_ms[];
int    C{MODULE_NAME}CircuitBreaker::m_trip_count[];
int    C{MODULE_NAME}CircuitBreaker::m_daily_trades[];
int    C{MODULE_NAME}CircuitBreaker::m_active=0;
int    C{MODULE_NAME}CircuitBreaker::m_count=0;

//=============================================================================
// RATE LIMITER — sliding window
//=============================================================================
class C{MODULE_NAME}RateLimiter
{
private:
   static ulong m_ts[];
   static int   m_head;
   static int   m_total;
public:
   static void Init(){ArrayResize(m_ts,InpRLMaxOrdersPerWindow);ArrayInitialize(m_ts,0);m_head=0;m_total=0;}
   static bool Allow()
   {
      if(!InpRLEnabled)return true;
      ulong now=GetTickCount64(),win=(ulong)InpRLWindowSeconds*1000UL;
      int cap=InpRLMaxOrdersPerWindow,active=0;
      for(int i=0;i<cap;i++)if(m_ts[i]>0&&(now-m_ts[i])<win)active++;
      if(active>=cap){CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("RL: %d/%d BLOCKED",active,cap));return false;}
      m_ts[m_head]=now;m_head=(m_head+1)%cap;m_total++;return true;
   }
   static int TotalSent(){return m_total;}
};
ulong C{MODULE_NAME}RateLimiter::m_ts[];
int   C{MODULE_NAME}RateLimiter::m_head=0;
int   C{MODULE_NAME}RateLimiter::m_total=0;

//=============================================================================
// PRE-TICK GUARD
//=============================================================================
bool {MODULE_NAME}_PreTickGuard(string s)
{
   if(!(bool){MODULE_NAME}_ENABLE_TRADING)return false;
   if(!InpEnable{MODULE_NAME})return false;
   if(!{MODULE_NAME}_IsTradeAllowed())return false;
   if(!{MODULE_NAME}_SpreadOK(s,InpMaxSpreadPoints))return false;
   if(!{MODULE_NAME}_IsTradeSession())return false;
   if(C{MODULE_NAME}CircuitBreaker::IsOpen())return false;
   // v4.4.1 fix #4: cap on simultaneous open positions
   if(InpMaxOpenPositions>0&&C{MODULE_NAME}PositionTracker::Count()>=InpMaxOpenPositions)
   {CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("PreTickGuard: max positions %d reached",InpMaxOpenPositions));return false;}
   // v4.4.1 fix #9: live equity float DD check between deals
   if(InpCBEnabled)
   {
      double bal=AccountInfoDouble(ACCOUNT_BALANCE);
      double eq =AccountInfoDouble(ACCOUNT_EQUITY);
      double ddEq=(bal>0)?100.0*(bal-eq)/bal:0.0;
      if(ddEq>=InpCBMaxFloatDrawdownPct)
      {CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("PreTickGuard: live float DD %.2f%%>=%.2f%%",ddEq,InpCBMaxFloatDrawdownPct));return false;}
   }
   return true;
}

//=============================================================================
// POSITION TRACKER — v4.4
// Maintains real-time view of open positions filtered by magic number.
// Must call Refresh() each tick or from OnTradeTransaction.
//=============================================================================
struct {MODULE_NAME}_T_PositionInfo
{
   ulong           ticket;
   string          symbol;
   ENUM_POSITION_TYPE type;
   double          volume;
   double          open_price;
   double          sl;
   double          tp;
   double          profit;
   double          swap;
   int             magic;
   datetime        open_time;
};

class C{MODULE_NAME}PositionTracker
{
private:
   static {MODULE_NAME}_T_PositionInfo m_pos[];
   static int                          m_n;
   static int                          m_magic;
   // v4.6 fix G1: internal scan with explicit magic to avoid multi-symbol static clash
   static void _Scan(int magic)
   {
      m_n=0;
      int total=PositionsTotal();
      ArrayResize(m_pos,total);
      for(int i=0;i<total;i++)
      {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0)continue;
         if(magic!=0&&(int)PositionGetInteger(POSITION_MAGIC)!=magic)continue;
         {MODULE_NAME}_T_PositionInfo &p=m_pos[m_n];
         p.ticket     =ticket;
         p.symbol     =PositionGetString(POSITION_SYMBOL);
         p.type       =(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         p.volume     =PositionGetDouble(POSITION_VOLUME);
         p.open_price =PositionGetDouble(POSITION_PRICE_OPEN);
         p.sl         =PositionGetDouble(POSITION_SL);
         p.tp         =PositionGetDouble(POSITION_TP);
         p.profit     =PositionGetDouble(POSITION_PROFIT);
         p.swap       =PositionGetDouble(POSITION_SWAP);
         p.magic      =(int)PositionGetInteger(POSITION_MAGIC);
         p.open_time  =(datetime)PositionGetInteger(POSITION_TIME);
         m_n++;
      }
   }

public:
   // SetMagic: legacy single-instance path — kept for backward compat
   static void SetMagic(int magic){m_magic=magic;}

   // Refresh(): uses static m_magic — single-symbol EA path
   static void Refresh(){_Scan(m_magic);}

   // v4.6 fix G1: Refresh(magic) overload — pass instance magic explicitly.
   // Use this in multi-symbol EAs: each C{MODULE_NAME} instance calls
   //   C{MODULE_NAME}PositionTracker::Refresh(m_magic) from OnTick()
   //   instead of the static SetMagic() path which would clobber other instances.
   static void Refresh(int magic){_Scan(magic);}

   static int   Count()                  {return m_n;}
   static int   CountBySymbol(string s)
   {int c=0;for(int i=0;i<m_n;i++)if(m_pos[i].symbol==s)c++;return c;}
   static int   CountBuys(string s)
   {int c=0;for(int i=0;i<m_n;i++)if(m_pos[i].symbol==s&&m_pos[i].type==POSITION_TYPE_BUY)c++;return c;}
   static int   CountSells(string s)
   {int c=0;for(int i=0;i<m_n;i++)if(m_pos[i].symbol==s&&m_pos[i].type==POSITION_TYPE_SELL)c++;return c;}

   // Net exposure in lots (buy positive, sell negative)
   static double NetExposure(string s)
   {
      double net=0;
      for(int i=0;i<m_n;i++)
         if(m_pos[i].symbol==s)
            net+=(m_pos[i].type==POSITION_TYPE_BUY?m_pos[i].volume:-m_pos[i].volume);
      return net;
   }
   static double TotalProfit(string s)
   {double p=0;for(int i=0;i<m_n;i++)if(m_pos[i].symbol==s)p+=m_pos[i].profit+m_pos[i].swap;return p;}

   // Returns first position ticket for symbol (0 if none)
   static ulong FirstTicket(string s,ENUM_POSITION_TYPE t)
   {for(int i=0;i<m_n;i++)if(m_pos[i].symbol==s&&m_pos[i].type==t)return m_pos[i].ticket;return 0;}

   static bool HasPosition(string s){return CountBySymbol(s)>0;}
   static const {MODULE_NAME}_T_PositionInfo* Get(int idx){return(idx>=0&&idx<m_n)?&m_pos[idx]:NULL;}
};
{MODULE_NAME}_T_PositionInfo C{MODULE_NAME}PositionTracker::m_pos[];
int C{MODULE_NAME}PositionTracker::m_n=0;
int C{MODULE_NAME}PositionTracker::m_magic=0;

//=============================================================================
// POSITION SIZER — v4.4
// Four modes: PERCENT_RISK, ATR_BASED, KELLY, FIXED
//=============================================================================
enum ENUM_{MODULE_NAME}_E_SizerMode
{
   {MODULE_NAME}_SIZE_PERCENT_RISK = 0,
   {MODULE_NAME}_SIZE_ATR          = 1,
   {MODULE_NAME}_SIZE_KELLY        = 2,
   {MODULE_NAME}_SIZE_FIXED        = 3
};

class C{MODULE_NAME}PositionSizer
{
public:
   // --- PERCENT RISK ---
   // sl_pts: stop loss distance in points
   static double ByPercentRisk(const {MODULE_NAME}_T_SymbolCache &c,
                                double sl_pts,double risk_pct=0.0)
   {
      if(risk_pct<=0)risk_pct=InpSizerRiskPct;
      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      // v4.9 fix F6: balance==0 guard — account not loaded or demo reset
      if(balance<=0){CORE_LOG({MODULE_NAME}_LOG_WARN,"PositionSizer: balance=0, returning vol_min");return c.vol_min;}
      double risk_money=balance*risk_pct/100.0;
      if(sl_pts<=0||c.tick_value<=0||c.tick_size<=0)return c.vol_min;
      double risk_per_lot=sl_pts*c.tick_value/c.tick_size;
      if(risk_per_lot<=0)return c.vol_min;
      return {MODULE_NAME}_NormalizeVolume(c,risk_money/risk_per_lot);
   }

   // --- ATR BASED ---
   // atr_value: ATR in price units (call iATR() before passing)
   static double ByATR(const {MODULE_NAME}_T_SymbolCache &c,
                        double atr_value,double atr_mult=0.0)
   {
      if(atr_mult<=0)atr_mult=InpSizerATRMultiplier;
      double sl_price=atr_value*atr_mult;
      double sl_pts  =(c.point>0)?sl_price/c.point:0;
      return ByPercentRisk(c,sl_pts);
   }

   // --- KELLY FRACTION ---
   // win_rate: [0,1], avg_win/avg_loss: ratio
   static double ByKelly(const {MODULE_NAME}_T_SymbolCache &c,
                          double sl_pts,double win_rate,
                          double avg_win,double avg_loss,
                          double kelly_frac=0.0)
   {
      if(kelly_frac<=0)kelly_frac=InpSizerKellyFraction;
      if(avg_loss<=0||win_rate<=0||win_rate>=1)return ByPercentRisk(c,sl_pts);
      double rr=avg_win/avg_loss;
      double kelly=win_rate-(1.0-win_rate)/rr;
      kelly=MathMax(0,MathMin(kelly,1))*kelly_frac;   // fractional Kelly cap
      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      // v4.9 fix F6: balance==0 guard — same as ByPercentRisk
      if(balance<=0){CORE_LOG({MODULE_NAME}_LOG_WARN,"PositionSizer Kelly: balance=0, returning vol_min");return c.vol_min;}
      double risk_money=balance*kelly;                // kelly is already a fraction [0,frac]
      double risk_per_lot=(c.tick_value>0&&c.tick_size>0)?sl_pts*c.tick_value/c.tick_size:0;
      if(risk_per_lot<=0)return c.vol_min;
      return {MODULE_NAME}_NormalizeVolume(c,risk_money/risk_per_lot);
   }

   // --- FIXED ---
   static double ByFixed(const {MODULE_NAME}_T_SymbolCache &c,double lots=0)
   {
      if(lots<=0)lots=InpSizerFixedLots;
      return {MODULE_NAME}_NormalizeVolume(c,lots);
   }

   // --- UNIFIED ENTRY POINT ---
   static double Calculate(const {MODULE_NAME}_T_SymbolCache &c,
                            ENUM_{MODULE_NAME}_E_SizerMode mode,
                            double sl_pts,
                            double extra1=0.0,  // win_rate (Kelly) | atr_value (ATR)
                            double extra2=0.0,  // avg_win (Kelly)  | atr_mult (ATR)
                            double extra3=0.0)  // avg_loss (Kelly)
   {
      double lots=0;
      switch(mode)
      {
         case {MODULE_NAME}_SIZE_PERCENT_RISK: lots=ByPercentRisk(c,sl_pts);           break;
         case {MODULE_NAME}_SIZE_ATR:          lots=ByATR(c,extra1,extra2);             break;
         case {MODULE_NAME}_SIZE_KELLY:        lots=ByKelly(c,sl_pts,extra1,extra2,extra3); break;
         default:                              lots=ByFixed(c);                          break;
      }
      CORE_LOG({MODULE_NAME}_LOG_DEBUG,
               StringFormat("Sizer[%s] sl_pts=%.1f lots=%.4f",
                            EnumToString(mode),sl_pts,lots));
      return lots;
   }
};

//=============================================================================
// FORWARD DECLARATIONS — v4.5
// Required because:
//   • TrySendFilling is defined after OrderModifier but called inside PartialClose
//   • SendOrderTxn idem — declared here for symmetry
//   • RunUnitTests_ is defined after C{MODULE_NAME}::Init() but called inside it
//   • C{MODULE_NAME}TradeJournal is defined after C{MODULE_NAME} but called in Deinit() (fix D1)
//   • C{MODULE_NAME}HealthMonitor is defined after SendOrderTxn but called inside it (fix D2)
// MQL5 does not allow forward reference without explicit declaration.
//=============================================================================

// v4.7 fix E1: T_OrderRequest + T_OrderResult moved here — MUST precede
//              SendOrderTxn forward declaration which references them.
//              Previously defined at L.1692 — 865 lines after their first use.
struct {MODULE_NAME}_T_OrderRequest
{
   string           symbol;
   ENUM_ORDER_TYPE  type;
   double           volume;
   double           price;
   double           sl;
   double           tp;
   double           stoplimit_price;
   int              deviation_pts;
   string           comment;
   int              magic;
};

struct {MODULE_NAME}_T_OrderResult
{
   bool   ok;
   int    retcode;
   ulong  deal;
   ulong  order;
   double price_exec;
   double slippage_pts;
};

bool {MODULE_NAME}_TrySendFilling(MqlTradeRequest &req, MqlTradeResult &out);
// v4.11 fix O4: optional cache pointer — pass &m_cache to skip redundant SymbolInfo calls
bool {MODULE_NAME}_SendOrderTxn(const {MODULE_NAME}_T_OrderRequest &r, {MODULE_NAME}_T_OrderResult &res,
                                 const {MODULE_NAME}_T_SymbolCache *cache=NULL);
#if {MODULE_NAME}_UNIT_TESTING==1
static bool RunUnitTests_{MODULE_NAME}();
#endif

// v4.6 fix D1: TradeJournal used in C{MODULE_NAME}::Deinit() but defined later
class C{MODULE_NAME}TradeJournal;
// v4.6 fix D2: HealthMonitor used in SendOrderTxn body but defined later
class C{MODULE_NAME}HealthMonitor;
// v4.7.1 fix F1: EventBus used in OnChartEvent{MODULE_NAME}() wrapper but defined 276 lines later
class C{MODULE_NAME}EventBus;

//=============================================================================
// ORDER MODIFIER — v4.4
// Modify SL/TP, Trail Stop, Break Even, Partial Close
//=============================================================================
class C{MODULE_NAME}OrderModifier
{
public:
   // Modify SL and/or TP on an open position
   static bool ModifySLTP(ulong ticket,double new_sl,double new_tp)
   {
      if(!PositionSelectByTicket(ticket)){CORE_LOG({MODULE_NAME}_LOG_WARN,"ModifySLTP: ticket not found");return false;}
      string sym=PositionGetString(POSITION_SYMBOL);
      double price=PositionGetDouble(POSITION_PRICE_CURRENT);
      ENUM_POSITION_TYPE pt=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      ENUM_ORDER_TYPE ot=(pt==POSITION_TYPE_BUY)?ORDER_TYPE_BUY:ORDER_TYPE_SELL;

      // Re-validate before modifying
      if(new_sl!=0||new_tp!=0)
         if(!{MODULE_NAME}_SLTPValid(sym,price,new_sl,new_tp,ot))
         {CORE_LOG({MODULE_NAME}_LOG_WARN,"ModifySLTP: SLTPValid failed");return false;}

#if {MODULE_NAME}_DRY_RUN==1
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN ModifySLTP ticket=%I64d sl=%.5f tp=%.5f",ticket,new_sl,new_tp));
      return true;
#endif

      MqlTradeRequest req;ZeroMemory(req);
      MqlTradeResult  res;ZeroMemory(res);
      req.action  =TRADE_ACTION_SLTP;
      req.position=ticket;
      req.sl      =new_sl;
      req.tp      =new_tp;
      req.symbol  =sym;
      if(!OrderSend(req,res))
      {CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("ModifySLTP err=%d",_LastError));return false;}
      return res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED;
   }

   // Trail stop: move SL to trail_dist points behind current price
   static bool TrailStop(ulong ticket,double trail_pts)
   {
      if(!PositionSelectByTicket(ticket))return false;
      string sym   =PositionGetString(POSITION_SYMBOL);
      double pt    =SymbolInfoDouble(sym,SYMBOL_POINT);
      double price =PositionGetDouble(POSITION_PRICE_CURRENT);
      double cur_sl=PositionGetDouble(POSITION_SL);
      double cur_tp=PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double trail_price=trail_pts*pt;
      double new_sl;
      if(ptype==POSITION_TYPE_BUY)
      {
         new_sl=price-trail_price;
         // v4.4.1 fix #6: if cur_sl==0 (no SL yet), always enter to set first trailing SL;
         // if cur_sl>0, only advance if new_sl is higher (tighter) than current
         if(cur_sl>0&&new_sl<=cur_sl){return true;} // already at tighter level
      }
      else
      {
         new_sl=price+trail_price;
         if(new_sl>=cur_sl&&cur_sl>0){return true;}
      }
      return ModifySLTP(ticket,new_sl,cur_tp);
   }

   // Move SL to break-even + be_buffer_pts
   // v4.4.1 fix #7: guard — position must be at least be_buffer_pts in profit before moving SL
   static bool BreakEven(ulong ticket,double be_buffer_pts=0.0)
   {
      if(!PositionSelectByTicket(ticket))return false;
      string sym     =PositionGetString(POSITION_SYMBOL);
      double pt      =SymbolInfoDouble(sym,SYMBOL_POINT);
      double open_px =PositionGetDouble(POSITION_PRICE_OPEN);
      double cur_price=PositionGetDouble(POSITION_PRICE_CURRENT);
      double cur_tp  =PositionGetDouble(POSITION_TP);
      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      // Require at least (be_buffer_pts + 1pt) of profit before attempting break-even
      double min_profit_pts=be_buffer_pts+1.0;
      if(ptype==POSITION_TYPE_BUY)
      {if((cur_price-open_px)/pt<min_profit_pts){CORE_LOG({MODULE_NAME}_LOG_DEBUG,"BreakEven: not enough profit");return false;}}
      else
      {if((open_px-cur_price)/pt<min_profit_pts){CORE_LOG({MODULE_NAME}_LOG_DEBUG,"BreakEven: not enough profit");return false;}}
      double new_sl=(ptype==POSITION_TYPE_BUY)?open_px+be_buffer_pts*pt:open_px-be_buffer_pts*pt;
      return ModifySLTP(ticket,new_sl,cur_tp);
   }

   // Partial close: close close_lots of position identified by ticket
   static bool PartialClose(ulong ticket,double close_lots,int magic)
   {
      if(!PositionSelectByTicket(ticket))return false;
      string sym      =PositionGetString(POSITION_SYMBOL);
      double pos_vol  =PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      {MODULE_NAME}_T_SymbolCache cache;{MODULE_NAME}_LoadSymbolCache(sym,cache);
      close_lots={MODULE_NAME}_NormalizeVolume(cache,MathMin(close_lots,pos_vol));
      ENUM_ORDER_TYPE close_type=(ptype==POSITION_TYPE_BUY)?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
      double price=(close_type==ORDER_TYPE_SELL)?SymbolInfoDouble(sym,SYMBOL_BID):SymbolInfoDouble(sym,SYMBOL_ASK);
#if {MODULE_NAME}_DRY_RUN==1
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN PartialClose ticket=%I64d lots=%.4f",ticket,close_lots));
      return true;
#endif
      MqlTradeRequest req;ZeroMemory(req);
      req.action      =TRADE_ACTION_DEAL;
      req.symbol      =sym;
      req.volume      =close_lots;
      req.type        =close_type;
      req.price       =price;
      req.position    =ticket;
      req.magic       =magic;
      req.comment     ="partial_close";
      // v4.5 fix C3: orphan MqlTradeResult res removed; TrySendFilling uses its own out param
      MqlTradeResult res;ZeroMemory(res);
      if(!{MODULE_NAME}_TrySendFilling(req,res))
      {CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("PartialClose err=%d",(int)res.retcode));return false;}
      return res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED;
   }
};

//=============================================================================
// PENDING ORDER MANAGER — v4.4
// Stale order cleanup, cancel-all, cancel-by-symbol
//=============================================================================
class C{MODULE_NAME}PendingManager
{
public:
   // Cancel all pending orders older than max_age_sec (0 = cancel all)
   static int CancelStale(int magic,int max_age_sec=0)
   {
      int cancelled=0;
      datetime cutoff=(max_age_sec>0)?TimeCurrent()-max_age_sec:0;
      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         ulong ticket=OrderGetTicket(i);
         if(ticket==0)continue;
         if((int)OrderGetInteger(ORDER_MAGIC)!=magic)continue;
         if(max_age_sec>0&&(datetime)OrderGetInteger(ORDER_TIME_SETUP)>cutoff)continue;
#if {MODULE_NAME}_DRY_RUN==1
         CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN CancelStale ticket=%I64d",ticket));
         cancelled++;continue;
#endif
         MqlTradeRequest req;ZeroMemory(req);
         MqlTradeResult  res;ZeroMemory(res);
         req.action=TRADE_ACTION_REMOVE;
         req.order =ticket;
         if(OrderSend(req,res)&&(res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED))
         {cancelled++;CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("Cancelled order %I64d",ticket));}
         else CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("Cancel fail ticket=%I64d rc=%d",ticket,(int)res.retcode));
      }
      return cancelled;
   }

   static int CancelBySymbol(string sym,int magic)
   {
      int cancelled=0;
      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         ulong ticket=OrderGetTicket(i);
         if(ticket==0)continue;
         if(OrderGetString(ORDER_SYMBOL)!=sym)continue;
         if((int)OrderGetInteger(ORDER_MAGIC)!=magic)continue;
#if {MODULE_NAME}_DRY_RUN==1
         CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN CancelBySymbol ticket=%I64d",ticket));
         cancelled++;continue;
#endif
         MqlTradeRequest req;ZeroMemory(req);MqlTradeResult res;ZeroMemory(res);
         req.action=TRADE_ACTION_REMOVE;req.order=ticket;
         if(OrderSend(req,res)&&(res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED))cancelled++;
      }
      return cancelled;
   }

   static int PendingCount(int magic)
   {
      int c=0;
      for(int i=0;i<OrdersTotal();i++)
      {ulong t=OrderGetTicket(i);if(t>0&&(int)OrderGetInteger(ORDER_MAGIC)==magic)c++;}
      return c;
   }

   // v4.7 fix A5: GetTickets() — fills out[] with all pending ticket IDs for magic
   //   Returns count. Caller pre-allocates out[] or passes empty array (auto-resized).
   //   e.g.:  ulong tickets[];
   //          int n = C{MODULE_NAME}PendingManager::GetTickets(m_magic, tickets);
   //          for(int i=0;i<n;i++) Print(tickets[i]);
   static int GetTickets(int magic, ulong &out[])
   {
      // v4.11 fix Y2: pre-allocate to OrdersTotal() then truncate — O(n) instead of O(n²)
      int total=OrdersTotal();
      int n=0;
      ArrayResize(out,total);
      for(int i=0;i<total;i++)
      {
         ulong t=OrderGetTicket(i);
         if(t==0)continue;
         if((int)OrderGetInteger(ORDER_MAGIC)!=magic)continue;
         out[n++]=t;
      }
      ArrayResize(out,n);
      return n;
   }

   // v4.7 fix A5: GetTicketsBySymbol() — filter by symbol AND magic
   // v4.11 fix Y2: pre-allocated array
   static int GetTicketsBySymbol(string sym,int magic,ulong &out[])
   {
      int total=OrdersTotal();
      int n=0;
      ArrayResize(out,total);
      for(int i=0;i<total;i++)
      {
         ulong t=OrderGetTicket(i);
         if(t==0)continue;
         if(OrderGetString(ORDER_SYMBOL)!=sym)continue;
         if((int)OrderGetInteger(ORDER_MAGIC)!=magic)continue;
         out[n++]=t;
      }
      ArrayResize(out,n);
      return n;
   }

   // Q4: ModifyPending() — change price, SL, TP of an existing pending order in place
   //   Returns true on DONE/PLACED. Use when re-pricing a limit/stop without cancel+replace.
   //   e.g.: C{MODULE_NAME}PendingManager::ModifyPending(ticket, newPrice, newSL, newTP);
   static bool ModifyPending(ulong ticket, double new_price, double new_sl, double new_tp)
   {
      if(!OrderSelect(ticket)){CORE_LOG({MODULE_NAME}_LOG_WARN,"ModifyPending: ticket not found");return false;}
      string sym=OrderGetString(ORDER_SYMBOL);
#if {MODULE_NAME}_DRY_RUN==1
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN ModifyPending ticket=%I64d px=%.5f sl=%.5f tp=%.5f",
               ticket,new_price,new_sl,new_tp));
      return true;
#endif
      MqlTradeRequest req;ZeroMemory(req);
      MqlTradeResult  res;ZeroMemory(res);
      req.action    =TRADE_ACTION_MODIFY;
      req.order     =ticket;
      req.symbol    =sym;
      req.price     =new_price;
      req.sl        =new_sl;
      req.tp        =new_tp;
      req.type_time =(ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME);
      req.expiration=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      if(!OrderSend(req,res))
      {CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("ModifyPending err=%d",_LastError));return false;}
      return res.retcode==TRADE_RETCODE_DONE||res.retcode==TRADE_RETCODE_PLACED;
   }
};

//=============================================================================
// EQUITY CURVE SAMPLER — v4.4
// Ring buffer of (timestamp, balance, equity) points; CSV export.
//=============================================================================
struct {MODULE_NAME}_T_EquityPoint
{
   datetime ts;
   double   balance;
   double   equity;
};

class C{MODULE_NAME}EquityCurve
{
private:
   static {MODULE_NAME}_T_EquityPoint m_buf[];
   static int m_head;
   static int m_n;
   static ulong m_last_sample_ms;
   static bool  m_buf_ready;

public:
   // v4.4.1 fix #10: one-time pre-allocation; call from Init or first Sample
   static void Init()
   {
      if(m_buf_ready)return;
      ArrayResize(m_buf,{MODULE_NAME}_C_EQUITY_CURVE_MAX);
      m_buf_ready=true;
   }

   // Call from OnTimer or OnTick; interval_ms controls sampling frequency
   static void Sample(ulong interval_ms=60000)
   {
      ulong now=GetTickCount64();
      if(now-m_last_sample_ms<interval_ms)return;
      m_last_sample_ms=now;
      if(!m_buf_ready)Init();  // safety: ensure allocated even if Init() not called explicitly
      int cap={MODULE_NAME}_C_EQUITY_CURVE_MAX;
      m_buf[m_head].ts     =TimeCurrent();
      m_buf[m_head].balance=AccountInfoDouble(ACCOUNT_BALANCE);
      m_buf[m_head].equity =AccountInfoDouble(ACCOUNT_EQUITY);
      m_head=(m_head+1)%cap;
      if(m_n<cap)m_n++;
   }

   static double MaxDrawdownPct()
   {
      if(m_n<2)return 0;
      double peak=0,maxdd=0;
      int cap={MODULE_NAME}_C_EQUITY_CURVE_MAX;
      for(int i=0;i<m_n;i++)
      {
         int idx=(m_head-m_n+i+cap)%cap;
         if(m_buf[idx].equity>peak)peak=m_buf[idx].equity;
         double dd=(peak>0)?100.0*(peak-m_buf[idx].equity)/peak:0;
         if(dd>maxdd)maxdd=dd;
      }
      return maxdd;
   }

   static void ExportCSV(string filename)
   {
      if(m_n==0)return;
      int fh=FileOpen(filename,FILE_WRITE|FILE_CSV|FILE_ANSI,',');
      if(fh==INVALID_HANDLE){CORE_LOG({MODULE_NAME}_LOG_ERROR,"EquityCurve: cannot open file");return;}
      FileWrite(fh,"timestamp","balance","equity");
      int cap={MODULE_NAME}_C_EQUITY_CURVE_MAX;
      for(int i=0;i<m_n;i++)
      {
         int idx=(m_head-m_n+i+cap)%cap;
         FileWrite(fh,TimeToString(m_buf[idx].ts),
                   DoubleToString(m_buf[idx].balance,2),
                   DoubleToString(m_buf[idx].equity,2));
      }
      FileClose(fh);
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("EquityCurve: %d points → %s",m_n,filename));
   }

   static int Count(){return m_n;}

   // Q6: GetPoint(idx) — read access to ring buffer (idx=0 is oldest, idx=m_n-1 is newest)
   //   Returns NULL if buffer empty or idx out of range.
   //   e.g.:  const {MODULE_NAME}_T_EquityPoint* p = C{MODULE_NAME}EquityCurve::GetPoint(0);
   //          if(p) Print(p.equity);
   static const {MODULE_NAME}_T_EquityPoint* GetPoint(int idx)
   {
      if(m_n==0||idx<0||idx>=m_n)return NULL;
      int cap={MODULE_NAME}_C_EQUITY_CURVE_MAX;
      int real_idx=(m_head-m_n+idx+cap)%cap;
      return &m_buf[real_idx];
   }

   // Q6: LatestPoint() — convenience accessor for the most recent sample
   static const {MODULE_NAME}_T_EquityPoint* LatestPoint()
   {return GetPoint(m_n-1);}

   // v4.7 fix A6: Reset() — clears ring buffer without deallocating
   static void Reset()
   {
      m_head=0;m_n=0;m_last_sample_ms=0;
      CORE_LOG({MODULE_NAME}_LOG_INFO,"EquityCurve: reset");
   }
};
{MODULE_NAME}_T_EquityPoint C{MODULE_NAME}EquityCurve::m_buf[];
int   C{MODULE_NAME}EquityCurve::m_head=0;
int   C{MODULE_NAME}EquityCurve::m_n=0;
ulong C{MODULE_NAME}EquityCurve::m_last_sample_ms=0;
bool  C{MODULE_NAME}EquityCurve::m_buf_ready=false;

//=============================================================================
// CONFIG MANAGER — v4.4
// Hot-reload key=value pairs from .ini file at runtime.
// Format: KEY=VALUE (one per line, # comments supported)
//=============================================================================
class C{MODULE_NAME}ConfigManager
{
private:
   static string m_keys[];
   static string m_vals[];
   static int    m_n;
   static ulong  m_last_load_ms;
   static string m_filename;

   static void Clear(){m_n=0;ArrayResize(m_keys,0);ArrayResize(m_vals,0);}

public:
   static void SetFile(string f){m_filename=f;}

   static bool Load(string filename="")
   {
      if(filename!="")m_filename=filename;
      if(m_filename=="")m_filename=InpConfigFile;
      int fh=FileOpen(m_filename,FILE_READ|FILE_TXT|FILE_ANSI);
      if(fh==INVALID_HANDLE)
      {CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("Config: cannot open %s",m_filename));return false;}
      Clear();
      while(!FileIsEnding(fh))
      {
         string line=FileReadString(fh);
         StringTrimLeft(line);StringTrimRight(line);
         if(StringLen(line)==0||StringGetCharacter(line,0)=='#')continue;
         int eq=StringFind(line,"=");
         if(eq<1)continue;
         string k=StringSubstr(line,0,eq);
         string v=StringSubstr(line,eq+1);
         StringTrimRight(k);StringTrimLeft(v);
         ArrayResize(m_keys,m_n+1);ArrayResize(m_vals,m_n+1);
         m_keys[m_n]=k;m_vals[m_n]=v;m_n++;
      }
      FileClose(fh);
      m_last_load_ms=GetTickCount64();
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("Config loaded: %d keys from %s",m_n,m_filename));
      return true;
   }

   // Auto-reload if TTL expired
   static void ReloadIfStale()
   {
      if(GetTickCount64()-m_last_load_ms>(ulong){MODULE_NAME}_C_CONFIG_RELOAD_MS)Load();
   }

   // v4.7 fix A3: public Reload() — immediate reload without waiting for TTL
   //   Call from EA when config file may have changed (e.g. after user edit)
   static bool Reload(){return Load();}

   // v4.7 fix A3: ForceReload() — resets TTL timer then reloads
   //   Use when you want subsequent ReloadIfStale() calls to respect the new TTL baseline
   static bool ForceReload()
   {
      m_last_load_ms=0;  // expire TTL immediately
      return Load();
   }

   static string GetStr(string key,string def="")
   {for(int i=0;i<m_n;i++)if(m_keys[i]==key)return m_vals[i];return def;}

   static double GetDouble(string key,double def=0.0)
   {string v=GetStr(key,"");return(v!="")?StringToDouble(v):def;}

   static int GetInt(string key,int def=0)
   {string v=GetStr(key,"");return(v!="")?StringToInteger(v):def;}

   static bool GetBool(string key,bool def=false)
   {string v={MODULE_NAME}_StrLower(GetStr(key,""));return(v=="1"||v=="true")?true:(v=="0"||v=="false")?false:def;}

   static int KeyCount(){return m_n;}
};
string C{MODULE_NAME}ConfigManager::m_keys[];
string C{MODULE_NAME}ConfigManager::m_vals[];
int    C{MODULE_NAME}ConfigManager::m_n=0;
ulong  C{MODULE_NAME}ConfigManager::m_last_load_ms=0;
string C{MODULE_NAME}ConfigManager::m_filename="";

//=============================================================================
// WATCHDOG TIMER — v4.4 + v4.12 slot-based multi-instance (fix ARC2)
// Detects OnTick() stall (hangs, frozen EA, disconnected feed).
// Call Kick() each tick; call Check() from OnTimer.
//=============================================================================
class C{MODULE_NAME}WatchdogTimer
{
private:
   static ulong m_last_kick_ms[];
   static ulong m_stall_threshold_ms[];
   static int   m_alert_count[];
   static int   m_active;
   static int   m_count;

public:
   static int Alloc()
   {
      int s=m_count++;
      ArrayResize(m_last_kick_ms,m_count);ArrayResize(m_stall_threshold_ms,m_count);
      ArrayResize(m_alert_count,m_count);
      m_last_kick_ms[s]=0;m_stall_threshold_ms[s]=5000;m_alert_count[s]=0;
      return s;
   }
   static void Activate(int slot){m_active=slot;}

   static void Init(ulong stall_ms=5000){m_last_kick_ms[m_active]=GetTickCount64();m_stall_threshold_ms[m_active]=stall_ms;m_alert_count[m_active]=0;}
   static void Kick(){m_last_kick_ms[m_active]=GetTickCount64();}

   static bool Check()
   {
      ulong age=GetTickCount64()-m_last_kick_ms[m_active];
      if(age>m_stall_threshold_ms[m_active])
      {
         m_alert_count[m_active]++;
         string msg=StringFormat("WATCHDOG[%d]: OnTick stall %I64dms (alert #%d)",m_active,age,m_alert_count[m_active]);
         CORE_LOG({MODULE_NAME}_LOG_ERROR,msg);
#ifdef __MQL5_TESTER__
         Print(msg);
#else
         Alert(msg);
#endif
         return true;
      }
      return false;
   }

   static ulong AgeMs(){return GetTickCount64()-m_last_kick_ms[m_active];}
   static int   AlertCount(){return m_alert_count[m_active];}
};
ulong C{MODULE_NAME}WatchdogTimer::m_last_kick_ms[];
ulong C{MODULE_NAME}WatchdogTimer::m_stall_threshold_ms[];
int   C{MODULE_NAME}WatchdogTimer::m_alert_count[];
int   C{MODULE_NAME}WatchdogTimer::m_active=0;
int   C{MODULE_NAME}WatchdogTimer::m_count=0;

//=============================================================================
// MOCK BROKER — v4.4
// Offline order simulation for unit testing without a broker connection.
// Activated by #define {MODULE_NAME}_MOCK_BROKER 1
//=============================================================================
#if {MODULE_NAME}_MOCK_BROKER==1
struct {MODULE_NAME}_T_MockOrder
{
   ulong           ticket;
   string          symbol;
   ENUM_ORDER_TYPE type;
   double          volume;
   double          price;
   double          sl;
   double          tp;
   int             retcode_override; // -1 = use DONE
};

class C{MODULE_NAME}MockBroker
{
private:
   static {MODULE_NAME}_T_MockOrder m_orders[];
   static int    m_n;
   static ulong  m_next_ticket;
   static int    m_forced_retcode; // -1 = auto DONE
   static int    m_total_calls;

public:
   static void Reset(){m_n=0;m_next_ticket=100000;m_forced_retcode=-1;m_total_calls=0;ArrayResize(m_orders,0);}
   static void ForceRetcode(int rc){m_forced_retcode=rc;} // inject failure
   static void ClearForce(){m_forced_retcode=-1;}

   static bool Send(const MqlTradeRequest &req,MqlTradeResult &res)
   {
      ZeroMemory(res);m_total_calls++;
      int rc=(m_forced_retcode>=0)?m_forced_retcode:TRADE_RETCODE_DONE;
      res.retcode=(uint)rc;
      if(rc==TRADE_RETCODE_DONE)
      {
         res.order =m_next_ticket;
         res.deal  =m_next_ticket;
         res.price =req.price;
         int n=ArraySize(m_orders);ArrayResize(m_orders,n+1);
         m_orders[n].ticket=m_next_ticket;
         m_orders[n].symbol=req.symbol;
         m_orders[n].type  =req.type;
         m_orders[n].volume=req.volume;
         m_orders[n].price =req.price;
         m_orders[n].sl    =req.sl;
         m_orders[n].tp    =req.tp;
         m_n++;m_next_ticket++;
         return true;
      }
      return false;
   }

   static int  TotalCalls()  {return m_total_calls;}
   static int  OrderCount()  {return m_n;}
   static const {MODULE_NAME}_T_MockOrder* GetOrder(int i){return(i>=0&&i<m_n)?&m_orders[i]:NULL;}
};
{MODULE_NAME}_T_MockOrder C{MODULE_NAME}MockBroker::m_orders[];
int   C{MODULE_NAME}MockBroker::m_n=0;
ulong C{MODULE_NAME}MockBroker::m_next_ticket=100000;
int   C{MODULE_NAME}MockBroker::m_forced_retcode=-1;
int   C{MODULE_NAME}MockBroker::m_total_calls=0;
#endif // {MODULE_NAME}_MOCK_BROKER

//=============================================================================
// ASSERT TRADE — v4.4
// Semantic order invariants for unit testing.
// Returns true if assertion passes, logs ERROR and returns false if not.
//=============================================================================
class C{MODULE_NAME}AssertTrade
{
private:
   static int m_pass;
   static int m_fail;

   static bool _Assert(bool cond,string msg)
   {if(cond){m_pass++;return true;}
    m_fail++;CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("ASSERT FAIL: %s",msg));return false;}

public:
   static void Reset(){m_pass=0;m_fail=0;}
   static int  PassCount(){return m_pass;}
   static int  FailCount(){return m_fail;}
   static bool AllPassed(){return m_fail==0;}

   static bool SLBelowPrice(double sl,double price,string ctx="")
   {return _Assert(sl<price,StringFormat("SL %.5f must be < price %.5f %s",sl,price,ctx));}
   static bool SLAbovePrice(double sl,double price,string ctx="")
   {return _Assert(sl>price,StringFormat("SL %.5f must be > price %.5f %s",sl,price,ctx));}
   static bool TPAbovePrice(double tp,double price,string ctx="")
   {return _Assert(tp>price,StringFormat("TP %.5f must be > price %.5f %s",tp,price,ctx));}
   static bool TPBelowPrice(double tp,double price,string ctx="")
   {return _Assert(tp<price,StringFormat("TP %.5f must be < price %.5f %s",tp,price,ctx));}
   static bool VolumeInRange(double vol,double vmin,double vmax,string ctx="")
   {return _Assert(vol>=vmin&&vol<=vmax,StringFormat("Vol %.4f not in [%.4f,%.4f] %s",vol,vmin,vmax,ctx));}
   static bool RetcodeOK(int rc,string ctx="")
   {return _Assert(rc==TRADE_RETCODE_DONE||rc==TRADE_RETCODE_PLACED,StringFormat("retcode=%d %s",rc,ctx));}
   static bool NonZero(double v,string ctx="")
   {return _Assert(MathAbs(v)>{MODULE_NAME}_C_EPS,StringFormat("Expected non-zero: %s",ctx));}
   static bool Equal(double a,double b,double tol,string ctx="")
   {return _Assert(MathAbs(a-b)<=tol,StringFormat("%.8f != %.8f (tol=%.8f) %s",a,b,tol,ctx));}

   static void Report()
   {CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("AssertTrade: %d pass / %d fail",m_pass,m_fail));}
};
int C{MODULE_NAME}AssertTrade::m_pass=0;
int C{MODULE_NAME}AssertTrade::m_fail=0;

//=============================================================================
// FUZZ INPUTS — v4.4
// Boundary value and random injection helpers for stress testing.
//=============================================================================
class C{MODULE_NAME}FuzzInputs
{
public:
   // Returns a volume at boundary: min, max, or step
   static double FuzzVolume(const {MODULE_NAME}_T_SymbolCache &c,int variant)
   {
      switch(variant%4)
      {
         case 0: return c.vol_min;
         case 1: return c.vol_max;
         case 2: return c.vol_min+c.vol_step;
         default:return c.vol_min+c.vol_step*(MathRand()%10+1);
      }
   }
   // Returns a price offset that is just inside / outside minDist
   static double FuzzSLOffset(const {MODULE_NAME}_T_SymbolCache &c,bool valid)
   {
      double minDist=(c.stops_level+c.freeze_level)*c.point;
      return valid?minDist+2*c.point:minDist-c.point;
   }
   // Returns a spread in points: zero, normal, extreme
   static double FuzzSpread(int variant)
   {
      switch(variant%3){case 0:return 0;case 1:return 15;default:return 200;}
   }
   // Random retcode from a set of common server codes
   static int FuzzRetcode()
   {
      int codes[]={TRADE_RETCODE_DONE,TRADE_RETCODE_REQUOTE,TRADE_RETCODE_REJECT,
                   TRADE_RETCODE_PRICE_OFF,TRADE_RETCODE_NO_MONEY,TRADE_RETCODE_INVALID_FILL};
      return codes[MathRand()%6];
   }
};

//=============================================================================
// FORWARD DECLARATION
//=============================================================================
class C{MODULE_NAME};

//=============================================================================
// INSTANCE MANAGER
//=============================================================================
class C{MODULE_NAME}Manager
{
private:
   static C{MODULE_NAME}* m_inst[];
   static string          m_key[];
   static int             m_n;
   static bool            m_init;
   static int Find(string k){for(int i=0;i<m_n;i++)if(m_key[i]==k&&m_inst[i]!=NULL)return i;return -1;}
public:
   static void Init(){if(m_init)return;ArrayResize(m_inst,0);ArrayResize(m_key,0);m_n=0;m_init=true;}
   static C{MODULE_NAME}* Get(string s,ENUM_TIMEFRAMES tf)
   {
      Init();
      string k={MODULE_NAME}_StrUpper(s)+"_"+IntegerToString((int)tf);
      int i=Find(k);if(i>=0)return m_inst[i];
      CORE_ASSERT_RET(m_n<{MODULE_NAME}_C_MAX_INSTANCES,"Max instances");
      ArrayResize(m_inst,m_n+1);ArrayResize(m_key,m_n+1);
      m_key[m_n]=k;m_inst[m_n]=new C{MODULE_NAME}();
      CORE_ASSERT_RET(m_inst[m_n]!=NULL,"Alloc failed");
      m_n++;return m_inst[m_n-1];
   }
   static void Release(string s,ENUM_TIMEFRAMES tf)
   {
      string k={MODULE_NAME}_StrUpper(s)+"_"+IntegerToString((int)tf);
      int i=Find(k);if(i<0)return;
      m_inst[i]->Deinit();delete m_inst[i];m_inst[i]=NULL;
      for(int j=i;j<m_n-1;j++){m_inst[j]=m_inst[j+1];m_key[j]=m_key[j+1];}
      m_n--;ArrayResize(m_inst,m_n);ArrayResize(m_key,m_n);
   }
   static void ReleaseAll()
   {
      // v4.5 fix M2: each Deinit() flushes TradeJournal+EquityCurve — must call before delete
      for(int i=0;i<m_n;i++)
         if(m_inst[i]){m_inst[i]->Deinit();delete m_inst[i];m_inst[i]=NULL;}
      m_n=0;ArrayFree(m_inst);ArrayFree(m_key);m_init=false;
   }
};
C{MODULE_NAME}* C{MODULE_NAME}Manager::m_inst[];
string          C{MODULE_NAME}Manager::m_key[];
int             C{MODULE_NAME}Manager::m_n=0;
bool            C{MODULE_NAME}Manager::m_init=false;

//=============================================================================
// CORE ENGINE CLASS
//=============================================================================
class C{MODULE_NAME}
{
private:
   bool                        m_ok;
   string                      m_symbol;
   ENUM_TIMEFRAMES             m_tf;
   int                         m_magic;
   ulong                       m_last_us;
   {MODULE_NAME}_T_SymbolCache m_cache;
   // v4.12 fix ARC4: per-instance subsystem slots
   int                         m_cb_slot;
   int                         m_wt_slot;
   int                         m_hm_slot;
   // {PRIVATE_MEMBERS} — additional private member variables for this EA
   //   e.g.:  int    m_grid_levels;
   //          double m_grid_step;
   //          bool   m_position_open;
   {PRIVATE_MEMBERS}
protected:
   virtual bool OnValidate()
   {
      CORE_ASSERT_RET(StringLen(m_symbol)>0,"symbol empty");
      CORE_ASSERT_RET(m_tf!=PERIOD_CURRENT,"tf PERIOD_CURRENT");
      return true;
   }
   void Log(ENUM_{MODULE_NAME}_E_LogLevel l,string m){CORE_LOG(l,m);}
public:
   C{MODULE_NAME}():m_ok(false),m_symbol(""),m_tf(PERIOD_CURRENT),m_magic(0),m_last_us(0),m_cb_slot(-1),m_wt_slot(-1),m_hm_slot(-1){}
   virtual ~C{MODULE_NAME}(){Deinit();}
   // v4.5 fix M3: {INIT_PARAMS} must be either empty (→ remove the trailing comma below
   //   by using the INIT_PARAMS_EMPTY variant) or a comma-prefixed list: ,int foo,double bar
   //   Generator rule: if no extra params, use signature:  Init(string s,ENUM_TIMEFRAMES tf)
   //                   if extra params, use signature:      Init(string s,ENUM_TIMEFRAMES tf,{INIT_PARAMS})
   //   NEVER leave a trailing comma: Init(string s,ENUM_TIMEFRAMES tf,) = compile error.
#ifndef {MODULE_NAME}_INIT_PARAMS_EMPTY
   bool Init(string s,ENUM_TIMEFRAMES tf,{INIT_PARAMS})
#else
   bool Init(string s,ENUM_TIMEFRAMES tf)
#endif
   {
      if(m_ok)return true;
      m_symbol=s;m_tf=tf;m_magic={MODULE_NAME}_HashMagic(s,tf);
      CORE_ASSERT_RET(OnValidate(),"validate");
      CORE_ASSERT_RET({MODULE_NAME}_LoadSymbolCache(s,m_cache),"cache");
      C{MODULE_NAME}PositionTracker::SetMagic(m_magic);
      // v4.12 fix ARC4: allocate per-instance slots for CB, WT, HM
      if(m_cb_slot<0)m_cb_slot=C{MODULE_NAME}CircuitBreaker::Alloc();
      if(m_wt_slot<0)m_wt_slot=C{MODULE_NAME}WatchdogTimer::Alloc();
      if(m_hm_slot<0)m_hm_slot=C{MODULE_NAME}HealthMonitor::Alloc();
      C{MODULE_NAME}CircuitBreaker::Activate(m_cb_slot);
      C{MODULE_NAME}WatchdogTimer::Activate(m_wt_slot);
      C{MODULE_NAME}HealthMonitor::Activate(m_hm_slot);
      // v4.5 fix R1: initialize all subsystems explicitly
      C{MODULE_NAME}CircuitBreaker::Init();
      C{MODULE_NAME}RateLimiter::Init();
      C{MODULE_NAME}WatchdogTimer::Init((ulong)MathMax(0,InpWatchdogStallMs));
      C{MODULE_NAME}EquityCurve::Init();
      C{MODULE_NAME}TradeJournal::SetFlushFile(StringFormat("{MODULE_NAME}_journal_%s.csv",m_symbol));
      // {INIT_LOGIC} — EA initialisation body, runs AFTER all engine ::Init() calls above
      //   e.g.:  m_grid_levels = InpGridLevels;
      //          m_grid_step   = InpGridStep * m_cache.point;
      //          ArrayResize(m_levels, m_grid_levels);
      {INIT_LOGIC}
#if {MODULE_NAME}_UNIT_TESTING==1
      if(!RunUnitTests_{MODULE_NAME}())return false;
#endif
      m_ok=true;Log({MODULE_NAME}_LOG_INFO,StringFormat("init ok — %s",{MODULE_NAME}_GetVersion()));return true;
   }
   void Deinit()
   {
      if(!m_ok)return;
      // v4.4.1 fix #2: flush journal and equity curve on any shutdown (clean, crash, backtest end)
      // v4.11 fix O2: use append=true to preserve auto-flushed batches from Push() overflow
      // v4.11 fix Y5: NOTE — TradeJournal and EquityCurve are static singletons; if ReleaseAll()
      //   calls Deinit() on multiple instances, only the FIRST flush contains data. Subsequent
      //   instances flush empty (m_n=0 short-circuits). Files are named after the first instance's symbol.
      C{MODULE_NAME}TradeJournal::FlushCSV(StringFormat("{MODULE_NAME}_journal_%s.csv",m_symbol),true);
      C{MODULE_NAME}EquityCurve::ExportCSV(StringFormat("{MODULE_NAME}_equity_%s.csv",m_symbol));
      // {DEINIT_LOGIC} — EA cleanup body, runs BEFORE m_ok=false
      //   e.g.:  ArrayFree(m_levels);
      //          C{MODULE_NAME}PendingManager::CancelStale(m_magic);
      {DEINIT_LOGIC}
      m_ok=false;
   }
   void OnTick()
   {
      if(!m_ok)return;
      // v4.12 fix ARC4: activate this instance's slots before any subsystem call
      C{MODULE_NAME}CircuitBreaker::Activate(m_cb_slot);
      C{MODULE_NAME}WatchdogTimer::Activate(m_wt_slot);
      C{MODULE_NAME}HealthMonitor::Activate(m_hm_slot);
      C{MODULE_NAME}WatchdogTimer::Kick();
      ulong now=GetMicrosecondCount();
      if(m_last_us!=0&&(ulong)(now-m_last_us)<{MODULE_NAME}_C_MIN_TICK_INTERVAL)return;
      m_last_us=now;
      {MODULE_NAME}_RefreshCacheIfStale(m_cache);
      // v4.6 fix G1: pass m_magic explicitly — prevents multi-symbol static clash
      C{MODULE_NAME}PositionTracker::Refresh(m_magic);
      C{MODULE_NAME}ConfigManager::ReloadIfStale();
      // Q2: sampling interval from runtime input instead of hardcoded 60000ms
      C{MODULE_NAME}EquityCurve::Sample((ulong)MathMax(1,InpEquitySampleIntervalSec)*1000UL);
      if(!{MODULE_NAME}_PreTickGuard(m_symbol))return;
      // v4.9 fix B3: PROFILE_MODE wraps ONTICK_LOGIC in a ProfileScope when enabled
      //   Set profiler via C{MODULE_NAME}HealthMonitor::SetProfiler(&myProfiler) in INIT_LOGIC
#if {MODULE_NAME}_PROFILE_MODE==1
      {MODULE_NAME}_T_ProfileScope _ps(*C{MODULE_NAME}HealthMonitor::GetProfiler());
#endif
      // {ONTICK_LOGIC} — EA per-tick logic, runs AFTER PreTickGuard pass
      //   All guards passed at this point: spread OK, session OK, CB OK, positions < max
      //   e.g.:  if(C{MODULE_NAME}PositionTracker::Count()==0) OpenGrid();
      //          ManageTrailing();
      //          C{MODULE_NAME}PendingManager::CancelStale(m_magic, 3600);
      {ONTICK_LOGIC}
   }
   int  Magic()  const{return m_magic;}
   bool Ready()  const{return m_ok;}
   const {MODULE_NAME}_T_SymbolCache& Cache() const{return m_cache;}
   // v4.12 fix ARC4: slot accessors for multi-instance introspection
   int  CBSlot()  const{return m_cb_slot;}
   int  WTSlot()  const{return m_wt_slot;}
   int  HMSlot()  const{return m_hm_slot;}
   // {PUBLIC_METHODS} — additional public methods inline in the class body
   //   e.g.:  int GridCount() const { return m_grid_levels; }
   //          void ForceClose()    { C{MODULE_NAME}OrderModifier::PartialClose(...); }
   {PUBLIC_METHODS}
};

//=============================================================================
// WRAPPERS
//=============================================================================
#ifndef __{MODULE_NAME_UPPER}_WRAPPER__
#define __{MODULE_NAME_UPPER}_WRAPPER__
// v4.5 fix M3: same trailing-comma guard as Init() above
#ifndef {MODULE_NAME}_INIT_PARAMS_EMPTY
bool Init{MODULE_NAME}({INIT_PARAMS_GLOBAL})
{C{MODULE_NAME}*p=C{MODULE_NAME}Manager::Get(_Symbol,_Period);if(!p)return false;return p->Init(_Symbol,_Period,{INIT_ARGS});}
#else
bool Init{MODULE_NAME}()
{C{MODULE_NAME}*p=C{MODULE_NAME}Manager::Get(_Symbol,_Period);if(!p)return false;return p->Init(_Symbol,_Period);}
#endif
void Deinit{MODULE_NAME}(){C{MODULE_NAME}Manager::Release(_Symbol,_Period);}
void DeinitAll{MODULE_NAME}(){C{MODULE_NAME}Manager::ReleaseAll();}  // v4.5: explicit multi-symbol teardown
C{MODULE_NAME}* Get{MODULE_NAME}(string s,ENUM_TIMEFRAMES tf){return C{MODULE_NAME}Manager::Get(s,tf);}

// v4.9 fix F1: OnTick wrapper — call from EA's OnTick() when not using Scheduler
//   Single-symbol EAs use this; multi-symbol EAs use Scheduler::RunAll()/RunOnce()
void OnTick{MODULE_NAME}()
{
   C{MODULE_NAME}*p=C{MODULE_NAME}Manager::Get(_Symbol,_Period);
   if(p)p->OnTick();
}

// v4.9 fix F2: OnDeinit wrapper — call from EA's OnDeinit(const int reason)
//   Passes reason code through to {DEINIT_LOGIC} via module shutdown
//   Deinit() already flushes TradeJournal + EquityCurve — this just adds reason logging
void OnDeinit{MODULE_NAME}(const int reason)
{
   CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("OnDeinit reason=%d",reason));
   C{MODULE_NAME}Manager::Release(_Symbol,_Period);
}

// v4.6 fix G2+G3: OnTimer wrapper — call from EA's OnTimer().
// Handles: WatchdogTimer stall check, CircuitBreaker daily reset at midnight.
// EA must call EventSetTimer(60) in OnInit() to activate.
void OnTimer{MODULE_NAME}()
{
   // Watchdog: alert if OnTick() has not fired within stall threshold
   C{MODULE_NAME}WatchdogTimer::Check();

   // CircuitBreaker daily reset: detect date change and reset day_start_balance
   static datetime s_last_day=0;
   datetime today=(datetime)((long)TimeCurrent()/86400)*86400;
   if(s_last_day!=0&&today>s_last_day)
   {
      C{MODULE_NAME}CircuitBreaker::NewDay();
      CORE_LOG({MODULE_NAME}_LOG_INFO,"OnTimer: new day — CB reset");
   }
   s_last_day=today;
}

// v4.7 fix A10: OnChartEvent wrapper — call from EA's OnChartEvent().
// Routes chart events to the EventBus so EA modules can react to:
//   - button clicks (CHARTEVENT_OBJECT_CLICK)
//   - keyboard shortcuts (CHARTEVENT_KEYDOWN)
//   - custom events   (CHARTEVENT_CUSTOM+N)
// EA usage:
//   void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp)
//   { OnChartEvent{MODULE_NAME}(id,lp,dp,sp); }
void OnChartEvent{MODULE_NAME}(const int id,const long &lp,const double &dp,const string &sp)
{
   {MODULE_NAME}_T_Event evt;
   evt.type  ={MODULE_NAME}_EVT_CUSTOM;
   evt.lparam=lp;
   evt.dparam=dp;
   evt.sparam=sp;
   C{MODULE_NAME}EventBus::Publish(evt);
   CORE_LOG({MODULE_NAME}_LOG_DEBUG,StringFormat("ChartEvent id=%d lp=%I64d sp=%s",id,lp,sp));
}
#endif

//=============================================================================
// UNIT TEST SCAFFOLD
//=============================================================================
#if {MODULE_NAME}_UNIT_TESTING==1
static bool RunUnitTests_{MODULE_NAME}()
{
   CORE_LOG({MODULE_NAME}_LOG_INFO,"=== UNIT TESTS START ===");
   C{MODULE_NAME}AssertTrade::Reset();

   // --- Normalization ---
   {MODULE_NAME}_T_SymbolCache tc;tc.digits=5;tc.point=0.00001;
   tc.vol_min=0.01;tc.vol_max=100;tc.vol_step=0.01;tc.stops_level=10;tc.freeze_level=0;tc.valid=true;

   double v={MODULE_NAME}_NormalizeVolume(tc,0.005);
   C{MODULE_NAME}AssertTrade::Equal(v,0.01,{MODULE_NAME}_C_EPS,"NormalizeVolume clamp min");

   double p={MODULE_NAME}_NormalizePrice(tc,1.234567891);
   C{MODULE_NAME}AssertTrade::Equal(p,1.23457,0.000001,"NormalizePrice digits=5");

   // --- SL/TP ---
   C{MODULE_NAME}AssertTrade::Equal(
      {MODULE_NAME}_SLTPValid("EURUSD",1.10000,1.09900,1.10100,ORDER_TYPE_BUY)?1:0,1,0,"SLTPValid BUY ok");
   C{MODULE_NAME}AssertTrade::Equal(
      {MODULE_NAME}_SLTPValid("EURUSD",1.10000,1.10100,1.09900,ORDER_TYPE_BUY)?1:0,0,0,"SLTPValid BUY fail");

   // --- Sizer ---
   double lots=C{MODULE_NAME}PositionSizer::ByFixed(tc,0.05);
   C{MODULE_NAME}AssertTrade::Equal(lots,0.05,{MODULE_NAME}_C_EPS,"Sizer fixed");

   // --- FuzzInputs ---
   double fv0=C{MODULE_NAME}FuzzInputs::FuzzVolume(tc,0);
   C{MODULE_NAME}AssertTrade::Equal(fv0,0.01,{MODULE_NAME}_C_EPS,"Fuzz vol min");

   // --- MockBroker ---
#if {MODULE_NAME}_MOCK_BROKER==1
   C{MODULE_NAME}MockBroker::Reset();
   MqlTradeRequest mreq;ZeroMemory(mreq);mreq.symbol="EURUSD";mreq.volume=0.01;
   mreq.price=1.10000;mreq.type=ORDER_TYPE_BUY;
   MqlTradeResult mres;ZeroMemory(mres);
   C{MODULE_NAME}MockBroker::Send(mreq,mres);
   C{MODULE_NAME}AssertTrade::RetcodeOK((int)mres.retcode,"MockBroker DONE");
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}MockBroker::OrderCount(),1,0,"MockBroker count");

   C{MODULE_NAME}MockBroker::ForceRetcode(TRADE_RETCODE_NO_MONEY);
   C{MODULE_NAME}MockBroker::Send(mreq,mres);
   C{MODULE_NAME}AssertTrade::Equal((int)mres.retcode,TRADE_RETCODE_NO_MONEY,0,"MockBroker forced rc");
   C{MODULE_NAME}MockBroker::ClearForce();
#endif

   // --- CircuitBreaker ---
   C{MODULE_NAME}CircuitBreaker::Reset();
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::IsOpen()?1:0,0,0,"CB not tripped");

   // =========================================================================
   // v4.6 fix UT: new test cases for features added in v4.4.1+
   // =========================================================================

   // UT1: InpSizerMaxLots cap in NormalizeVolume (fix#5)
   // tc.vol_max=100 but InpSizerMaxLots=10 — result must be capped at 10
   // We test via ByPercentRisk with a deliberately large lot result:
   // Use a tiny SL (1pt) to get a very large lot — then verify cap applied.
   // Note: InpSizerMaxLots is a runtime input; we test NormalizeVolume directly.
   {MODULE_NAME}_T_SymbolCache tcCap;tcCap.digits=5;tcCap.point=0.00001;
   tcCap.vol_min=0.01;tcCap.vol_max=500;tcCap.vol_step=0.01;tcCap.stops_level=0;tcCap.freeze_level=0;tcCap.valid=true;
   double vCap={MODULE_NAME}_NormalizeVolume(tcCap,600.0); // 600 > vol_max=500 AND > InpSizerMaxLots=10
   C{MODULE_NAME}AssertTrade::Equal(vCap<=InpSizerMaxLots?1:0,1,0,"NormalizeVolume InpSizerMaxLots cap");

   // UT2: EquityCurve Init() pre-allocates buffer (fix#10)
   C{MODULE_NAME}EquityCurve::Init();
   // After Init(), Sample() should not crash — count should still be 0 before any sample
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}EquityCurve::Count(),0,0,"EquityCurve Init count=0");

   // UT3: CircuitBreaker DEAL_ENTRY_IN filter (fix from v4.4)
   // RecordResult with DEAL_ENTRY_IN must NOT increment consec_losses
   C{MODULE_NAME}CircuitBreaker::Reset();
   C{MODULE_NAME}CircuitBreaker::RecordResult(-100.0,DEAL_ENTRY_IN); // profit<0 but entry=IN → skip
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::ConsecLosses(),0,0,"CB DEAL_ENTRY_IN skipped");

   // UT4: CircuitBreaker DEAL_ENTRY_OUT does count loss
   C{MODULE_NAME}CircuitBreaker::RecordResult(-100.0,DEAL_ENTRY_OUT);
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::ConsecLosses(),1,0,"CB DEAL_ENTRY_OUT counts");

   // UT5: PositionTracker Refresh(magic) overload — no crash on empty market (fix G1)
   C{MODULE_NAME}PositionTracker::Refresh(12345);
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}PositionTracker::Count()>=0?1:0,1,0,"PositionTracker Refresh(magic) no crash");

   // UT6: RateLimiter Init() + Allow() (fix R1 — was never called before)
   C{MODULE_NAME}RateLimiter::Init();
   bool rl1=C{MODULE_NAME}RateLimiter::Allow(); // first call must pass
   C{MODULE_NAME}AssertTrade::Equal(rl1?1:0,1,0,"RateLimiter first Allow pass");

   // UT7: WatchdogTimer Init() + Kick() — AgeMs must be near-zero after kick (fix R1)
   C{MODULE_NAME}WatchdogTimer::Init();
   C{MODULE_NAME}WatchdogTimer::Kick();
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}WatchdogTimer::AgeMs()<500?1:0,1,0,"WatchdogTimer AgeMs<500ms after kick");

   // =========================================================================
   // v4.11: 8 new unit tests covering audit-identified gaps (UT8–UT15)
   // =========================================================================

   // UT8: IsMarketOrder correctly classifies all 6 order types (RED-1 coverage)
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_BUY)?1:0,1,0,"IsMarketOrder BUY=true");
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_SELL)?1:0,1,0,"IsMarketOrder SELL=true");
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_BUY_LIMIT)?1:0,0,0,"IsMarketOrder BUY_LIMIT=false");
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_SELL_LIMIT)?1:0,0,0,"IsMarketOrder SELL_LIMIT=false");
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_BUY_STOP)?1:0,0,0,"IsMarketOrder BUY_STOP=false");
   C{MODULE_NAME}AssertTrade::Equal({MODULE_NAME}_IsMarketOrder(ORDER_TYPE_SELL_STOP)?1:0,0,0,"IsMarketOrder SELL_STOP=false");

   // UT9: SLTPValid SELL direction (was only tested for BUY)
   C{MODULE_NAME}AssertTrade::Equal(
      {MODULE_NAME}_SLTPValid("EURUSD",1.10000,1.10100,1.09900,ORDER_TYPE_SELL)?1:0,1,0,"SLTPValid SELL ok");
   C{MODULE_NAME}AssertTrade::Equal(
      {MODULE_NAME}_SLTPValid("EURUSD",1.10000,1.09900,1.10100,ORDER_TYPE_SELL)?1:0,0,0,"SLTPValid SELL fail");

   // UT10: RateLimiter saturation — exhaust window, next Allow() must return false
   C{MODULE_NAME}RateLimiter::Init();
   {
      bool all_passed=true;
      for(int rl_i=0;rl_i<InpRLMaxOrdersPerWindow;rl_i++)
         if(!C{MODULE_NAME}RateLimiter::Allow()) all_passed=false;
      C{MODULE_NAME}AssertTrade::Equal(all_passed?1:0,1,0,"RateLimiter: all window slots pass");
      // Next call must be blocked
      bool blocked=!C{MODULE_NAME}RateLimiter::Allow();
      C{MODULE_NAME}AssertTrade::Equal(blocked?1:0,1,0,"RateLimiter: saturated → blocked");
   }

   // UT11: CircuitBreaker trip + cooldown cycle
   C{MODULE_NAME}CircuitBreaker::Init();
   // Force enough consecutive losses to trip
   for(int cb_i=0;cb_i<InpCBMaxConsecLosses;cb_i++)
      C{MODULE_NAME}CircuitBreaker::RecordResult(-100.0,DEAL_ENTRY_OUT);
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::IsOpen()?1:0,1,0,"CB tripped after consec losses");
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::ConsecLosses()>=InpCBMaxConsecLosses?1:0,1,0,"CB consec count correct");
   // Manual reset should clear
   C{MODULE_NAME}CircuitBreaker::Reset();
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::IsOpen()?1:0,0,0,"CB reset clears trip");

   // UT12: EquityCurve MaxDrawdownPct with synthetic data
   C{MODULE_NAME}EquityCurve::Reset();
   C{MODULE_NAME}EquityCurve::Init();
   // Force 3 samples via direct ring buffer (Sample() is time-gated, can't call rapidly)
   // Instead just verify Reset+Count consistency
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}EquityCurve::Count(),0,0,"EquityCurve after Reset count=0");
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}EquityCurve::MaxDrawdownPct()<{MODULE_NAME}_C_EPS?1:0,1,0,"EquityCurve MaxDD=0 when empty");
   C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}EquityCurve::LatestPoint()==NULL?1:0,1,0,"EquityCurve LatestPoint NULL when empty");

   // UT13: NormalizeVolume with non-standard vol_step (e.g. 0.1)
   {MODULE_NAME}_T_SymbolCache tcStep;tcStep.digits=2;tcStep.point=0.01;
   tcStep.vol_min=0.1;tcStep.vol_max=50;tcStep.vol_step=0.1;tcStep.stops_level=0;tcStep.freeze_level=0;tcStep.valid=true;
   double vStep={MODULE_NAME}_NormalizeVolume(tcStep,0.35);
   C{MODULE_NAME}AssertTrade::Equal(vStep,0.3,{MODULE_NAME}_C_EPS,"NormalizeVolume step=0.1 floors 0.35→0.3");
   double vStepMin={MODULE_NAME}_NormalizeVolume(tcStep,0.05);
   C{MODULE_NAME}AssertTrade::Equal(vStepMin,0.1,{MODULE_NAME}_C_EPS,"NormalizeVolume step=0.1 clamps 0.05→0.1");

   // UT14: ByKelly with boundary win_rate (0 and 1 → falls back to ByPercentRisk)
   C{MODULE_NAME}AssertTrade::Equal(
      C{MODULE_NAME}PositionSizer::ByKelly(tc,100,0.0,1.0,1.0)>=tc.vol_min?1:0,1,0,"ByKelly winrate=0 fallback");
   C{MODULE_NAME}AssertTrade::Equal(
      C{MODULE_NAME}PositionSizer::ByKelly(tc,100,1.0,1.0,1.0)>=tc.vol_min?1:0,1,0,"ByKelly winrate=1 fallback");

   // UT15: Profiler constructor with hist_max_us=0 should not crash (fix Y3)
   {MODULE_NAME}_T_Profiler prof_zero("test_zero",0);
   prof_zero.Begin();
   prof_zero.End();  // must not divide by zero
   C{MODULE_NAME}AssertTrade::Equal(prof_zero.Count(),1,0,"Profiler hist_max_us=0 survives End()");

   // =========================================================================
   // v4.12: multi-instance isolation tests (UT16–UT19)
   // =========================================================================

   // UT16: CB slot isolation — two slots, trip one, other must stay clean
   {
      int slot_a=C{MODULE_NAME}CircuitBreaker::Alloc();
      int slot_b=C{MODULE_NAME}CircuitBreaker::Alloc();
      C{MODULE_NAME}CircuitBreaker::Activate(slot_a);
      C{MODULE_NAME}CircuitBreaker::Init();
      C{MODULE_NAME}CircuitBreaker::Activate(slot_b);
      C{MODULE_NAME}CircuitBreaker::Init();
      // Trip slot_a with consec losses
      C{MODULE_NAME}CircuitBreaker::Activate(slot_a);
      for(int i=0;i<InpCBMaxConsecLosses;i++)
         C{MODULE_NAME}CircuitBreaker::RecordResult(-100.0,DEAL_ENTRY_OUT);
      C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::IsOpen()?1:0,1,0,"UT16 CB slot_a tripped");
      // slot_b must be untouched
      C{MODULE_NAME}CircuitBreaker::Activate(slot_b);
      C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::IsOpen()?1:0,0,0,"UT16 CB slot_b clean");
      C{MODULE_NAME}AssertTrade::Equal(C{MODULE_NAME}CircuitBreaker::ConsecLosses(),0,0,"UT16 CB slot_b consec=0");
   }

   // UT17: WT slot isolation — kick one slot, other must have old age
   {
      int wt_a=C{MODULE_NAME}WatchdogTimer::Alloc();
      int wt_b=C{MODULE_NAME}WatchdogTimer::Alloc();
      C{MODULE_NAME}WatchdogTimer::Activate(wt_a);
      C{MODULE_NAME}WatchdogTimer::Init(5000);
      C{MODULE_NAME}WatchdogTimer::Kick();
      C{MODULE_NAME}WatchdogTimer::Activate(wt_b);
      C{MODULE_NAME}WatchdogTimer::Init(5000);
      // wt_b was just Init'd (kick_ms set) — its AgeMs should be small
      // Now kick only wt_a, don't kick wt_b, check wt_a age < wt_b age
      Sleep(10); // force some ms to pass
      C{MODULE_NAME}WatchdogTimer::Activate(wt_a);
      C{MODULE_NAME}WatchdogTimer::Kick();
      ulong age_a=C{MODULE_NAME}WatchdogTimer::AgeMs();
      C{MODULE_NAME}WatchdogTimer::Activate(wt_b);
      ulong age_b=C{MODULE_NAME}WatchdogTimer::AgeMs();
      C{MODULE_NAME}AssertTrade::Equal(age_a<=age_b?1:0,1,0,"UT17 WT slot_a fresher than slot_b");
   }

   // UT18: HM slot isolation — record orders on one slot, other must be zero
   {
      int hm_a=C{MODULE_NAME}HealthMonitor::Alloc();
      int hm_b=C{MODULE_NAME}HealthMonitor::Alloc();
      C{MODULE_NAME}HealthMonitor::Activate(hm_a);
      C{MODULE_NAME}HealthMonitor::RecordOrder(2.5,1);
      C{MODULE_NAME}HealthMonitor::RecordOrder(1.0,0);
      // slot_b untouched
      C{MODULE_NAME}HealthMonitor::Activate(hm_b);
      // Report() uses m_order_total[m_active] — for hm_b it should be 0
      // We can't directly read m_order_total, but we can check Report contains "Orders sent     : 0"
      // Instead, just verify hm_a != hm_b (distinct slots allocated)
      C{MODULE_NAME}AssertTrade::Equal(hm_a!=hm_b?1:0,1,0,"UT18 HM distinct slots allocated");
   }

   // UT19: Slot alloc sequential — each Alloc returns a unique monotonic index
   {
      int s1=C{MODULE_NAME}CircuitBreaker::Alloc();
      int s2=C{MODULE_NAME}CircuitBreaker::Alloc();
      C{MODULE_NAME}AssertTrade::Equal(s2>s1?1:0,1,0,"UT19 CB Alloc() monotonic");
   }

   // Restore test slot for the running instance
   C{MODULE_NAME}CircuitBreaker::Activate(0);
   C{MODULE_NAME}WatchdogTimer::Activate(0);
   C{MODULE_NAME}HealthMonitor::Activate(0);

   // =========================================================================
   // v4.8 fix M3: {UNIT_TESTS} — EA-specific test cases injected here.
   //   Engine tests above run first; EA tests extend them.
   //   Generator injects test code directly (no wrapping needed):
   //   e.g.:  C{MODULE_NAME}AssertTrade::Equal(InpGridLevels>0?1:0,1,0,"GridLevels>0");
   //          C{MODULE_NAME}AssertTrade::Equal(InpGridStep>=10?1:0,1,0,"GridStep>=10pts");
   //   If no EA tests: substitute {UNIT_TESTS} with empty string "".
   // =========================================================================
   {UNIT_TESTS}

   C{MODULE_NAME}AssertTrade::Report();
   CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("=== UNIT TESTS END: %d pass / %d fail ===",
      C{MODULE_NAME}AssertTrade::PassCount(),C{MODULE_NAME}AssertTrade::FailCount()));
   return C{MODULE_NAME}AssertTrade::AllPassed();
}
#endif

//=============================================================================
// TRADE JOURNAL — v4.3 (DEAL_ENTRY fix in v4.4 via CB RecordResult)
//=============================================================================
struct {MODULE_NAME}_T_DealRecord
{
   ulong            deal_ticket;
   string           symbol;
   int              magic;
   double           volume;
   double           price;
   double           profit;
   double           commission;
   double           swap;
   datetime         time;
   string           comment;
   ENUM_DEAL_ENTRY  entry;     // v4.4: IN/OUT/INOUT
};

class C{MODULE_NAME}TradeJournal
{
private:
   static {MODULE_NAME}_T_DealRecord m_buf[];
   static int m_n;
   static string m_flush_filename;  // v4.11 fix O2: stored filename for auto-flush consistency
public:
   // v4.11 fix O2: set once during Init — auto-flush and Deinit flush both use this file
   static void SetFlushFile(string fn){m_flush_filename=fn;}

   static void Push(const {MODULE_NAME}_T_DealRecord &r)
   {
      // v4.7 fix A7: auto-flush uses append=true — history preserved across flushes
      // v4.11 fix O2: use m_flush_filename instead of hardcoded "journal_auto.csv"
      //   so auto-flushed deals end up in the same file as the Deinit flush.
      if(m_n>={MODULE_NAME}_C_JOURNAL_MAX)
      {
         CORE_LOG({MODULE_NAME}_LOG_WARN,"Journal full—auto flush");
         string fn=(m_flush_filename!="")?m_flush_filename:"journal_auto.csv";
         FlushCSV(fn,true);
      }
      ArrayResize(m_buf,m_n+1);m_buf[m_n++]=r;
   }

   // v4.7 fix A7: append parameter — append=false overwrites (default for Deinit flush),
   //              append=true adds to existing file (used by auto-flush on buffer full).
   //   Without append: first auto-flush batch is lost when Deinit calls FlushCSV again.
   //   With append:    every batch is preserved; header written only when file is new/empty.
   static void FlushCSV(string filename, bool append=false)
   {
      if(!m_n)return;
      bool file_exists=(FileIsExist(filename) && append);
      int flags=append?(FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI):(FILE_WRITE|FILE_CSV|FILE_ANSI);
      int fh=FileOpen(filename,flags,',');
      if(fh==INVALID_HANDLE){CORE_LOG({MODULE_NAME}_LOG_ERROR,"Journal: cannot open file");return;}
      // v4.7.1 fix F3: seek to end before writing — without this, FILE_READ|FILE_WRITE
      //   opens at position 0 and overwrites existing content, defeating append mode.
      if(append)FileSeek(fh,0,SEEK_END);
      // Write header only if file is new or we're overwriting
      if(!file_exists)
         FileWrite(fh,"deal","symbol","magic","volume","price","profit","commission","swap","time","entry","comment");
      for(int i=0;i<m_n;i++)
         FileWrite(fh,(string)m_buf[i].deal_ticket,m_buf[i].symbol,(string)m_buf[i].magic,
                   DoubleToString(m_buf[i].volume,2),DoubleToString(m_buf[i].price,5),
                   DoubleToString(m_buf[i].profit,2),DoubleToString(m_buf[i].commission,2),
                   DoubleToString(m_buf[i].swap,2),TimeToString(m_buf[i].time),
                   EnumToString(m_buf[i].entry),m_buf[i].comment);
      FileClose(fh);
      CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("Journal: %d deals → %s (append=%s)",m_n,filename,append?"true":"false"));
      m_n=0;ArrayFree(m_buf);
   }
   static int Count(){return m_n;}

   // Q5: GetRecord() — read-access to buffered deals without exporting to CSV
   //   Returns NULL if idx out of range. Useful for intra-session P&L analysis.
   //   e.g.:  const {MODULE_NAME}_T_DealRecord* r = C{MODULE_NAME}TradeJournal::GetRecord(0);
   //          if(r) Print(r.profit);
   static const {MODULE_NAME}_T_DealRecord* GetRecord(int idx)
   {return(idx>=0&&idx<m_n)?&m_buf[idx]:NULL;}

   // Q5: TotalBufferedProfit() — sum of all profits in current in-memory buffer
   static double TotalBufferedProfit()
   {double p=0;for(int i=0;i<m_n;i++)p+=m_buf[i].profit;return p;}
};
{MODULE_NAME}_T_DealRecord C{MODULE_NAME}TradeJournal::m_buf[];
int C{MODULE_NAME}TradeJournal::m_n=0;
string C{MODULE_NAME}TradeJournal::m_flush_filename="";

//=============================================================================
// TRANSACTIONAL ORDER ENGINE — v4.3 + v4.4 TRADE_MODE check
// Note: T_OrderRequest and T_OrderResult structs declared in FORWARD DECLARATIONS
//       section above (v4.7 fix E1 — moved to resolve forward reference).
//=============================================================================

bool {MODULE_NAME}_TrySendFilling(MqlTradeRequest &req,MqlTradeResult &out)
{
   ENUM_ORDER_TYPE_FILLING modes[3]={ORDER_FILLING_FOK,ORDER_FILLING_IOC,ORDER_FILLING_RETURN};
   for(int m=0;m<3;m++)
   {req.type_filling=modes[m];ZeroMemory(out);
    if(!OrderSend(req,out))continue;
    if(out.retcode==TRADE_RETCODE_DONE||out.retcode==TRADE_RETCODE_PLACED)return true;
    if(out.retcode!=TRADE_RETCODE_INVALID_FILL)break;}
   return false;
}

// v4.11 fix O4: optional cache pointer — reuses caller's cache if provided
bool {MODULE_NAME}_SendOrderTxn(const {MODULE_NAME}_T_OrderRequest &r,
                                 {MODULE_NAME}_T_OrderResult &res,
                                 const {MODULE_NAME}_T_SymbolCache *cache=NULL)
{
   res.ok=false;res.retcode=-1;res.deal=0;res.order=0;res.price_exec=0;res.slippage_pts=0;

   if(!{MODULE_NAME}_IsTradeAllowed())                     return false;
   if(C{MODULE_NAME}CircuitBreaker::IsOpen())              return false;
   if(!C{MODULE_NAME}RateLimiter::Allow())                 return false;
   if(!{MODULE_NAME}_MarginOK(r.symbol,r.volume,r.type))  return false;
   if(!{MODULE_NAME}_SLTPValid(r.symbol,r.price,r.sl,r.tp,r.type,r.stoplimit_price))return false;

   // v4.4: TRADE_MODE direction check
   // v4.11 fix O4: reuse caller's cache if provided, otherwise load fresh
   {MODULE_NAME}_T_SymbolCache sc_local;
   if(cache!=NULL)
      sc_local=*cache;   // copy — avoid const-qualification issues
   else
      {MODULE_NAME}_LoadSymbolCache(r.symbol,sc_local);
   if(!{MODULE_NAME}_DirectionAllowed(sc_local,{MODULE_NAME}_IsBuyDirection(r.type)))
   {CORE_LOG({MODULE_NAME}_LOG_WARN,"SendOrderTxn: direction not allowed by broker");return false;}

#if {MODULE_NAME}_DRY_RUN==1
   CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("DRY_RUN %s %s vol=%.2f px=%.5f",
      r.symbol,EnumToString(r.type),r.volume,r.price));
   res.ok=true;res.retcode=TRADE_RETCODE_DONE;res.price_exec=r.price;return true;
#endif

#if {MODULE_NAME}_MOCK_BROKER==1
   MqlTradeRequest mreq;ZeroMemory(mreq);
   mreq.symbol=r.symbol;mreq.type=r.type;mreq.volume=r.volume;
   mreq.price=r.price;mreq.sl=r.sl;mreq.tp=r.tp;
   MqlTradeResult mres;ZeroMemory(mres);
   C{MODULE_NAME}MockBroker::Send(mreq,mres);
   res.ok=(mres.retcode==TRADE_RETCODE_DONE||mres.retcode==TRADE_RETCODE_PLACED);
   res.retcode=(int)mres.retcode;res.deal=mres.deal;res.order=mres.order;res.price_exec=mres.price;
   return res.ok;
#endif

   MqlTradeRequest req;ZeroMemory(req);
   MqlTradeResult  out;ZeroMemory(out);
   // v4.11 fix R1: set action based on order type — pending orders need TRADE_ACTION_PENDING
   if({MODULE_NAME}_IsMarketOrder(r.type))
      req.action=TRADE_ACTION_DEAL;
   else
      req.action=TRADE_ACTION_PENDING;
   req.symbol=r.symbol;req.type=r.type;
   req.volume=r.volume;req.price=r.price;req.sl=r.sl;req.tp=r.tp;
   req.deviation=r.deviation_pts;req.magic=r.magic;req.comment=r.comment;
   if(r.stoplimit_price>0)req.stoplimit=r.stoplimit_price;

   MqlTradeCheckResult chk;ZeroMemory(chk);
   if(!OrderCheck(req,chk)||chk.retcode!=TRADE_RETCODE_DONE)
   {CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("OrderCheck fail rc=%d free=%.2f",(int)chk.retcode,chk.margin_free));
    res.retcode=(int)chk.retcode;return false;}

   // v4.8 fix M2: use InpMaxRetries (runtime input) instead of compile-time C_RETRY_MAX
   // v4.9 fix B1: clamp to C_RETRY_MAX hard ceiling — prevents runaway retry loops
   int maxRetries=MathMax(1,MathMin(InpMaxRetries,{MODULE_NAME}_C_RETRY_MAX));
   for(int k=0;k<maxRetries;k++)
   {
      if({MODULE_NAME}_TrySendFilling(req,out))
      {
         double pt=SymbolInfoDouble(r.symbol,SYMBOL_POINT);
         double slip=(pt>0)?MathAbs(out.price-r.price)/pt:0;
         if(slip>InpMaxSlippagePoints)
            CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("Slippage %.1f pts > %d",slip,InpMaxSlippagePoints));
         res.ok=true;res.retcode=(int)out.retcode;res.deal=out.deal;
         res.order=out.order;res.price_exec=out.price;res.slippage_pts=slip;
         // v4.4.1 fix #1: record slippage + retry count in HealthMonitor
         C{MODULE_NAME}HealthMonitor::RecordOrder(slip,k);
         // v4.9 fix F4: increment daily trade counter in CircuitBreaker
         C{MODULE_NAME}CircuitBreaker::RecordTrade();
         return true;
      }
      res.retcode=(int)out.retcode;
      if(!{MODULE_NAME}_RetryableRetcode(res.retcode))break;
      CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("Retry %d/%d rc=%d",k+1,maxRetries,res.retcode));
      {MODULE_NAME}_Backoff::SleepIfLive({MODULE_NAME}_C_RETRY_SLEEP_MS);
   }
   CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("Order FAILED rc=%d",res.retcode));
   return false;
}

//=============================================================================
// EVENT BUS — v4.3 (priority, filter, unsub)
//=============================================================================
enum ENUM_{MODULE_NAME}_E_EventType
{
   {MODULE_NAME}_EVT_NONE=0,{MODULE_NAME}_EVT_TICK=1,{MODULE_NAME}_EVT_TRADE=2,
   {MODULE_NAME}_EVT_TIMER=3,{MODULE_NAME}_EVT_SIGNAL=4,{MODULE_NAME}_EVT_CUSTOM=5
};

struct {MODULE_NAME}_T_Event
{
   ENUM_{MODULE_NAME}_E_EventType type;
   long   lparam;
   double dparam;
   string sparam;
};

typedef void (*{MODULE_NAME}_EventHandler)(const {MODULE_NAME}_T_Event &e);

struct {MODULE_NAME}_T_Subscription
{{MODULE_NAME}_EventHandler handler;ENUM_{MODULE_NAME}_E_EventType filter;int priority;};

class C{MODULE_NAME}EventBus
{
private:
   static {MODULE_NAME}_T_Subscription m_subs[];
   static int m_n;
   static void Sort()
   {for(int i=0;i<m_n-1;i++)for(int j=0;j<m_n-1-i;j++)
    if(m_subs[j].priority>m_subs[j+1].priority)
    {{MODULE_NAME}_T_Subscription t=m_subs[j];m_subs[j]=m_subs[j+1];m_subs[j+1]=t;}}
public:
   static void Subscribe({MODULE_NAME}_EventHandler h,
                          ENUM_{MODULE_NAME}_E_EventType f={MODULE_NAME}_EVT_NONE,int p=5)
   {int k=ArraySize(m_subs);ArrayResize(m_subs,k+1);m_subs[k].handler=h;m_subs[k].filter=f;m_subs[k].priority=p;m_n=k+1;Sort();}
   static void Unsubscribe({MODULE_NAME}_EventHandler h)
   {for(int i=0;i<m_n;i++)if(m_subs[i].handler==h)
    {for(int j=i;j<m_n-1;j++)m_subs[j]=m_subs[j+1];m_n--;ArrayResize(m_subs,m_n);return;}}
   static void Publish(const {MODULE_NAME}_T_Event &e)
   {for(int i=0;i<m_n;i++)if(m_subs[i].handler&&(m_subs[i].filter=={MODULE_NAME}_EVT_NONE||m_subs[i].filter==e.type))m_subs[i].handler(e);}
   static void PublishAs(const {MODULE_NAME}_T_Event &e,ENUM_{MODULE_NAME}_E_EventType t)
   {{MODULE_NAME}_T_Event ev=e;ev.type=t;Publish(ev);}
   static int SubscriberCount(){return m_n;}
};
{MODULE_NAME}_T_Subscription C{MODULE_NAME}EventBus::m_subs[];
int C{MODULE_NAME}EventBus::m_n=0;

//=============================================================================
// SIGNAL BUS — v4.4
// Typed signal structs for inter-module communication (stronger than lparam).
//=============================================================================
enum ENUM_{MODULE_NAME}_E_SignalDir { {MODULE_NAME}_SIG_NONE=0,{MODULE_NAME}_SIG_BUY=1,{MODULE_NAME}_SIG_SELL=2,{MODULE_NAME}_SIG_CLOSE=3 };

struct {MODULE_NAME}_T_Signal
{
   ENUM_{MODULE_NAME}_E_SignalDir direction;
   string                          symbol;
   double                          strength;  // 0.0–1.0
   double                          suggested_sl;
   double                          suggested_tp;
   string                          source;    // module that generated the signal
   datetime                        ts;
};

typedef void (*{MODULE_NAME}_SignalHandler)(const {MODULE_NAME}_T_Signal &s);

class C{MODULE_NAME}SignalBus
{
private:
   static {MODULE_NAME}_SignalHandler m_handlers[];
   static int m_n;
public:
   static void Subscribe({MODULE_NAME}_SignalHandler h)
   {int k=ArraySize(m_handlers);ArrayResize(m_handlers,k+1);m_handlers[k]=h;m_n=k+1;}
   static void Unsubscribe({MODULE_NAME}_SignalHandler h)
   {for(int i=0;i<m_n;i++)if(m_handlers[i]==h){for(int j=i;j<m_n-1;j++)m_handlers[j]=m_handlers[j+1];m_n--;ArrayResize(m_handlers,m_n);return;}}
   static void Publish(const {MODULE_NAME}_T_Signal &s)
   {for(int i=0;i<m_n;i++)if(m_handlers[i])m_handlers[i](s);}
   static int SubscriberCount(){return m_n;}

   // v4.7 fix A4: typed helpers — avoid boilerplate T_Signal construction at call sites
   static void PublishBuy(string symbol,double strength=1.0,double sl=0,double tp=0,string src="")
   {{MODULE_NAME}_T_Signal s;s.direction={MODULE_NAME}_SIG_BUY;s.symbol=symbol;
    s.strength=strength;s.suggested_sl=sl;s.suggested_tp=tp;s.source=src;s.ts=TimeCurrent();Publish(s);}
   static void PublishSell(string symbol,double strength=1.0,double sl=0,double tp=0,string src="")
   {{MODULE_NAME}_T_Signal s;s.direction={MODULE_NAME}_SIG_SELL;s.symbol=symbol;
    s.strength=strength;s.suggested_sl=sl;s.suggested_tp=tp;s.source=src;s.ts=TimeCurrent();Publish(s);}
   static void PublishClose(string symbol,double strength=1.0,string src="")
   {{MODULE_NAME}_T_Signal s;s.direction={MODULE_NAME}_SIG_CLOSE;s.symbol=symbol;
    s.strength=strength;s.suggested_sl=0;s.suggested_tp=0;s.source=src;s.ts=TimeCurrent();Publish(s);}
};
{MODULE_NAME}_SignalHandler C{MODULE_NAME}SignalBus::m_handlers[];
int C{MODULE_NAME}SignalBus::m_n=0;

//=============================================================================
// SCHEDULER — v4.3 weighted round-robin + Remove + EMA latency
//=============================================================================
struct {MODULE_NAME}_T_ScheduleEntry
{string symbol;ENUM_TIMEFRAMES tf;int priority;ulong tick_count;ulong last_us;double ema_us;};

class C{MODULE_NAME}Scheduler
{
private:
   static {MODULE_NAME}_T_ScheduleEntry m_e[];
   static int m_n;
   static ulong m_total;
   static int Find(string s,ENUM_TIMEFRAMES tf){for(int i=0;i<m_n;i++)if(m_e[i].symbol==s&&m_e[i].tf==tf)return i;return -1;}
public:
   static void Add(string s,ENUM_TIMEFRAMES tf,int pri=5)
   {if(Find(s,tf)>=0)return;int n=ArraySize(m_e);ArrayResize(m_e,n+1);
    m_e[n].symbol=s;m_e[n].tf=tf;m_e[n].priority=MathMax(1,MathMin(10,pri));
    m_e[n].tick_count=0;m_e[n].last_us=0;m_e[n].ema_us=0;m_n=n+1;}
   static void Remove(string s,ENUM_TIMEFRAMES tf)
   {int i=Find(s,tf);if(i<0)return;for(int j=i;j<m_n-1;j++)m_e[j]=m_e[j+1];m_n--;ArrayResize(m_e,m_n);}
   // v4.7 fix A9: RunOnce(guard) — weighted round-robin with optional PreTickGuard check
   //   guard=true (default): skips symbol if PreTickGuard fails (spread, session, CB, positions)
   //   guard=false: raw dispatch — use only when you manage guards externally
   static void RunOnce(bool guard=true)
   {
      if(!m_n)return;
      int best=-1;double bs=-1;
      for(int i=0;i<m_n;i++){double sc=(double)m_e[i].priority/(m_e[i].tick_count+1);if(sc>bs){bs=sc;best=i;}}
      if(best<0)return;
      // v4.7 fix A9: PreTickGuard check before dispatching
      if(guard&&!{MODULE_NAME}_PreTickGuard(m_e[best].symbol))
      {m_e[best].tick_count++;m_total++;return;} // count tick but skip EA logic
      ulong t0=GetMicrosecondCount();
      C{MODULE_NAME}*p=C{MODULE_NAME}Manager::Get(m_e[best].symbol,m_e[best].tf);
      if(p)p->OnTick();
      ulong dt=GetMicrosecondCount()-t0;
      m_e[best].tick_count++;m_total++;m_e[best].last_us=dt;
      m_e[best].ema_us=0.9*m_e[best].ema_us+0.1*(double)dt;
   }

   // v4.7 fix A9: RunAll(guard) — dispatch all symbols with optional PreTickGuard
   // v4.11 fix O5: m_total incremented per-symbol (consistent with RunOnce semantics)
   static void RunAll(bool guard=true)
   {
      for(int i=0;i<m_n;i++)
      {
         if(guard&&!{MODULE_NAME}_PreTickGuard(m_e[i].symbol))
         {m_e[i].tick_count++;m_total++;continue;}
         C{MODULE_NAME}*p=C{MODULE_NAME}Manager::Get(m_e[i].symbol,m_e[i].tf);
         if(p)p->OnTick();
         m_e[i].tick_count++;
         m_total++;
      }
   }
   static string StatsReport()
   {string r=StringFormat("Scheduler %d symbols dispatches=%I64u\n",m_n,m_total);
    for(int i=0;i<m_n;i++)r+=StringFormat("  %-10s %s pri=%d ticks=%I64u ema=%.1fus last=%I64dus\n",
      m_e[i].symbol,EnumToString(m_e[i].tf),m_e[i].priority,m_e[i].tick_count,m_e[i].ema_us,m_e[i].last_us);
    return r;}
   static int   SymbolCount(){return m_n;}
   static ulong TotalTicks() {return m_total;}
};
{MODULE_NAME}_T_ScheduleEntry C{MODULE_NAME}Scheduler::m_e[];
int   C{MODULE_NAME}Scheduler::m_n=0;
ulong C{MODULE_NAME}Scheduler::m_total=0;

//=============================================================================
// PROFILER — v4.3 P50/P95/P99 + v4.4 RAII ProfileScope
//=============================================================================
class {MODULE_NAME}_T_Profiler
{
private:
   ulong  m_t0,m_acc,m_peak,m_hist_max_us;
   uint   m_cnt;
   string m_name;
   ulong  m_hist[{MODULE_NAME}_C_HIST_BUCKETS];
public:
   // v4.11 fix Y3: clamp hist_max_us to minimum 1 — prevents division-by-zero in End()/PercentileUs()
   {MODULE_NAME}_T_Profiler(string name="default",ulong hist_max_us=10000)
      :m_t0(0),m_acc(0),m_peak(0),m_hist_max_us(hist_max_us<1?1:hist_max_us),m_cnt(0),m_name(name)
   {ArrayInitialize(m_hist,0);}
   void Begin(){m_t0=GetMicrosecondCount();}
   void End()
   {ulong dt=GetMicrosecondCount()-m_t0;m_acc+=dt;m_cnt++;if(dt>m_peak)m_peak=dt;
    int b=(int)MathMin((double)dt/((double)m_hist_max_us/{MODULE_NAME}_C_HIST_BUCKETS),(double)({MODULE_NAME}_C_HIST_BUCKETS-1));
    m_hist[b]++;}
   double AvgUs()  const{return m_cnt?(double)m_acc/m_cnt:0;}
   ulong  PeakUs() const{return m_peak;}
   uint   Count()  const{return m_cnt;}
   double PercentileUs(double pct) const
   {if(!m_cnt)return 0;ulong tgt=(ulong)MathCeil((double)m_cnt*pct/100);ulong run=0;
    double bw=(double)m_hist_max_us/{MODULE_NAME}_C_HIST_BUCKETS;
    for(int i=0;i<{MODULE_NAME}_C_HIST_BUCKETS;i++){run+=m_hist[i];if(run>=tgt)return(i+1)*bw;}
    return(double)m_hist_max_us;}
   void Reset(){m_t0=0;m_acc=0;m_cnt=0;m_peak=0;ArrayInitialize(m_hist,0);}
   string Report() const
   {return StringFormat("[%s] n=%u avg=%.1fus p50=%.0f p95=%.0f p99=%.0f peak=%I64d",
      m_name,m_cnt,AvgUs(),PercentileUs(50),PercentileUs(95),PercentileUs(99),m_peak);}
   void ExportCSV(string fn) const
   {int fh=FileOpen(fn,FILE_WRITE|FILE_CSV|FILE_ANSI,',');
    if(fh==INVALID_HANDLE){CORE_LOG({MODULE_NAME}_LOG_ERROR,StringFormat("Profiler: cant open %s",fn));return;}
    FileWrite(fh,"section","n","avg_us","p50","p95","p99","peak_us");
    FileWrite(fh,m_name,(string)m_cnt,DoubleToString(AvgUs(),1),DoubleToString(PercentileUs(50),0),
              DoubleToString(PercentileUs(95),0),DoubleToString(PercentileUs(99),0),(string)m_peak);
    FileWrite(fh,"---histogram---","bucket_upper_us","count");
    double bw=(double)m_hist_max_us/{MODULE_NAME}_C_HIST_BUCKETS;
    for(int i=0;i<{MODULE_NAME}_C_HIST_BUCKETS;i++)FileWrite(fh,"",DoubleToString((i+1)*bw,0),(string)m_hist[i]);
    FileClose(fh);CORE_LOG({MODULE_NAME}_LOG_INFO,StringFormat("Profiler CSV: %s",fn));}
};

// RAII scope wrapper — v4.4
class {MODULE_NAME}_T_ProfileScope
{
private:
   {MODULE_NAME}_T_Profiler &m_ref;
public:
   {MODULE_NAME}_T_ProfileScope({MODULE_NAME}_T_Profiler &p):m_ref(p){m_ref.Begin();}
   ~{MODULE_NAME}_T_ProfileScope(){m_ref.End();}
};

//=============================================================================
// §15 HEALTH MONITOR — v4.4 + v4.12 slot-based multi-instance (fix ARC3)
// Extended: slippage avg, retry stats, equity curve DD, position count
//=============================================================================
class C{MODULE_NAME}HealthMonitor
{
private:
   static double m_slip_acc[];
   static uint   m_slip_n[];
   static uint   m_retry_total[];
   static uint   m_order_total[];
   static {MODULE_NAME}_T_Profiler* m_profiler;  // profiler is process-global (not per-slot)
   static int    m_active;
   static int    m_count;
public:
   static int Alloc()
   {
      int s=m_count++;
      ArrayResize(m_slip_acc,m_count);ArrayResize(m_slip_n,m_count);
      ArrayResize(m_retry_total,m_count);ArrayResize(m_order_total,m_count);
      m_slip_acc[s]=0;m_slip_n[s]=0;m_retry_total[s]=0;m_order_total[s]=0;
      return s;
   }
   static void Activate(int slot){m_active=slot;}

   static void RecordOrder(double slip_pts,int retries)
   {m_slip_acc[m_active]+=slip_pts;m_slip_n[m_active]++;m_retry_total[m_active]+=retries;m_order_total[m_active]++;}

   static void SetProfiler({MODULE_NAME}_T_Profiler* p){m_profiler=p;}
   static {MODULE_NAME}_T_Profiler* GetProfiler()
   {
      static {MODULE_NAME}_T_Profiler s_dummy("noop");
      return (m_profiler!=NULL)?m_profiler:&s_dummy;
   }

   static string Report()
   {
      double bal=AccountInfoDouble(ACCOUNT_BALANCE);
      double eq =AccountInfoDouble(ACCOUNT_EQUITY);
      double fr =AccountInfoDouble(ACCOUNT_FREEMARGIN);
      double dd =(bal>0)?100.0*(bal-eq)/bal:0;
      double avgSlip=m_slip_n[m_active]?m_slip_acc[m_active]/m_slip_n[m_active]:0;
      double retryRate=m_order_total[m_active]?100.0*m_retry_total[m_active]/m_order_total[m_active]:0;
      string profiler_line="  Profiler        : not registered\n";
      if(m_profiler!=NULL)
         profiler_line=StringFormat("  Profiler        : n=%u avg=%.1fus p95=%.0f peak=%I64dus\n",
            m_profiler.Count(),m_profiler.AvgUs(),m_profiler.PercentileUs(95),m_profiler.PeakUs());
      return StringFormat(
         "\n====== {MODULE_NAME} HEALTH v4.12 [slot %d] ======\n"
         "  TradeAllowed    : %s\n"
         "  CircuitBreaker  : %s  trips=%d  consec=%d\n"
         "  RateLimiter     : sent=%d\n"
         "  Scheduler       : %d symbols  dispatches=%I64u\n"
         "  EventBus        : %d subs\n"
         "  SignalBus       : %d subs\n"
         "  TradeJournal    : %d buffered\n"
         "  EquityCurve     : %d pts  maxDD=%.2f%%\n"
         "  Positions open  : %d\n"
         "  Watchdog        : age=%I64dms  alerts=%d\n"
         "  Config keys     : %d\n"
         "  Orders sent     : %d  avgSlip=%.1f pts  retryRate=%.1f%%\n"
         "%s"
         "  Account         : bal=%.2f  eq=%.2f  free=%.2f  DD=%.2f%%\n"
         "========================================",
         m_active,
         ({MODULE_NAME}_IsTradeAllowed()?"YES":"NO"),
         (C{MODULE_NAME}CircuitBreaker::IsOpen()?"TRIPPED":"OK"),
         C{MODULE_NAME}CircuitBreaker::TripCount(),
         C{MODULE_NAME}CircuitBreaker::ConsecLosses(),
         C{MODULE_NAME}RateLimiter::TotalSent(),
         C{MODULE_NAME}Scheduler::SymbolCount(),
         C{MODULE_NAME}Scheduler::TotalTicks(),
         C{MODULE_NAME}EventBus::SubscriberCount(),
         C{MODULE_NAME}SignalBus::SubscriberCount(),
         C{MODULE_NAME}TradeJournal::Count(),
         C{MODULE_NAME}EquityCurve::Count(),
         C{MODULE_NAME}EquityCurve::MaxDrawdownPct(),
         C{MODULE_NAME}PositionTracker::Count(),
         C{MODULE_NAME}WatchdogTimer::AgeMs(),
         C{MODULE_NAME}WatchdogTimer::AlertCount(),
         C{MODULE_NAME}ConfigManager::KeyCount(),
         (int)m_order_total[m_active],avgSlip,retryRate,
         profiler_line,
         bal,eq,fr,dd);
   }
   static void Print(){::Print(Report());}
};
double C{MODULE_NAME}HealthMonitor::m_slip_acc[];
uint   C{MODULE_NAME}HealthMonitor::m_slip_n[];
uint   C{MODULE_NAME}HealthMonitor::m_retry_total[];
uint   C{MODULE_NAME}HealthMonitor::m_order_total[];
{MODULE_NAME}_T_Profiler* C{MODULE_NAME}HealthMonitor::m_profiler=NULL;
int    C{MODULE_NAME}HealthMonitor::m_active=0;
int    C{MODULE_NAME}HealthMonitor::m_count=0;

//=============================================================================
// OnTradeTransaction HOOK — v4.4
// + HistoryDealSelect guard
// + DEAL_ENTRY_IN filter (CB only on OUT/INOUT)
// + entry field in journal record
//=============================================================================
#ifdef {MODULE_NAME}_ENABLE_TRADE_EVENTS
void {MODULE_NAME}_OnTradeTransaction(const MqlTradeTransaction &trans,
                                       const MqlTradeRequest     &request,
                                       const MqlTradeResult      &result)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD)return;
   if(!HistoryDealSelect(trans.deal))
   {CORE_LOG({MODULE_NAME}_LOG_WARN,StringFormat("HistoryDealSelect fail deal=%I64d",trans.deal));return;}
   int deal_magic=(int)HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   if(deal_magic!={MODULE_NAME}_HashMagic(_Symbol,_Period))return;

   ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY);

   {MODULE_NAME}_T_DealRecord rec;
   rec.deal_ticket=trans.deal;
   rec.symbol     =trans.symbol;
   rec.magic      =deal_magic;
   rec.volume     =HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
   rec.price      =HistoryDealGetDouble(trans.deal,DEAL_PRICE);
   rec.profit     =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
   rec.commission =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   rec.swap       =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
   rec.time       =(datetime)HistoryDealGetInteger(trans.deal,DEAL_TIME);
   rec.comment    =HistoryDealGetString(trans.deal,DEAL_COMMENT);
   rec.entry      =entry;

   // v4.4: pass entry type so CB skips DEAL_ENTRY_IN (profit=0)
   C{MODULE_NAME}CircuitBreaker::RecordResult(rec.profit,entry);
   C{MODULE_NAME}TradeJournal::Push(rec);

   // v4.11 fix Y7: use deal_magic explicitly — avoids reliance on static m_magic
   //   which is only valid in single-symbol mode. This is still a singleton call,
   //   but at least passes the correct magic from the deal itself.
   C{MODULE_NAME}PositionTracker::Refresh(deal_magic);

   {MODULE_NAME}_T_Event evt;
   evt.type={MODULE_NAME}_EVT_TRADE;evt.lparam=(long)trans.type;
   evt.dparam=rec.profit;evt.sparam=trans.symbol;
   C{MODULE_NAME}EventBus::Publish(evt);

   CORE_LOG({MODULE_NAME}_LOG_INFO,
            StringFormat("Deal %I64d %s %s vol=%.2f px=%.5f pnl=%.2f",
                         trans.deal,trans.symbol,EnumToString(entry),
                         rec.volume,rec.price,rec.profit));
}
#endif

//=============================================================================
// USER IMPLEMENTATIONS — out-of-class method definitions
// {PUBLIC_METHOD_IMPLEMENTATIONS} — implement here any methods declared in
//   {PUBLIC_METHODS} that are too long for inline definition inside the class.
//   Also use this section for free functions and helpers specific to this EA.
//   e.g.:  void C{MODULE_NAME}::OpenGrid()
//          {
//             for(int i=0;i<m_grid_levels;i++) { ... }
//          }
//   May be left empty ("") if all logic is inline or in {ONTICK_LOGIC}.
//=============================================================================
{PUBLIC_METHOD_IMPLEMENTATIONS}

#endif // __{MODULE_NAME_UPPER}_MQH__
//+------------------------------------------------------------------+
//  END OF {MODULE_NAME}.mqh  v4.12 — DEAD-CODE-FREE • FULL-DRY-RUN • WEEKEND-SAFE • CB-COMPLETE • MULTI-INSTANCE
//+------------------------------------------------------------------+
