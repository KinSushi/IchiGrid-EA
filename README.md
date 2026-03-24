# IchiGridEA

Expert Advisor MetaTrader 5 — Ichimoku + Grid Trading avec IA adaptative.

## Progression

| Métrique | Valeur |
|----------|--------|
| Modules planifiés (Excel) | **0** |
| Fichiers attendus | **0** |
| Fichiers générés | **15** |
| Code (.mqh/.mq5) | **2** (3,103 lignes) |
| Data (.csv/.json/.dat) | **6** |
| Resources (.png/.log/.md) | **7** |
| Progression | **1500.0%** |
| Sections couvertes | **0** |
| Dernière MAJ | `2026-03-24T00:28:14Z` |

## Par niveau

| Niveau | Planifié | Code | Data | Resources | Total |
|--------|----------|------|------|-----------|-------|
| Core | ? | 0 | 0 | 0 | 0 |
| IchimokuSignals | ? | 0 | 0 | 0 | 0 |
| L1 | ? | 0 | 0 | 0 | 0 |
| L2 | ? | 0 | 0 | 0 | 0 |
| L3 | ? | 0 | 0 | 0 | 0 |


## Structure

```
IchiGrid-EA/
├── Plan/                        # .docx sources (spécifications)
├── Excel/                       # EA_Master + EA_Master_vLLM
├── Templates/                   # Templates MQL5 v4.12
├── Include/                     # Code MQL5 généré
│   ├── Core/                    #   188 modules fondamentaux
│   ├── IchimokuSignals/         #   44 filtres F01-F44
│   ├── L1/                      #   1,258 modules niveau 1
│   ├── L2/                      #   5,391 modules niveau 2
│   └── L3/                      #   6,459 modules niveau 3
├── Data/                        # Fichiers data générés
│   ├── Core/                    #   .csv, .json, .dat
│   ├── IchimokuSignals/
│   ├── L1/
│   ├── L2/
│   └── L3/
├── Resources/                   # Fichiers ressources
│   ├── Core/                    #   .png, .log, .md, .txt, .zip
│   ├── L1/
│   ├── L2/
│   └── L3/
├── Files/Presets/               # Presets MetaTrader 5
├── pipeline/
│   ├── scripts/                 # Outils pipeline
│   └── config/                  # Configuration
├── PROJECT.json                 # Stats auto-générées
├── HASHES.json                  # SHA-256 tous fichiers
└── CHANGELOG.md
```

## Fichiers attendus par extension

| Extension | Attendu | Rôle |
|-----------|---------|------|
| `.mqh` | 13,340 | Code MQL5 |
| `.csv` | 12,821 | Tables de données |
| `.json` | 415 | Configurations |
| `.png` | 37 | Visualisations |
| `.log` | 10 | Logs santé |
| `.md` | 10 | Documentation |
| `.zip` | 5 | Archives |
| `.dat` | 2 | Index binaires |
| `.txt` | 1 | Narratifs |
| **Total** | **26,641** | |

## Pipeline

```
[1.SYNC] → [2.LOAD] → [3.HASH] → [4.DECIDE] → [5.PARSE] → [6.MAP]
[7.GENERATE] → [8.COMPILE] → [9.VALIDATE] → [10.HASH_OUT] → [11.SNAPSHOT] → [12.PUBLISH]
```

| Script | Rôle |
|--------|------|
| `deploy.py` | Auto trace → README → git push → OVH sync |
| `ea_plan_builder.py` | Parse .docx → Excel master |
| `excel_hash_sync.py` | Sync SHA-256 repo ↔ Excel (2 couches: LLM + disque) |
| `vllm_generate.py` | Génération batch via LLM API |

## Infrastructure

| Service | URL |
|---------|-----|
| GitHub | []() |
| OVH miroir | []() |

## Déploiement

```bash
python pipeline/scripts/deploy.py              # Full auto
python pipeline/scripts/deploy.py --push --msg "description"
```

## Routage fichiers générés

Chaque module peut produire 1 à 3 fichiers. Le routage est automatique:
- `.mqh`, `.mq5` → `Include/<Level>/`
- `.csv`, `.json`, `.dat` → `Data/<Level>/`
- `.png`, `.log`, `.md`, `.txt`, `.zip` → `Resources/<Level>/`

Le `<Level>` est dérivé du champ `Path` de l'Excel (EA::Core::S2 → Core).

---
*Auto-généré par `deploy.py` — 2026-03-24T00:28:14Z*
