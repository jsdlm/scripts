#!/usr/bin/env bash
# LinuxHarvest.sh
# Usage: ./LinuxHarvest.sh [-p /home/] [-o rapport.html]

SCAN_PATH="/home/"
OUTPUT_FILE="./InterestingFiles_$(date +%Y%m%d_%H%M%S).html"

while getopts "p:o:" opt; do
    case $opt in
        p) SCAN_PATH="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
    esac
done

_HE=""
html_encode() {
    _HE="$1"
    _HE="${_HE//&/&amp;}"
    _HE="${_HE//</&lt;}"
    _HE="${_HE//>/&gt;}"
    _HE="${_HE//\"/&quot;}"
}

NAME_PATTERNS=(
    "*password*" "*passwd*" "*credential*" "*key*"
    "*secret*" "*token*" "*apikey*" "*api_key*" "*private*"
    "*vpn*" "*ssh*" "*rdp*" "*ftp*" "*smtp*" "*database*"
)

EXTENSIONS=(
    ".xml" ".ini" ".config" ".conf" ".cfg" ".txt" ".bat"
    ".ps1" ".psm1" ".psd1" ".vbs" ".cmd" ".rdp" ".rdg" ".vnc"
    ".env" ".yaml" ".yml" ".json" ".toml" ".properties" ".settings"
    ".kdbx" ".kdb" ".pem" ".pfx" ".p12" ".ovpn" ".key"
    ".log" ".bak" ".old" ".backup" ".sql" ".db"
    ".doc" ".docx" ".xls" ".xlsx" ".ppt" ".pptx"
    ".odt" ".ods" ".odp" ".csv" ".mdb" ".accdb"
    ".sh" ".py" ".rb" ".php"
)

echo "[*] Scan en cours sur : $SCAN_PATH"

TMPFILE=$(mktemp)
COUNTER=0
FOUND=0

while IFS=$'\t' read -r filename filepath size_bytes mod_date; do
    COUNTER=$((COUNTER + 1))
    (( COUNTER % 1000 == 0 )) && printf "\r[*] %d fichiers analyses..." "$COUNTER" >&2

    name_lc="${filename,,}"

    ext=""
    if [[ "$filename" == *.* ]]; then
        ext=".${filename##*.}"
        ext="${ext,,}"
    fi

    matched_by=""

    for pattern in "${NAME_PATTERNS[@]}"; do
        if [[ "$name_lc" == $pattern ]]; then
            matched_by="Nom"
            break
        fi
    done

    if [[ -z "$matched_by" && -n "$ext" ]]; then
        for e in "${EXTENSIONS[@]}"; do
            if [[ "$ext" == "$e" ]]; then
                matched_by="Extension"
                break
            fi
        done
    fi

    if [[ -n "$matched_by" ]]; then
        size_bytes="${size_bytes:-0}"
        size_kb_int=$((size_bytes / 1024))
        size_kb_dec=$(( (size_bytes % 1024) * 100 / 1024 ))
        printf -v size_kb "%d.%02d" "$size_kb_int" "$size_kb_dec"

        html_encode "$filename"; enc_name="$_HE"
        html_encode "$filepath"; enc_path="$_HE"
        html_encode "$ext";      enc_ext="$_HE"

        printf "    <tr>\n      <td>%s</td>\n      <td class='path'>%s</td>\n      <td>%s</td>\n      <td>%s KB</td>\n      <td>%s</td>\n      <td>%s</td>\n    </tr>\n" \
            "$enc_name" "$enc_path" "$enc_ext" "$size_kb" "$mod_date" "$matched_by" >> "$TMPFILE"
        FOUND=$((FOUND + 1))
    fi
done < <(find "$SCAN_PATH" -type f -printf '%f\t%p\t%s\t%TY-%Tm-%Td %TH:%TM\n' 2>/dev/null)

printf "\r\033[K"
echo "[+] $FOUND fichiers trouves."

SCAN_DATE=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME_VAL=$(hostname)
html_encode "$SCAN_PATH"; PATH_ENC="$_HE"

{
cat << HTMLEOF
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Interesting Files - $HOSTNAME_VAL</title>
<style>
  body { font-family: Consolas, monospace; font-size: 13px; background: #f5f5f5; color: #222; margin: 0; padding: 20px; }
  h1 { font-size: 15px; margin-bottom: 6px; }
  .meta { color: #555; margin-bottom: 14px; font-size: 12px; }
  .filters { display: flex; flex-direction: column; gap: 8px; margin-bottom: 12px; }
  .filters-row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  input[type=text] { font-family: Consolas, monospace; font-size: 12px; padding: 5px 8px; border: 1px solid #bbb; background: #fff; width: 280px; }
  .filter-group { display: flex; flex-wrap: wrap; align-items: center; gap: 5px; background: #fff; border: 1px solid #ccc; padding: 4px 8px; }
  .filter-label { font-size: 11px; font-weight: bold; color: #444; margin-right: 2px; white-space: nowrap; }
  .filter-group button { font-family: Consolas, monospace; font-size: 11px; padding: 1px 6px; border: 1px solid #bbb; background: #eee; cursor: pointer; }
  .filter-group button:hover { background: #ddd; }
  .filter-group label { font-size: 12px; display: flex; align-items: center; gap: 3px; cursor: pointer; white-space: nowrap; }
  .filter-group input[type=checkbox] { margin: 0; cursor: pointer; }
  .count { font-size: 12px; color: #555; }
  #exclude-input { width: 180px; }
  .excl-tags { display: flex; flex-wrap: wrap; gap: 4px; }
  .excl-tag { display: flex; align-items: center; gap: 3px; background: #f5c6cb; color: #721c24; padding: 1px 6px; font-size: 11px; border-radius: 2px; }
  .excl-tag button { background: none; border: none; color: #721c24; cursor: pointer; font-size: 12px; padding: 0 1px; line-height: 1; }
  table { width: 100%; border-collapse: collapse; background: #fff; }
  thead th { background: #222; color: #fff; text-align: left; padding: 7px 10px; font-size: 12px; cursor: pointer; white-space: nowrap; }
  thead th:hover { background: #444; }
  tbody tr:nth-child(even) { background: #f0f0f0; }
  tbody tr:hover { background: #dde8f5; }
  td { padding: 5px 10px; border-bottom: 1px solid #ddd; vertical-align: top; }
  td.path { font-size: 11px; color: #555; word-break: break-all; max-width: 400px; }
  .badge { display: inline-block; padding: 1px 6px; font-size: 11px; border-radius: 2px; }
  .badge-name { background: #bee5eb; color: #0c5460; }
  .badge-ext  { background: #d4edda; color: #155724; }
  #no-results { display: none; padding: 20px; text-align: center; color: #888; }
</style>
</head>
<body>
<h1>Interesting Files Report</h1>
<div class="meta">
  Host : <b>$HOSTNAME_VAL</b> &nbsp;|&nbsp;
  Path : <b>$PATH_ENC</b> &nbsp;|&nbsp;
  Date : <b>$SCAN_DATE</b> &nbsp;|&nbsp;
  Total : <b>$FOUND fichiers</b>
</div>

<div class="filters">
  <div class="filters-row">
    <input type="text" id="search" placeholder="Filtrer nom, chemin, extension..." oninput="applyFilters()">
    <span class="count">Affichage : <span id="visible-count">$FOUND</span> / $FOUND</span>
  </div>
  <div class="filters-row">
    <div class="filter-group">
      <span class="filter-label">Match</span>
      <button onclick="setAll('match',true)">All</button>
      <button onclick="setAll('match',false)">None</button>
      <label><input type="checkbox" class="cb-match" value="Nom" checked onchange="applyFilters()"> Nom</label>
      <label><input type="checkbox" class="cb-match" value="Extension" checked onchange="applyFilters()"> Extension</label>
    </div>
    <div class="filter-group" id="group-ext">
      <span class="filter-label">Extension</span>
      <button onclick="setAll('ext',true)">All</button>
      <button onclick="setAll('ext',false)">None</button>
    </div>
    <div class="filter-group">
      <span class="filter-label">Exclure</span>
      <input type="text" id="exclude-input" placeholder="nom ou chemin..." onkeydown="if(event.key==='Enter')addExclusion()">
      <button onclick="addExclusion()">+</button>
      <div class="excl-tags" id="excl-tags"></div>
    </div>
  </div>
</div>

<table id="main-table">
  <thead>
    <tr>
      <th onclick="sortTable(0)">Nom</th>
      <th onclick="sortTable(1)">Chemin</th>
      <th onclick="sortTable(2)">Extension</th>
      <th onclick="sortTable(3)">Taille</th>
      <th onclick="sortTable(4)">Modifie</th>
      <th onclick="sortTable(5)">Match</th>
    </tr>
  </thead>
  <tbody id="table-body">
HTMLEOF
cat "$TMPFILE"
cat << 'HTMLEOF_END'
  </tbody>
</table>
<div id="no-results">Aucun resultat.</div>

<script>
  const tbody = document.getElementById('table-body');
  const rows  = Array.from(tbody.querySelectorAll('tr'));

  // badges
  rows.forEach(r => {
    const m = r.cells[5].textContent.trim();
    const cls = m === 'Nom' ? 'badge-name' : 'badge-ext';
    r.cells[5].innerHTML = '<span class="badge ' + cls + '">' + m + '</span>';
  });

  // extension checkboxes
  const exts = [...new Set(rows.map(r => r.cells[2].textContent.trim()).filter(Boolean))].sort();
  const grpExt = document.getElementById('group-ext');
  exts.forEach(e => {
    const lbl = document.createElement('label');
    const cb  = document.createElement('input');
    cb.type = 'checkbox'; cb.className = 'cb-ext'; cb.value = e; cb.checked = true;
    cb.addEventListener('change', applyFilters);
    lbl.appendChild(cb);
    lbl.appendChild(document.createTextNode(' ' + e));
    grpExt.appendChild(lbl);
  });

  // exclusions
  let exclusions = ['linuxharvest.sh', '.cache', '.thumbnail'];
  function addExclusion() {
    const inp = document.getElementById('exclude-input');
    const val = inp.value.trim().toLowerCase();
    if (!val || exclusions.includes(val)) { inp.value = ''; return; }
    exclusions.push(val);
    inp.value = '';
    renderExclusions();
    applyFilters();
  }
  function removeExclusion(i) {
    exclusions.splice(i, 1);
    renderExclusions();
    applyFilters();
  }
  function renderExclusions() {
    const container = document.getElementById('excl-tags');
    container.innerHTML = '';
    exclusions.forEach((v, i) => {
      const tag = document.createElement('span');
      tag.className = 'excl-tag';
      tag.innerHTML = v + '<button onclick="removeExclusion(' + i + ')" title="Supprimer">&times;</button>';
      container.appendChild(tag);
    });
  }

  renderExclusions();
  applyFilters();

  function checkedValues(cls) {
    return new Set([...document.querySelectorAll('.' + cls + ':checked')].map(c => c.value));
  }

  function setAll(group, state) {
    document.querySelectorAll('.cb-' + group).forEach(c => c.checked = state);
    applyFilters();
  }

  function applyFilters() {
    const q       = document.getElementById('search').value.toLowerCase();
    const matches = checkedValues('cb-match');
    const extSet  = checkedValues('cb-ext');
    let vis = 0;
    rows.forEach(r => {
      const name = r.cells[0].textContent.toLowerCase();
      const path = r.cells[1].textContent.toLowerCase();
      const ext  = r.cells[2].textContent.trim();
      const show =
        (!q || name.includes(q) || path.includes(q) || ext.toLowerCase().includes(q))
        && matches.has(r.cells[5].textContent.trim())
        && extSet.has(ext)
        && !exclusions.some(x => name.includes(x) || path.includes(x));
      r.style.display = show ? '' : 'none';
      if (show) vis++;
    });
    document.getElementById('visible-count').textContent = vis;
    document.getElementById('no-results').style.display = vis === 0 ? 'block' : 'none';
  }

  let sortDir = {};
  function sortTable(col) {
    sortDir[col] = !sortDir[col];
    rows.slice().sort((a, b) => {
      const av = a.cells[col].textContent.trim();
      const bv = b.cells[col].textContent.trim();
      const an = parseFloat(av), bn = parseFloat(bv);
      if (!isNaN(an) && !isNaN(bn)) return sortDir[col] ? an - bn : bn - an;
      return sortDir[col] ? av.localeCompare(bv) : bv.localeCompare(av);
    }).forEach(r => tbody.appendChild(r));
  }
</script>
</body>
</html>
HTMLEOF_END
} > "$OUTPUT_FILE"

rm -f "$TMPFILE"
echo "[+] Rapport genere : $OUTPUT_FILE"
