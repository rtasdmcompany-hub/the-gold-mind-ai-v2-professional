# PERFORMANCE_REVIEW.md

**Phase 8 · Sprint 6**  
**Nature:** Evaluation + optimization **recommendations only**  
**Rule:** No Core Trading / Strategy / Order / Risk / Recovery / AI Decision changes in this sprint

---

## 1. Review areas

### Memory Usage
| Observation | Recommendation |
|-------------|----------------|
| Enterprise modules accumulate state | Cap caches; prefer ring buffers for journals/samples |
| Diagnostics packs | Stream/zip; don’t hold full logs in RAM |
| Charts/widgets | Limit simultaneous heavy charts; dispose inactive |

### CPU Usage
| Observation | Recommendation |
|-------------|----------------|
| Timer fan-out across centers | Keep commercial work on timer; avoid tick-hot UI rebuilds |
| Dashboard remaps | Freeze commercial IA; reduce full-grid rebuild frequency |
| Logging | Async/buffer; no TRACE in prod |

### Initialization Time
| Observation | Recommendation |
|-------------|----------------|
| Many modules at Init | Lazy-init non-critical commercial panels after first paint |
| License validate | Async with offline lease; don’t block UI indefinitely |
| Show progress | Skeleton / splash — not frozen window |

### Dashboard Performance
| Observation | Recommendation |
|-------------|----------------|
| Last-wins widget publish | Stable taxonomy + differential updates |
| 14-slot churn | Commercial pin set (Sprint 4/5) |
| Text object spam | Batch UI updates per timer tick |

### Chart Rendering
| Observation | Recommendation |
|-------------|----------------|
| Heavy overlays | Toggle advanced layers; default minimal |
| Resize storms | Debounce redraw |

### Background Tasks
| Observation | Recommendation |
|-------------|----------------|
| Cloud / validate / reports | Queue with priority: Safety > License > Reports |
| Export PDF | Background job + notification on complete |

### Long Running Sessions
| Observation | Recommendation |
|-------------|----------------|
| Multi-day MT5 uptime | Rotate logs; sample Performance channel; leak checks in Diagnostics |
| Memory creep | Periodic health sample; warn on soft ceiling |
| Timer drift | Idempotent process handlers |

---

## 2. Performance budgets (guidance)

| Metric | Target guidance |
|--------|-----------------|
| Commercial shell first paint | < 3s on mid laptop after terminal ready |
| Timer commercial slice | Keep short; yield; no blocking network on UI thread when avoidable |
| Idle CPU (commercial extras) | Near-zero beyond scheduled samples |
| Log volume default | INFO without per-tick noise |

Exact budgets finalize in implementation sprint with profiling.

---

## 3. Reliability over speed

If a faster path risks instability (skipping backups, skipping integrity checks): **prefer the safer path**.

---

## 4. What not to optimize here

- Gold Mind calculation internals  
- Risk/recovery algorithms  
- Order execution path  

Those remain frozen; commercial shell and diagnostics are the optimization surface.

---

*End of PERFORMANCE_REVIEW.md*
