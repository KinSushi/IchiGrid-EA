# IchiGridEA — Changelog

## v7.0 (2026-03-23) — Clean Slate

### Restructuration complète
- Nettoyage total du repo
- Structure canonique: Plan/ Excel/ Templates/ Include/ pipeline/
- Suppression du code MQL5 non vérifié (sera régénéré proprement)

### Pipeline
- `deploy.py` — Auto-deploy: trace → README → git push → OVH sync
- `excel_hash_sync.py` v2 — Extraction @code_hash LLM + SHA-256 disque
- `ea_plan_builder.py` — Parse .docx → Excel master
- `vllm_generate.py` — Génération batch via LLM API

### CI/CD
- GitHub Actions: trace + hash verify + OVH sync
- Auto-génération README.md avec stats

### Source de vérité
- `EA_Master.xlsx` (13 340 modules, 11 cols)
- `EA_Master_vLLM.xlsx` (13 340 modules, 18 cols workflow)
- Templates v4.12 (.mq5 + .mqh)
- 2 plans .docx (filtres Ichimoku + sections 1-760)

---

## Versions précédentes

Historique pré-nettoyage archivé. Les versions 1.0-6.0 contenaient du code
généré non compilé. Le repo repart sur une base propre et traçable.
