#!/usr/bin/env python3
"""
deploy.py v2 — Auto-deploy IchiGridEA (multi-extension, multi-dossier)
=======================================================================

Gère la structure complète:
  Include/{Core,IchimokuSignals,L1,L2,L3}/  → .mqh, .mq5
  Data/{Core,IchimokuSignals,L1,L2,L3}/     → .csv, .json, .dat
  Resources/{Core,L1,L2,L3}/                → .png, .log, .md, .txt, .zip

Usage:
  python deploy.py                    # Full: trace → readme → git → ovh
  python deploy.py --trace            # PROJECT.json + HASHES.json
  python deploy.py --readme           # README.md
  python deploy.py --push             # git add + commit + push
  python deploy.py --ovh              # OVH sync
  python deploy.py --push --msg "x"   # Custom commit message
  python deploy.py --dry-run

v2.0.0 | 2026-03-23
"""
import argparse, hashlib, json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

# ── File categories ──
CODE_EXT    = {'.mqh', '.mq5'}
DATA_EXT    = {'.csv', '.json', '.dat'}
RES_EXT     = {'.png', '.log', '.md', '.txt', '.zip'}
PIPE_EXT    = {'.py', '.yml', '.yaml'}
DOC_EXT     = {'.docx', '.xlsx'}
ALL_TRACKED = CODE_EXT | DATA_EXT | RES_EXT | PIPE_EXT | DOC_EXT | {'.set', '.editorconfig'}
IGNORED     = {'.git', '__pycache__', '.venv', 'node_modules', '.checkpoints'}
LEVELS      = {'Core', 'IchimokuSignals', 'L1', 'L2', 'L3'}

def sha256_file(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for c in iter(lambda: f.read(65536), b''): h.update(c)
    return h.hexdigest()

def count_lines(p):
    try:
        with open(p, 'r', encoding='utf-8', errors='ignore') as f: return sum(1 for _ in f)
    except: return 0

def run(cmd, cwd=None, timeout=120):
    try:
        r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return r.returncode == 0, (r.stdout + r.stderr).strip()
    except Exception as e: return False, str(e)

def find_base():
    for p in [Path('.'), Path(__file__).parent.parent.parent]:
        if (p / 'PROJECT.json').exists() or (p / 'pipeline').is_dir():
            return p.resolve()
    return Path('.').resolve()

def load_config(base):
    cfg_path = base / 'pipeline' / 'config' / 'pipeline.json'
    if cfg_path.exists():
        with open(cfg_path) as f: return json.load(f)
    return {}

def classify_file(rel_path, ext):
    """Retourne (category, level) pour un fichier."""
    parts = rel_path.replace('\\', '/').split('/')
    level = None
    for p in parts:
        if p in LEVELS:
            level = p
            break

    if ext in CODE_EXT: return 'code', level
    if ext in DATA_EXT: return 'data', level
    if ext in RES_EXT:  return 'resource', level
    if ext in PIPE_EXT: return 'pipeline', None
    if ext in DOC_EXT:  return 'source', None
    return 'other', None

# ══════════════════════════════════════════════════════════════
# TRACE
# ══════════════════════════════════════════════════════════════
def update_trace(base, cfg):
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    files_data = {}
    total_lines = 0
    sections = set()
    by_ext = {}
    by_dir = {}
    by_level = {lv: {'code': 0, 'data': 0, 'resource': 0, 'lines': 0} for lv in LEVELS}
    by_category = {'code': 0, 'data': 0, 'resource': 0, 'pipeline': 0, 'source': 0, 'other': 0}

    for root, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if d not in IGNORED]
        for fname in files:
            if fname == '.gitkeep': continue
            ext = os.path.splitext(fname)[1].lower()
            if ext not in ALL_TRACKED and fname not in ('.gitignore', 'LICENSE'): continue
            ap = os.path.join(root, fname)
            rp = os.path.relpath(ap, base).replace('\\', '/')
            if rp.startswith('.git/'): continue

            h = sha256_file(ap)
            ln = count_lines(ap)
            sz = os.path.getsize(ap)
            total_lines += ln

            cat, level = classify_file(rp, ext)
            by_ext[ext] = by_ext.get(ext, 0) + 1
            by_category[cat] = by_category.get(cat, 0) + 1

            d = rp.split('/')[0]
            by_dir[d] = by_dir.get(d, 0) + 1

            if level and level in by_level:
                by_level[level][cat] = by_level[level].get(cat, 0) + 1
                if cat == 'code':
                    by_level[level]['lines'] += ln

            rec = {'sha256': h, 'lines': ln, 'size': sz, 'category': cat}
            if level: rec['level'] = level

            # Extract section from gen:header
            if ext in CODE_EXT:
                try:
                    with open(ap, 'r', encoding='utf-8', errors='ignore') as f:
                        head = ''.join(f.readline() for _ in range(50))
                    m = re.search(r'@section\s*:\s*(\S+)', head)
                    if m and not m.group(1).startswith('{'):
                        sections.add(m.group(1))
                        rec['section'] = m.group(1)
                    m2 = re.search(r'@code_hash\s*:\s*([a-fA-F0-9]+)', head)
                    if m2: rec['gen_code_hash'] = m2.group(1)
                    m3 = re.search(r'@model\s*:\s*(\S+)', head)
                    if m3: rec['gen_model'] = m3.group(1)
                except: pass

            files_data[rp] = rec

    # Excel module count
    excel_modules = 0
    for ep in ['Excel/EA_Master_vLLM.xlsx', 'Excel/EA_Master.xlsx']:
        fp = base / ep
        if fp.exists():
            try:
                import openpyxl
                wb = openpyxl.load_workbook(fp, data_only=True, read_only=True)
                ws = wb['PLAN']
                excel_modules = ws.max_row - 2
                wb.close()
            except: pass
            break

    # Stats
    code_files = by_category['code']
    data_files = by_category['data']
    res_files = by_category['resource']
    generated_files = code_files + data_files + res_files
    code_lines = sum(v['lines'] for f, v in files_data.items()
                     if os.path.splitext(f)[1] in CODE_EXT)
    # Expected total files = sum of all extensions in plan
    expected_total = sum(cfg.get('structure', {}).get('stats_expected', {}).get('by_extension', {}).values())
    if not expected_total: expected_total = excel_modules * 2  # fallback

    version = cfg.get('version', '7.0')

    proj = {
        '_updated': now,
        'project': 'IchiGridEA',
        'version': version,
        'stats': {
            'total_files': len(files_data),
            'total_lines': total_lines,
            'code_files': code_files,
            'code_lines': code_lines,
            'data_files': data_files,
            'resource_files': res_files,
            'generated_files': generated_files,
            'excel_modules': excel_modules,
            'expected_files': expected_total,
            'progress_pct': round(generated_files / max(expected_total, 1) * 100, 2),
            'sections_covered': len(sections),
        },
        'by_extension': dict(sorted(by_ext.items(), key=lambda x: -x[1])),
        'by_category': by_category,
        'by_level': {lv: dict(v) for lv, v in by_level.items()},
        'by_directory': dict(sorted(by_dir.items(), key=lambda x: -x[1])),
        'infrastructure': {
            'github': cfg.get('github', {}).get('repo', ''),
            'ovh_http': cfg.get('ovh', {}).get('http', ''),
        },
        'sections': sorted(list(sections)),
    }

    hashes = {
        '_generated': now, '_version': version,
        '_files': len(files_data), '_lines': total_lines,
        'files': files_data,
    }

    with open(base / 'PROJECT.json', 'w', encoding='utf-8') as f:
        json.dump(proj, f, indent=2, ensure_ascii=False)
    with open(base / 'HASHES.json', 'w', encoding='utf-8') as f:
        json.dump(hashes, f, indent=2, ensure_ascii=False)

    return proj['stats'], proj['by_level']

# ══════════════════════════════════════════════════════════════
# README
# ══════════════════════════════════════════════════════════════
def generate_readme(base, cfg):
    proj_path = base / 'PROJECT.json'
    if not proj_path.exists(): return
    with open(proj_path) as f: proj = json.load(f)
    s = proj.get('stats', {})
    bl = proj.get('by_level', {})

    github_url = cfg.get('github', {}).get('repo', '').replace('.git', '')
    ovh_url = cfg.get('ovh', {}).get('http', '')
    expected = cfg.get('structure', {}).get('stats_expected', {})

    # Level table
    level_rows = ""
    for lv in ['Core', 'IchimokuSignals', 'L1', 'L2', 'L3']:
        d = bl.get(lv, {})
        exp = expected.get('by_level', {}).get(lv, '?')
        code = d.get('code', 0)
        data = d.get('data', 0)
        res = d.get('resource', 0)
        total = code + data + res
        level_rows += f"| {lv} | {exp} | {code} | {data} | {res} | {total} |\n"

    readme = f"""# IchiGridEA

Expert Advisor MetaTrader 5 — Ichimoku + Grid Trading avec IA adaptative.

## Progression

| Métrique | Valeur |
|----------|--------|
| Modules planifiés (Excel) | **{s.get('excel_modules', 0):,}** |
| Fichiers attendus | **{s.get('expected_files', 0):,}** |
| Fichiers générés | **{s.get('generated_files', 0)}** |
| Code (.mqh/.mq5) | **{s.get('code_files', 0)}** ({s.get('code_lines', 0):,} lignes) |
| Data (.csv/.json/.dat) | **{s.get('data_files', 0)}** |
| Resources (.png/.log/.md) | **{s.get('resource_files', 0)}** |
| Progression | **{s.get('progress_pct', 0)}%** |
| Sections couvertes | **{s.get('sections_covered', 0)}** |
| Dernière MAJ | `{proj.get('_updated', 'N/A')}` |

## Par niveau

| Niveau | Planifié | Code | Data | Resources | Total |
|--------|----------|------|------|-----------|-------|
{level_rows}

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
| GitHub | [{github_url}]({github_url}) |
| OVH miroir | [{ovh_url}]({ovh_url}) |

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
*Auto-généré par `deploy.py` — {proj.get('_updated', '')}*
"""
    with open(base / 'README.md', 'w', encoding='utf-8') as f:
        f.write(readme)

# ══════════════════════════════════════════════════════════════
# GIT + OVH (inchangé)
# ══════════════════════════════════════════════════════════════
def git_push(base, cfg, msg=None, dry=False):
    gh = cfg.get('github', {})
    cmds = [
        f'git config user.email "{gh.get("email", "dibaccointernacional@gmail.com")}"',
        f'git config user.name "{gh.get("user", "KinSushi")}"',
        'git add -A',
    ]
    if not msg:
        try:
            with open(base / 'PROJECT.json') as f: p = json.load(f)
            s = p.get('stats', {})
            msg = (f"deploy: {s.get('generated_files',0)}/{s.get('expected_files',0)} files "
                   f"({s.get('progress_pct',0)}%) | "
                   f"code:{s.get('code_files',0)} data:{s.get('data_files',0)} res:{s.get('resource_files',0)}")
        except:
            msg = f"deploy: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')}"
    cmds.append(f'git commit -m "{msg}"')
    cmds.append(f'git push origin {gh.get("branch", "main")}')

    for cmd in cmds:
        if dry: print(f"  [DRY] {cmd}")
        else:
            ok, out = run(cmd, cwd=str(base))
            if not ok and 'nothing to commit' not in out and 'dry' not in out:
                print(f"  ⚠ {cmd[:40]}... → {out[:80]}")

def sync_ovh(base, cfg, dry=False):
    ovh = cfg.get('ovh', {})
    key = os.path.expanduser(ovh.get('key', '~/.ssh/ovh_serveur'))
    host = ovh.get('host', '92.222.226.50')
    user = ovh.get('user', 'ubuntu')
    path = ovh.get('path', '/opt/ichigrid-mirror')
    branch = cfg.get('github', {}).get('branch', 'main')
    repo = cfg.get('github', {}).get('repo', '')
    remote = f"""if [ -d \"{path}/.git\" ]; then cd {path} && git pull origin {branch}; else git clone {repo} {path}; fi"""
    cmd = f'ssh -i {key} -o StrictHostKeyChecking=no -o ConnectTimeout=10 {user}@{host} "{remote}"'
    if dry: print(f"  [DRY] ssh → {host}"); return True, 'dry'
    return run(cmd, timeout=60)

# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════
def main():
    p = argparse.ArgumentParser(description='Auto-deploy IchiGridEA v2')
    p.add_argument('--trace', action='store_true')
    p.add_argument('--readme', action='store_true')
    p.add_argument('--push', action='store_true')
    p.add_argument('--ovh', action='store_true')
    p.add_argument('--msg', default=None)
    p.add_argument('--dry-run', action='store_true')
    a = p.parse_args()
    do_all = not (a.trace or a.readme or a.push or a.ovh)

    base = find_base()
    cfg = load_config(base)
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

    print(f"{'='*60}\n  ICHIGRIDEA DEPLOY v2 — {now}\n  Base: {base}\n{'='*60}\n")

    if do_all or a.trace:
        print("[1/4] Traçabilité...")
        stats, by_level = update_trace(base, cfg)
        print(f"  {stats['total_files']} fichiers | code:{stats['code_files']} data:{stats['data_files']} res:{stats['resource_files']}")
        print(f"  {stats['code_lines']:,} lignes MQL5 | {stats['progress_pct']}% | {stats['sections_covered']} sections")
        for lv in ['Core', 'IchimokuSignals', 'L1', 'L2', 'L3']:
            d = by_level.get(lv, {})
            t = d.get('code',0)+d.get('data',0)+d.get('resource',0)
            if t: print(f"    {lv}: code={d.get('code',0)} data={d.get('data',0)} res={d.get('resource',0)}")
        print()

    if do_all or a.readme:
        print("[2/4] README.md...")
        generate_readme(base, cfg)
        print("  Généré\n")

    if do_all or a.push:
        print("[3/4] Git push...")
        git_push(base, cfg, a.msg, a.dry_run)
        print()

    if do_all or a.ovh:
        print("[4/4] OVH sync...")
        ok, out = sync_ovh(base, cfg, a.dry_run)
        print(f"  {'OK' if ok else '⚠ ' + str(out)[:80]}\n")

    print(f"{'='*60}\n  TERMINÉ\n{'='*60}")

if __name__ == '__main__':
    sys.exit(main())
