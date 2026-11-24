# WoW Forever addon + macro setup for a new PC (JangHyunGyu/wowforever)
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/JangHyunGyu/JangHyunGyu/main/wowforever/setup.ps1 | iex
# Installs the latest version of every addon in the work log, applies the patches,
# installs DruidMacros from this repo and rebuilds the TUGs solo guides (no dungeon / elite quests).
# Run it again after the game has been started and closed once to apply the SavedVariables settings.
& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$RAW = 'https://raw.githubusercontent.com/JangHyunGyu/JangHyunGyu/main/wowforever'
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131 Safari/537.36'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$cr = [string][char]13; $lf = [string][char]10; $tab = [string][char]9
function Say($m) { Write-Host ('[setup] ' + $m) }
# Leveling guide: Polestar (written for Forever, 1-60). Set $useTugs = $true to install Guidelime + TUGs
# with the solo patch instead of removing them (TUGs is Forever-specific only up to about level 35).
$useTugs = $false

# ---- 1. find the game ----
$wow = $null
foreach ($drv in (Get-PSDrive -PSProvider FileSystem)) {
  foreach ($p in 'Program Files (x86)\World of Warcraft', 'Program Files\World of Warcraft', 'World of Warcraft', 'Games\World of Warcraft') {
    $c = Join-Path $drv.Root $p
    if (-not $wow -and (Test-Path (Join-Path $c '_forever_\Wow.exe'))) { $wow = Join-Path $c '_forever_' }
  }
}
if (-not $wow) { throw 'WoW Forever (_forever_\Wow.exe) was not found. Install the game first.' }
$ao = Join-Path $wow 'Interface\AddOns'
New-Item -ItemType Directory -Force $ao | Out-Null
$running = [bool](Get-Process Wow -ErrorAction SilentlyContinue)
$stage = Join-Path $env:USERPROFILE ('wow_addons_' + (Get-Date -Format yyyyMMdd))
$zips = Join-Path $stage 'zips'; $ext = Join-Path $stage 'x'
New-Item -ItemType Directory -Force $zips, $ext | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
Say ('game: ' + $wow + '  (running: ' + $running + ')')
Say ('staging: ' + $stage)

function Get-File($url, $out, $referer) {
  $a = @('-sL', '--fail', '-A', $UA, '-o', $out)
  if ($referer) { $a += @('-e', $referer) }
  $a += $url
  & curl.exe @a
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $out)) { throw ('download failed: ' + $url) }
}
function Get-GitHub($repo, $pattern) {
  $rels = Invoke-RestMethod ('https://api.github.com/repos/' + $repo + '/releases?per_page=20') -Headers @{ 'User-Agent' = 'curl' }
  foreach ($r in $rels) {
    if ($r.prerelease) { continue }
    $as = $r.assets | Where-Object { $_.name -like $pattern } | Select-Object -First 1
    if ($as) {
      $out = Join-Path $zips $as.name
      Get-File $as.browser_download_url $out $null
      Say ($repo + '  ' + $r.tag_name)
      return $out
    }
  }
  throw ('no release asset for ' + $repo)
}
function Get-Curse($id, $label) {
  $json = & curl.exe -sL -A $UA ('https://www.curseforge.com/api/v1/mods/' + $id + '/files?pageIndex=0&pageSize=20&sort=dateCreated&sortDescending=true')
  $files = ($json | ConvertFrom-Json).data
  $f = $files | Where-Object { $_.releaseType -eq 1 -and (@($_.gameVersions) -match '^1\.6') } | Select-Object -First 1
  if (-not $f) { throw ('no Forever file on CurseForge for ' + $label) }
  $out = Join-Path $zips $f.fileName
  Get-File ('https://www.curseforge.com/api/v1/mods/' + $id + '/files/' + $f.id + '/download') $out $null
  Say ($label + '  ' + $f.fileName)
  return $out
}

# ---- 2. download the latest of everything ----
$zipList = @()
$zipList += Get-GitHub 'Questie/Questie' 'Questie-*.zip'
$zipList += Get-GitHub 'fitzforge/polestar' 'Polestar-*.zip'
if ($useTugs) { $zipList += Get-GitHub 'max-ri/Guidelime' 'Guidelime-*.zip' }
$zipList += Get-GitHub 'cjber/shortest-path-forever' '*forever.zip'
$zipList += Get-GitHub 'Nevcairiel/GatherMate2' 'GatherMate2-*.zip'
$zipList += Get-GitHub 'Nevcairiel/GatherMate2_Data' 'GatherMate2_Data-*.zip'
$zipList += Get-Curse 1707376 'GodJohnson'
if ($useTugs) { $zipList += Get-Curse 335816 'GuideLime_TUGs_Forever' }
$zipList += Get-Curse 261459 'FasterLoot'
$zipList += Get-Curse 1710286 'LayerSwap'
$zipList += Get-Curse 1716822 'ForeverLayerHop'
$zipList += Get-Curse 1724751 'ForeverVisibility'

# ---- 3. extract and copy (never QuestieTrace, retail GatherMate2 storage, movement speed addons) ----
$skip = '^(QuestieTrace|GatherMate2Storage_.*|MovementSpeed|WidgetTools|WidgetToolbox.*|Polestar_(deDE|esES|esMX|frFR|ptBR|ruRU|zhCN|zhTW))$'
if (-not $useTugs) { $skip = $skip.Replace('^(', '^(Guidelime|GuideLime_TUGs_Forever|') }
foreach ($zip in $zipList) {
  $dir = Join-Path $ext ([IO.Path]::GetFileNameWithoutExtension($zip))
  if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -Confirm:$false }
  [IO.Compression.ZipFile]::ExtractToDirectory($zip, $dir)
  foreach ($sub in (Get-ChildItem $dir -Directory)) {
    if ($sub.Name -notmatch $skip) { Copy-Item $sub.FullName -Destination $ao -Recurse -Force }
  }
}
foreach ($sub in (Get-ChildItem $ao -Directory)) {
  if ($sub.Name -match $skip) {
    $keep = Join-Path $stage 'removed_addons'
    New-Item -ItemType Directory -Force $keep | Out-Null
    Copy-Item $sub.FullName -Destination $keep -Recurse -Force
    Remove-Item $sub.FullName -Recurse -Force -Confirm:$false
    Say ('removed forbidden addon (backup kept in staging): ' + $sub.Name)
  }
}

# ---- 4. party finder (Inven attachment; AutoHotkey scripts are not copied) ----
try {
  foreach ($n in 'FindParty', 'MessageQueue') {
    $zp = Join-Path $zips ($n + '.zip')
    Get-File ('https://upload3.inven.co.kr/upload/2026/10/02/bbs/' + $n + '.zip') $zp 'https://www.inven.co.kr/board/wow/6569/360'
    $dir = Join-Path $ext ('inven_' + $n)
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -Confirm:$false }
    [IO.Compression.ZipFile]::ExtractToDirectory($zp, $dir)
    $src = $dir; if (Test-Path (Join-Path $dir $n)) { $src = Join-Path $dir $n }
    $dst = Join-Path $ao $n
    New-Item -ItemType Directory -Force $dst | Out-Null
    Get-ChildItem $src | Where-Object { $_.Extension -ne '.ahk' } | Copy-Item -Destination $dst -Recurse -Force
  }
  Say 'FindParty + MessageQueue installed'
} catch { Say ('WARNING: party finder not installed: ' + $_.Exception.Message) }

# ---- 5. Guidelime koKR font patch ----
$mw = Join-Path $ao 'Guidelime\MainWindow.lua'
$txt = 'koKR font fix'; if (Test-Path $mw) { $txt = [IO.File]::ReadAllText($mw, $utf8) }
if ($txt -notmatch 'koKR font fix') {
  $nl = $lf; if ($txt.Contains($cr + $lf)) { $nl = $cr + $lf }
  $anchor = 'function MW.getFontPath()' + $nl
  $pos = $txt.IndexOf($anchor)
  if ($pos -ge 0) {
    $ins = $anchor + $tab + '-- koKR font fix' + $nl + $tab + 'if GetLocale() == "koKR" and STANDARD_TEXT_FONT then return STANDARD_TEXT_FONT end' + $nl
    $txt = $txt.Substring(0, $pos) + $ins + $txt.Substring($pos + $anchor.Length)
    [IO.File]::WriteAllText($mw, $txt, $utf8)
    Say 'Guidelime koKR font patch applied'
  } else { Say 'WARNING: Guidelime patch anchor not found (MW.getFontPath changed upstream)' }
}

# ---- 6. ForeverLayerHop slider patch (only where upstream has no OnValueChanged line) ----
foreach ($file in (Get-ChildItem (Join-Path $ao 'ForeverLayerHop') -Filter *.lua -ErrorAction SilentlyContinue)) {
  $lines = [IO.File]::ReadAllLines($file.FullName, $utf8)
  $res = New-Object System.Collections.Generic.List[string]
  $added = 0
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $res.Add($lines[$i])
    $m = [regex]::Match($lines[$i], '(\w+)\s*=\s*CreateFrame\("Slider".*UIPanelScrollBarTemplate')
    if ($m.Success -and ($i + 1 -ge $lines.Length -or $lines[$i + 1] -notmatch 'OnValueChanged')) {
      $res.Add($m.Groups[1].Value + ':SetScript("OnValueChanged", nil)')
      $added++
    }
  }
  if ($added -gt 0) { [IO.File]::WriteAllLines($file.FullName, $res, $utf8); Say ('ForeverLayerHop patched: ' + $file.Name + ' x' + $added) }
}

# ---- 7. DruidMacros (this repo) ----
$dm = Join-Path $ao 'DruidMacros'
New-Item -ItemType Directory -Force $dm | Out-Null
foreach ($n in 'DruidMacros.lua', 'DruidMacros.toc') { Get-File ($RAW + '/DruidMacros/' + $n) (Join-Path $dm $n) $null }
$ver = (Select-String -Path (Join-Path $dm 'DruidMacros.toc') -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1).Matches[0].Groups[1].Value
Say ('DruidMacros ' + $ver)

# ---- 8. TUGs solo guides: drop dungeon / instance quests everywhere, elite quests in guides from level 20,
#         quests that need a removed quest first, and the dungeon-only instruction lines ----
$soloAll = '17,166,167,168,214,350,373,377,386,387,388,389,391,392,393,394,395,396,434,704,709,721,722,723,724,725,726,727,971,1050,1139,1198,1199,1200,1275,1360,2040,2198,2199,2200,2201,2204,2240,2278,2279,2361,2398,2418,2439,2745,2746,2768,2864,2865,2922,2923,2924,2925,2926,2927,2928,2929,2930,2931,2963,3042,3527,3801,3802,4024,4123,4126,4128,4241,4262,4286,4341,5848,92415,95161,95189,95195,95250,95647,95737,95772,96393,96394,96395,96403'
$soloElite = '19,55,115,169,193,197,208,228,248,303,304,474,543,628,630,631,632,633,634,682,684,685,694,695,696,697,706,717,762,779,1380,1448,1449,1450,2879,2942,2943,2944,2946,2954,2964,2977,3181,3182,3201,3372,3452,3453,3454,3462,3463,3481,3566,4023,4182,4183,4184,4185,4186,4223,4224,5153,5154,5156,5168,5181,5210,6025,6182,6183,6184,6185,7701,95999'
$soloDrop = 'Start looking for a Halls of Thanes group|CAREFUL, the endboss FEARS|Use the lever right next to the Quest you just accepted|I suggest to do RoL now|Look for a group for deadmines|The first 2 quests are in the cave but before the dungeon|Do the dungeon now. The endboss drops|Either use Hearthstone now OR run out and turnin the quests: The Defias|As a Group do Ruuzel|If you do NOT have the stockade quests|We will turn in the other 2 dungeons quests|Search for people to do the Elite quests with|are pretty hard quests solo. I usually skip them|Start looking for a BFD dungeon group|You do BFD now|in a group, do the follow up ELITE|in a group, accept the follow up ELITE|If you are in a group, do the follow-up elite quest|If you dont intent to do Uldaman|Now do Uldaman quests|Go further into Uldaman|If you havent found|Do a full run of Uldaman|Run into the room with Ironaya|Take the Gni|In the same Room as the dwarves there is an Urn|In the Room with Galgann Firehammer|Kill Grimlok, loot the Sapphire|BUY: 5 Silver Bars|If youre not doing brd, fly to Ironforge|Were going into BRD soon|Run back to the Blackrock go into the middle part|If youre in a group do the next step,if not skip it|The next quest requires you to interact with a corpse downstairs'
$al = Join-Path $ao 'GuideLime_TUGs_Forever\TUGs\Alliance'
$bk = $al + '_backup_original'
if (Test-Path $al) {
  New-Item -ItemType Directory -Force $bk | Out-Null
  Copy-Item (Join-Path $al '*.lua') $bk -Force
  $setAll = @{}; foreach ($q in $soloAll.Split(',')) { $setAll[$q] = 1 }
  $setElite = @{}; foreach ($q in $soloElite.Split(',')) { $setElite[$q] = 1 }
  $dropList = $soloDrop.Split('|')
  $rx = [regex]'\[Q[A-Z]{1,2}\s*(\d+)[^\]]*\]'
  $total = 0; $changed = 0
  foreach ($file in (Get-ChildItem -LiteralPath $bk -Filter *.lua)) {
    $raw = [IO.File]::ReadAllText($file.FullName, $utf8)
    $nl = $lf; if ($raw.Contains($cr + $lf)) { $nl = $cr + $lf }
    $level = 0; $m = [regex]::Match($raw, '\[N\s*(\d+)'); if ($m.Success) { $level = [int]$m.Groups[1].Value }
    $kept = New-Object System.Collections.ArrayList
    $removed = 0
    foreach ($line in ($raw -split '\r?\n')) {
      $tags = $rx.Matches($line); $drop = $false; $new = $line
      if ($tags.Count -gt 0) {
        $gone = @()
        foreach ($tg in $tags) {
          $id = $tg.Groups[1].Value
          if ($setAll.ContainsKey($id) -or ($level -ge 20 -and $setElite.ContainsKey($id))) { $gone += $tg }
        }
        if ($gone.Count -eq $tags.Count) { $drop = $true } else { foreach ($tg in $gone) { $new = $new.Replace($tg.Value, '') } }
      } else {
        foreach ($w in $dropList) { if ($line.Contains($w)) { $drop = $true } }
      }
      if ($drop) { $removed++ } else { [void]$kept.Add($new) }
    }
    if ($removed -gt 0 -and @($kept | Where-Object { $rx.IsMatch($_) }).Count -eq 0) {
      $shell = New-Object System.Collections.ArrayList
      foreach ($k in $kept) {
        if ($k -match '^(Guidelime\.registerGuide\(|\[\[|\]\]|\[(GA|N|NX|D)[ \d]|Thanks for using|$)') { [void]$shell.Add($k) } else { $removed++ }
      }
      $kept = $shell
    }
    [IO.File]::WriteAllText((Join-Path $al $file.Name), ($kept -join $nl), $utf8)
    if ($removed -gt 0) { $changed++; $total += $removed }
  }
  Say ('TUGs solo guides rebuilt: ' + $total + ' lines removed in ' + $changed + ' files (originals in Alliance_backup_original)')
} else { Say 'WARNING: TUGs Alliance folder not found, solo patch skipped' }

# ---- 9. SavedVariables (only with the game closed, only once the files exist) ----
if ($running) {
  Say 'The game is running: SavedVariables were not touched. Close the game and run this again for the GodJohnson arrow setting.'
} else {
  $svs = @(Get-ChildItem (Join-Path $wow 'WTF\Account') -Recurse -Filter 'GodJohnsonGoldBorder.lua' -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -like '*SavedVariables' })
  if ($svs.Count -eq 0) { Say 'GodJohnson settings file does not exist yet. Log in once, close the game, then run this again.' }
  foreach ($sv in $svs) {
    $old = [IO.File]::ReadAllText($sv.FullName, $utf8)
    $new = [regex]::Replace($old, '(\["frontArrow"\]\s*=\s*)true', '$1false')
    $new = [regex]::Replace($new, '(\["navigationArrowDisabled"\]\s*=\s*)false', '$1true')
    if ($new -ne $old) {
      $svb = Join-Path $stage 'sv_backup'
      New-Item -ItemType Directory -Force $svb | Out-Null
      Copy-Item $sv.FullName -Destination $svb -Force
      [IO.File]::WriteAllText($sv.FullName, $new, $utf8)
      Say 'GodJohnson 3D arrow turned off (backup in staging\sv_backup)'
    } elseif ($old -match '\["frontArrow"\]\s*=\s*false') {
      Say 'GodJohnson 3D arrow already off'
    } else {
      Say 'GodJohnson arrow keys not found in the settings file: turn the 3D arrow off in the GodJohnson options instead'
    }
  }
}

# ---- 10. summary ----
Say '--- installed ---'
foreach ($sub in (Get-ChildItem $ao -Directory | Sort-Object Name)) {
  if ($sub.Name -like 'GodJohnsonFontChoice*') { continue }
  $v = ''
  foreach ($toc in (Get-ChildItem $sub.FullName -Filter *.toc)) {
    if (Select-String -Path $toc.FullName -Pattern '^## Interface:.*16001' -Quiet) {
      $hit = Select-String -Path $toc.FullName -Pattern '^## Version:\s*(.+)$' | Select-Object -First 1
      if ($hit) { $v = $hit.Matches[0].Groups[1].Value.Trim() }
    }
  }
  Say ('  ' + $sub.Name + '  ' + $v)
}
Say 'Done. Restart the game completely (a /reload does not load new addon folders), enable every addon on the character screen,'
Say 'then log in on the druid: DruidMacros builds the macros and action bars after 3 seconds.'
}
