# Phase 7 — Developer Guide

## Extension rule

Never edit frozen platforms under:

`Include/TradeJournal` `StrategyLab` `OptimizationLab` `PortfolioAnalytics` `ReportingCenter` `ConfigurationCenter` `AIDecisionCenter` `MultiAccountCenter` `CommandCenter`

Add new folders and facades; bind observe-only via pointers; Process on timer only.

## Naming

Prefer unique `GM_*` prefixes and `CGmEnterprise*Engine` facades.

## Safety flags

Every result struct must keep `may_execute` / interrupt / remote flags **false**.
