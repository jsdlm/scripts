# Find-InterestingFiles.ps1
# Usage: .\Find-InterestingFiles.ps1 [-Path "C:\"] [-OutputFile "rapport.html"]

param(
    [string]$Path = "C:\",
    [string]$OutputFile = ".\InterestingFiles_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
)

function HtmlEncode($s) {
    $s = $s -replace '&', '&amp;'
    $s = $s -replace '<', '&lt;'
    $s = $s -replace '>', '&gt;'
    $s = $s -replace '"', '&quot;'
    return $s
}

$InterestingNames = @(
    "*password*", "*passwd*", "*credential*", "*key*",
    "*secret*", "*token*", "*apikey*", "*api_key*", "*private*",
    "*vpn*", "*ssh*", "*rdp*", "*ftp*", "*smtp*", "*database*",
)

$InterestingExtensions = @(
    ".xml", ".ini", ".config", ".conf", ".cfg", ".txt", ".bat",
    ".ps1", ".psm1", ".psd1", ".vbs", ".cmd", ".rdp", ".rdg", ".vnc",
    ".env", ".yaml", ".yml", ".json", ".toml", ".properties", ".settings",
    ".kdbx", ".kdb", ".pem", ".pfx", ".p12", ".ovpn", ".key",
    ".log", ".bak", ".old", ".backup", ".sql", ".db",
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
    ".odt", ".ods", ".odp", ".csv", ".mdb", ".accdb"
)

Write-Host "[*] Scan en cours sur : $Path" -ForegroundColor Cyan

$Results = [System.Collections.Generic.List[object]]::new()

$AllFiles = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -Force |
    Where-Object { -not $_.PSIsContainer }

$Total = $AllFiles.Count
$Counter = 0

foreach ($File in $AllFiles) {
    $Counter++
    if ($Counter % 1000 -eq 0) {
        Write-Progress -Activity "Scan" -Status "$Counter / $Total" -PercentComplete (($Counter / $Total) * 100)
    }

    $MatchedBy = $null

    foreach ($Pattern in $InterestingNames) {
        if ($File.Name -like $Pattern) {
            $MatchedBy = "Nom"
            break
        }
    }

    if (-not $MatchedBy -and ($InterestingExtensions -contains $File.Extension.ToLower())) {
        $MatchedBy = "Extension"
    }

    if ($MatchedBy) {
        $Results.Add([PSCustomObject]@{
            Name         = $File.Name
            FullPath     = $File.FullName
            Extension    = $File.Extension
            SizeKB       = [math]::Round($File.Length / 1KB, 2)
            LastModified = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            MatchedBy    = $MatchedBy
        })
    }
}

Write-Progress -Activity "Scan" -Completed
Write-Host "[+] $($Results.Count) fichiers trouves." -ForegroundColor Green

$TableRows = ""
foreach ($R in $Results) {
    $TableRows += "    <tr>`n"
    $TableRows += "      <td>" + (HtmlEncode $R.Name) + "</td>`n"
    $TableRows += "      <td class='path'>" + (HtmlEncode $R.FullPath) + "</td>`n"
    $TableRows += "      <td>" + (HtmlEncode $R.Extension) + "</td>`n"
    $TableRows += "      <td>" + $R.SizeKB + " KB</td>`n"
    $TableRows += "      <td>" + $R.LastModified + "</td>`n"
    $TableRows += "      <td>" + (HtmlEncode $R.MatchedBy) + "</td>`n"
    $TableRows += "    </tr>`n"
}

$ScanDate   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$TotalFound = $Results.Count
$HostName   = $env:COMPUTERNAME
$PathEnc    = HtmlEncode $Path

$Html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Interesting Files - $HostName</title>
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
  Host : <b>$HostName</b> &nbsp;|&nbsp;
  Path : <b>$PathEnc</b> &nbsp;|&nbsp;
  Date : <b>$ScanDate</b> &nbsp;|&nbsp;
  Total : <b>$TotalFound fichiers</b>
</div>

<div class="filters">
  <div class="filters-row">
    <input type="text" id="search" placeholder="Filtrer nom, chemin, extension..." oninput="applyFilters()">
    <span class="count">Affichage : <span id="visible-count">$TotalFound</span> / $TotalFound</span>
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
$TableRows
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
      const show =
        (!q || r.cells[0].textContent.toLowerCase().includes(q)
            || r.cells[1].textContent.toLowerCase().includes(q)
            || r.cells[2].textContent.toLowerCase().includes(q))
        && matches.has(r.cells[5].textContent.trim())
        && extSet.has(r.cells[2].textContent.trim());
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
"@

$Html | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Host "[+] Rapport genere : $OutputFile" -ForegroundColor Green
