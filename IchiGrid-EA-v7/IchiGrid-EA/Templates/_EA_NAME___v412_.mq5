//+------------------------------------------------------------------+
//|        {MODULE_NAME}.mq5 — v4.12 EA HARNESS                     |
//|                 Copyright 2026, SOVRALYS LLC                     |
//| Companion to {MODULE_NAME}.mqh v4.12 Institutional Core Engine   |
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
| @depends      : {MODULE_NAME}.mqh v4.12
| @description  : {DESCRIPTION}
| @audit_tag    : v4.12 — EA harness matching .mqh v4.12 contract
</gen:header>
===============================================================================

COMPILE-TIME CONTRACT — .mq5 HARNESS
=====================================
This file is the thin EA shell that MetaTrader loads. ALL logic lives in the
.mqh template. This file:
  1. Sets feature flags (#define) BEFORE #include
  2. Includes the .mqh engine
  3. Wires the 6 MT5 event handlers to engine wrappers
  4. Optionally adds EA-level globals, panel code, or multi-symbol setup

┌─ MANDATORY SUBSTITUTIONS ────────────────────────────────────────────────┐
│ {MODULE_NAME}       → Same as in .mqh (e.g. IchiGrid)                    │
│ {MODULE_NAME_UPPER} → Uppercase (e.g. ICHIGRID)                          │
│ {VERSION}           → Semver (e.g. 1.0.0)                                │
│ All traceability tokens: same as .mqh                                    │
└──────────────────────────────────────────────────────────────────────────┘

┌─ OPTIONAL PLACEHOLDERS ──────────────────────────────────────────────────┐
│ {EA_FEATURE_FLAGS}    → Extra #define before include (e.g. DRY_RUN)      │
│ {EA_INCLUDES}         → Extra #include after engine (e.g. panels, libs)  │
│ {EA_GLOBALS}          → Global variables for EA-level state              │
│ {EA_ONINIT_LOGIC}     → Code in OnInit() AFTER engine init succeeds      │
│ {EA_ONDEINIT_LOGIC}   → Code in OnDeinit() BEFORE engine deinit         │
│ {EA_ONTICK_PRE}       → Code in OnTick() BEFORE engine OnTick           │
│ {EA_ONTICK_POST}      → Code in OnTick() AFTER engine OnTick            │
│ {EA_ONTIMER_LOGIC}    → Code in OnTimer() AFTER engine OnTimer          │
│ {EA_ONCHARTEVENT}     → Code in OnChartEvent() AFTER engine dispatch    │
│ All may be left as empty string "".                                      │
└──────────────────────────────────────────────────────────────────────────┘

┌─ MULTI-SYMBOL SETUP ─────────────────────────────────────────────────────┐
│ For single-symbol EAs:                                                    │
│   Use OnTick{MODULE_NAME}() — routes to _Symbol/_Period instance          │
│                                                                           │
│ For multi-symbol EAs:                                                     │
│   1. In {EA_ONINIT_LOGIC}, register symbols:                              │
│        C{MODULE_NAME}Scheduler::Add("EURUSD",PERIOD_H1,8);               │
│        C{MODULE_NAME}Scheduler::Add("XAUUSD",PERIOD_M15,5);              │
│   2. Replace OnTick{MODULE_NAME}() with:                                  │
│        C{MODULE_NAME}Scheduler::RunAll();                                 │
│   3. Use DeinitAll{MODULE_NAME}() instead of OnDeinit{MODULE_NAME}().     │
│   Note: CB/WT/HM are per-instance (v4.12). Other subsystems are shared.  │
└──────────────────────────────────────────────────────────────────────────┘
*/

#property strict
#property copyright "Copyright 2026, SOVRALYS LLC"
#property link      ""
#property version   "{VERSION}"
#property description "{MODULE_NAME} v{VERSION}"
#property description "Powered by Institutional Core Engine v4.12"

//=============================================================================
// §0 FEATURE FLAGS — set BEFORE #include
// These override defaults in the .mqh. Uncomment/modify as needed.
//=============================================================================

// --- Core behavior ---
// #define {MODULE_NAME}_ENABLE_TRADING     1     // master on/off (default: 1)
// #define {MODULE_NAME}_ENABLE_LOGS        1     // logging (default: 1)

// --- Testing ---
// #define {MODULE_NAME}_UNIT_TESTING       1     // run UTs on Init() (default: 0)
// #define {MODULE_NAME}_DRY_RUN            1     // log orders, don't send (default: 0)
// #define {MODULE_NAME}_MOCK_BROKER        1     // offline MockBroker (default: 0)
// #define {MODULE_NAME}_PROFILE_MODE       1     // OnTick profiling (default: 0)

// --- Trade events ---
// ENABLE_TRADE_EVENTS is ON by default since v4.11 (required for CB consec_losses).
// Uncomment below ONLY if you want to disable it:
// #define {MODULE_NAME}_DISABLE_TRADE_EVENTS

// --- Init params ---
// If your EA has NO extra Init() parameters, uncomment this:
#define {MODULE_NAME}_INIT_PARAMS_EMPTY
// If your EA HAS extra params, comment the line above and set in .mqh:
//   {INIT_PARAMS}        = ,int bars,bool dbg
//   {INIT_PARAMS_GLOBAL} = ,int bars,bool dbg
//   {INIT_ARGS}          = bars,dbg

// {EA_FEATURE_FLAGS} — additional #define directives for this EA
//   e.g.:  #define MY_CUSTOM_FLAG 1
{EA_FEATURE_FLAGS}

//=============================================================================
// §1 ENGINE INCLUDE
// The .mqh must be in the same directory or MQL5/Include/.
// All 13 injection points in the .mqh must be substituted (even to "").
//=============================================================================
#include "{MODULE_NAME}.mqh"

// {EA_INCLUDES} — additional includes AFTER engine (panels, indicator libs, etc.)
//   e.g.:  #include <Controls\Dialog.mqh>
//          #include "MyPanel.mqh"
{EA_INCLUDES}

//=============================================================================
// §2 EA-LEVEL GLOBALS
// State that lives outside the engine — panel handles, indicator handles, etc.
//=============================================================================
// {EA_GLOBALS} — global variables for EA-level state
//   e.g.:  int g_atr_handle = INVALID_HANDLE;
//          bool g_panel_visible = false;
{EA_GLOBALS}

//=============================================================================
// §3 OnInit — EA initialization
//=============================================================================
int OnInit()
{
   //--- Timer: REQUIRED for WatchdogTimer + CircuitBreaker daily reset.
   //    60s is the recommended interval. Set to 0 to disable (not recommended).
   EventSetTimer(60);

   //--- Initialize the engine instance for _Symbol / _Period
#ifndef {MODULE_NAME}_INIT_PARAMS_EMPTY
   if(!Init{MODULE_NAME}({INIT_ARGS}))
#else
   if(!Init{MODULE_NAME}())
#endif
   {
      Print("[FATAL] {MODULE_NAME} Init failed — EA will not trade");
      return INIT_FAILED;
   }

   // {EA_ONINIT_LOGIC} — EA-level init AFTER engine init succeeds
   //   e.g.:  g_atr_handle = iATR(_Symbol, _Period, 14);
   //          if(g_atr_handle == INVALID_HANDLE) return INIT_FAILED;
   //
   //   Multi-symbol setup:
   //          C{MODULE_NAME}Scheduler::Add("EURUSD", PERIOD_H1, 8);
   //          C{MODULE_NAME}Scheduler::Add("XAUUSD", PERIOD_M15, 5);
   {EA_ONINIT_LOGIC}

   Print(StringFormat("[%s] Init OK — %s", _Symbol, {MODULE_NAME}_GetVersion()));
   return INIT_SUCCEEDED;
}

//=============================================================================
// §4 OnDeinit — EA shutdown
//=============================================================================
void OnDeinit(const int reason)
{
   // {EA_ONDEINIT_LOGIC} — EA-level cleanup BEFORE engine deinit
   //   e.g.:  if(g_atr_handle != INVALID_HANDLE) IndicatorRelease(g_atr_handle);
   {EA_ONDEINIT_LOGIC}

   //--- Engine deinit: flushes TradeJournal, EquityCurve, logs reason code.
   //    For multi-symbol: replace with DeinitAll{MODULE_NAME}();
   OnDeinit{MODULE_NAME}(reason);

   EventKillTimer();
}

//=============================================================================
// §5 OnTick — per-tick execution
//=============================================================================
void OnTick()
{
   // {EA_ONTICK_PRE} — code BEFORE engine OnTick (e.g. indicator refresh)
   //   e.g.:  double atr_buf[];
   //          if(CopyBuffer(g_atr_handle, 0, 0, 1, atr_buf) < 1) return;
   {EA_ONTICK_PRE}

   //--- Single-symbol: delegates to C{MODULE_NAME}::OnTick() for _Symbol/_Period.
   //    Includes: slot activation, watchdog kick, cache refresh, position tracker,
   //    config reload, equity sampling, PreTickGuard, then {ONTICK_LOGIC}.
   //
   //    Multi-symbol: replace with C{MODULE_NAME}Scheduler::RunAll();
   OnTick{MODULE_NAME}();

   // {EA_ONTICK_POST} — code AFTER engine OnTick (e.g. panel update)
   //   e.g.:  UpdatePanel();
   {EA_ONTICK_POST}
}

//=============================================================================
// §6 OnTimer — periodic tasks (WatchdogTimer + CB daily reset)
//=============================================================================
void OnTimer()
{
   //--- Engine: watchdog stall check + CircuitBreaker midnight reset.
   OnTimer{MODULE_NAME}();

   // {EA_ONTIMER_LOGIC} — EA-level periodic tasks AFTER engine OnTimer
   //   e.g.:  C{MODULE_NAME}HealthMonitor::Print();  // periodic health dump
   //          CheckLicenseExpiry();
   {EA_ONTIMER_LOGIC}
}

//=============================================================================
// §7 OnChartEvent — chart interaction (buttons, keyboard, custom events)
//=============================================================================
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- Engine: routes to EventBus so subscribed modules can react.
   OnChartEvent{MODULE_NAME}(id, lparam, dparam, sparam);

   // {EA_ONCHARTEVENT} — EA-level chart event handling AFTER engine dispatch
   //   e.g.:  if(id == CHARTEVENT_OBJECT_CLICK && sparam == "btnClose")
   //             ForceCloseAll();
   {EA_ONCHARTEVENT}
}

//=============================================================================
// §8 OnTradeTransaction — deal/order execution feedback
// Active by default since v4.11 (ENABLE_TRADE_EVENTS).
// Powers: CB consec_losses, daily DD tracking, TradeJournal recording,
//         PositionTracker invalidation, EventBus EVT_TRADE publish.
//=============================================================================
#ifdef {MODULE_NAME}_ENABLE_TRADE_EVENTS
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest     &request,
                        const MqlTradeResult      &result)
{
   {MODULE_NAME}_OnTradeTransaction(trans, request, result);
}
#endif

//+------------------------------------------------------------------+
//  END OF {MODULE_NAME}.mq5 v4.12 — EA HARNESS
//+------------------------------------------------------------------+
