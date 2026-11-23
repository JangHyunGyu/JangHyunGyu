-- DruidMacros 5.1: 드루이드 한글 매크로 자동 생성 + 단축바 자동 배치
local TAG = "|cffff7d0a[드루이드 매크로]|r "
local function P(msg) print(TAG .. msg) end

-- 주문 ID로 클라이언트 언어의 이름을 가져온다(한글 클라면 한글 이름).
local function N(id, fallback)
  local n
  if C_Spell and C_Spell.GetSpellName then n = C_Spell.GetSpellName(id) end
  if not n and GetSpellInfo then n = GetSpellInfo(id) end
  return n or fallback
end
-- 주문책에 같은 이름이 있으면 배운 것으로 본다(2등급 이상을 배우면 1등급 ID가 '모름'으로 나오는 문제 방지)
local function InBook(name)
  if not name then return false end
  local found = false
  pcall(function()
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
      for j = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
        local it = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
        if it and it.name == name and it.spellID then found = true; return end
      end
    end
  end)
  return found
end
local function Known(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  if IsSpellKnown and IsSpellKnown(id) then return true end
  return InBook(N(id, nil))
end

local function K(id, fb) if Known(id) then return N(id, fb) end end
local function CAST(t)
  local out = {}
  local real = false
  for _, c in ipairs(t) do
    if c[2] then out[#out+1] = c[1]..c[2]; real = true
    elseif c[3] or c[1]:match("^%[form:[%d/]+%] $") then out[#out+1] = c[1] end -- 못 배운 폼 스킬: 다른 폼으로 넘어가지 않게 막기
  end
  if not real then return "" end
  return "/cast "..table.concat(out, "; ")
end
local function BANG(n) return n and ("!"..n) or nil end

-- 폼 번호는 배운 폼 순서로 정해진다(바다표범을 안 배웠으면 표범이 2번). 실제 번호를 찾아 쓴다.
local function FormIndex(ids, default)
  local ok, n = pcall(GetNumShapeshiftForms)
  if ok and n then
    for i = 1, n do
      local r = {pcall(GetShapeshiftFormInfo, i)}
      if r[1] then for k = 2, 6 do for _, id in ipairs(ids) do if r[k] == id then return tostring(i) end end end end
    end
  end
  return default
end

local function BuildList()
  local FB = FormIndex({5487, 9634}, "1")
  local FC = FormIndex({768}, "3")
  local FA = FormIndex({1066}, "2") -- 바다표범
  local function F(t) return (t:gsub("form:1/3", "form:"..FB.."/"..FC):gsub("form:1", "form:"..FB):gsub("form:3", "form:"..FC)) end
  local claw, rake, bite, rip = K(1082,"할퀴기"), K(1822,"갈퀴 발톱"), (K(1328618,"흉포한 이빨") or K(22568,"흉포한 이빨")), K(1079,"도려내기")
  local shred, ravage, pounce = K(5221,"칼날 발톱"), K(6785,"찢어발기기"), K(9005,"암습")
  local maul, swipe, demo, growl = K(6807,"후려치기"), K(779,"휘둘러치기"), K(99,"위협의 포효"), K(6795,"포효")
  local bash, enrage, frenzy = K(5211,"강타"), K(5229,"분노"), K(22842,"광포한 재생력")
  -- 포에버 야성의 돌진 특성(1238122). 표범 폼에서는 등 뒤로 도약하는 표범판(414924)으로 바뀐다
  local charge = K(414924,"야성의 돌진") or K(1238122,"야성의 돌진") or K(16979,"야성의 돌진")
  -- 5.0: 포에버는 호랑이의 분노 삭제(대신 40레벨 특성 '변신의 힘'). 나이트엘프 종족 기술 엘룬의 빛(치명타 +10%, 15초, 3분)을 대신 쓴다
  local cower, dash, prowl = K(8998,"웅크리기"), K(1850,"질주"), K(5215,"숨기")
  local elune = K(1259799,"엘룬의 빛")
  local moonfire, wrath, ff, fff = K(8921,"달빛 섬광"), K(5176,"천벌"), K(770,"요정의 불꽃"), K(16857,"요정의 불꽃(야성)")
  local cat, travel, aquatic = K(768,"표범 변신"), K(783,"치타 변신"), K(1066,"바다표범 변신")
  local bear = K(9634,"광포한 곰 변신") or K(5487,"곰 변신")
  local roots, hib, grasp = K(339,"휘감는 뿌리"), K(2637,"겨울잠"), K(16689,"자연의 손아귀")
  local rejuv, regrowth, ht = K(774,"회복"), K(8936,"재생"), K(5185,"치유의 손길")
  local motw, thorns, innerv, bark = K(1126,"야생의 징표"), K(467,"가시"), K(29166,"정신 자극"), K(22812,"나무 껍질")
  local curse = K(2782,"저주 해제")
  local poison = K(2893,"독 해제") or K(8946,"해독")
  local rebirth = K(20484,"환생")
  local MO = "[@mouseover,help,nodead][help,nodead][@player] "
  local MOS = "[mod:shift,@mouseover,help,nodead][mod:shift,help,nodead][mod:shift,@player] "
  local MH = "[@mouseover,harm,nodead][] "
  local T, SA = "#showtooltip\n", "#showtooltip\n/startattack\n"
  local list = {
    -- 1~12: 단축바 1,2,...,9,0,-,=   13~: 키 직접 연결
    {"DM1 공격", SA..CAST{{"[form:1] ",maul},{"[form:3,stealth,mod:shift] ",ravage},{"[form:3,stealth] ",pounce},{"[form:3,mod:shift] ",shred},{"[form:3] ",claw},{"",wrath}}},
    {"DM2 출혈", SA..CAST{{"[form:1] ",swipe},{"[form:3] ",rake},{MH,moonfire}}},
    {"DM3 마무리", SA..CAST{{"[form:1] ",demo},{"[form:3,mod:shift] ",rip},{"[form:3] ",bite or rip},{MH,roots}}},
    {"DM4 요정불꽃", T..CAST{{"[form:1/3] ",fff or ff},{MH,ff}}}, -- 포에버: 일반 요정의 불꽃이 표범·곰에서도 써짐(야성 특성 삭제)
    {"DM5 포효", T..CAST{{"[form:1] ",growl},{"[form:3] ",cower},{MH,hib}}},
    {"DM6 회복", T..CAST{{MOS,ht},{MO,rejuv}}},
    {"DM7 재생", T..CAST{{MO,regrowth}}},
    {"DM8 생존", T..CAST{{"[mod:shift,@mouseover,help,nodead][mod:shift] ",innerv},{"",bark}}},
    {"DM9 숨기질주", T..CAST{{"[noform:3] ",BANG(cat)},{"[combat] ",dash},{"[nostealth] ",prowl}}},
    {"DM0 버프", T..CAST{{MOS,thorns},{"[help,nodead][@player] ",motw}}},
    {"DM- 해제", T..CAST{{MOS,poison},{MO,curse}}},
    {"DM= 부활", T.."/cast [combat,@mouseover,help,dead][combat] "..(rebirth or "환생").."; [@mouseover,help,dead][] 되살리기"},
    {"DME 곰", T..(bear and "/cancelform [form:1,nomod:shift]\n" or "")..CAST{{"[mod:shift,form:1] ",nil,true},{"",BANG(bear)}}, {"E","SHIFT-E"}}, -- 4.8: 곰에서 E = 폼 풀고 바로 다시 곰
    -- 여러 번 눌러도 폼이 안 풀린다(! 붙임). 해제는 F1. 숨기는 마우스 휠 클릭(4.1). Q 하나로: 물속 바다표범 / 밖에서 전투 아닐 때 치타(30렙) / 나머지 표범. Shift+Q는 무조건 표범
    {"DMQ 표범", T..(cat and ("/cancelform [form:3"..(aquatic and ("/"..FA) or "")..",nomod:shift]\n") or "")..CAST{{"[mod:shift,form:3] ",nil,true},{"[mod:shift] ",BANG(cat)},{"[swimming] ",BANG(aquatic)},{"[nocombat,outdoors] ",BANG(travel)},{"",BANG(cat)}}, {"Q","SHIFT-Q"}}, -- 4.7/4.8: 표범·바다표범에서 Q = 폼 풀고 바로 다시 표범(이동 불가·감속 풀기). Shift+Q는 표범이면 그대로
    {"DMR 강타", "#showtooltip\n/startattack [form:1]\n"..CAST{{"[mod:shift,form:1/3] ",grasp},{"[form:1] ",bash},{"[form:3] ",elune},{"[mod:shift] ",elune},{"",grasp}}, {"R","SHIFT-R"}}, -- 5.0: R 곰 강타/표범 엘룬의 빛/사람 자연의 손아귀, Shift+R 곰·표범 자연의 손아귀/사람 엘룬의 빛
    {"DMF 생존기", T..CAST{{"[form:1,mod:shift] ",frenzy},{"[form:1] ",enrage},{"[form:3] ",dash},{"",bark}}, {"F","SHIFT-F"}},
    {"DM 변신해제", T.."/cancelform", {"F1"}},
    -- 4.1: 숨기 = 마우스 가운데(휠) 클릭. 사람·곰이면 표범으로 변신, 표범이면 숨기. 숨은 상태에서 눌러도 안 풀림
    {"DM 숨기", T..CAST{{"[noform:3] ",BANG(cat)},{"",prowl}}, {"BUTTON3"}}, -- 4.9: 은신 중 한 번 더 누르면 은신 해제
    {"DM 섬광곰", (ff and moonfire and bear) and (T.."/cancelform [form:1]\n/castsequence reset=target/combat "..ff..", "..moonfire..", "..bear) or ""},
    {"DM 위상", "/ls swap"},
    -- 4.2: 돌진+칼날발톱. 1번 누르면 등 뒤로 돌진, 바로 한 번 더 누르면 칼날 발톱(돌진 쿨이면 바로 칼날 발톱). 4.4부터 표범·숨기 바 5번(도려내기는 3번 Shift)
    {"DM 돌진발톱", (shred or claw) and (SA..(charge and ("/cast [form:3,harm,nodead] "..charge.."\n") or "")..CAST{{"[form:3] ",shred or claw}}) or ""},
    {"DM 표범마무리", (bite or rip) and (SA..CAST{{"[mod:shift] ",rip},{"",bite or rip}}) or ""},
  }
  for _, m in ipairs(list) do m[2] = F(m[2]) end
  return list
end

-- 배운 주문 목록을 저장(매크로 맞춤용)
local CHECK = {1328618,1328617,1259799,2912,2908,20580,437138,1238122,414924,1082,1822,22568,1079,6807,779,99,8921,5176,770,6795,5211,9005,6785,5221,5487,9634,768,783,1066,5215,1850,339,2637,774,8936,5185,1126,467,2782,2893,8946,20484,22812,5229,22842,16689,16857,16979,5570,24858,29166,18960}
local function DumpSpells()
  local t, k = {}, {}
  pcall(function()
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
      for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
        for j = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
          local it = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
          if it and it.spellID then t[#t+1] = (info.name or "?").."|"..it.spellID.."|"..(it.name or "") end
        end
      end
    elseif GetNumSpellTabs then
      for i = 1, GetNumSpellTabs() do
        local tn, _, off, num = GetSpellTabInfo(i)
        for j = off + 1, off + num do
          local _, id = GetSpellBookItemInfo(j, "spell")
          t[#t+1] = (tn or "?").."|"..tostring(id).."|"..(GetSpellBookItemName(j, "spell") or "")
        end
      end
    end
  end)
  for _, id in ipairs(CHECK) do if Known(id) then k[#k+1] = id..":"..N(id, "?") end end
  DruidMacrosDB.spells, DruidMacrosDB.known, DruidMacrosDB.level = t, k, UnitLevel("player")
end

local ICON = "INV_MISC_QUESTIONMARK"
local OLD = {"DM8 변신","표범공격","표범변신","곰공격","이동변신","MO회복","MO재생","MO뿌리","요정의불꽃","야생의징표","부활"}
-- 1~12 기본바, 73~84 표범, 85~96 숨기, 97~108 곰, 109~120 달빛야수
local FORM_BASES = {0, 72, 84, 96, 108}
local KEYS = {"1","2","3","4","5","6","7","8","9","0","-","="}

local function IsDruid() local _, c = UnitClass("player"); return c == "DRUID" end

local function MakeMacros()
  for _, n in ipairs(OLD) do
    local i = GetMacroIndexByName(n); if i and i > 0 then pcall(DeleteMacro, i) end
  end
  local ok_n, fail = 0, 0
  for _, m in ipairs(BuildList()) do
    local name, body = m[1], m[2]
    if body ~= "" then
    local idx = GetMacroIndexByName(name)
    if idx and idx > 0 then
      if pcall(EditMacro, idx, name, ICON, body) then ok_n = ok_n + 1 else fail = fail + 1 end
    else
      local ok, ni = pcall(CreateMacro, name, ICON, body, true)
      if ok and ni then ok_n = ok_n + 1 else fail = fail + 1 end
    end
    end
  end
  return ok_n, fail
end

local function Backup()
  local b = {}
  for slot = 1, 120 do
    local t, id = GetActionInfo(slot)
    if t == "spell" or t == "item" then
      b[slot] = {t, id}
    elseif t == "macro" and id then
      local mn = GetMacroInfo(id)
      if mn then b[slot] = {"macro", mn} end
    end
  end
  DruidMacrosDB.backup = b
end

local function ClearAll()
  for slot = 1, 120 do
    if HasAction(slot) then PickupAction(slot); ClearCursor() end
  end
end

local function PlaceAll()
  local list = BuildList()
  for i, m in ipairs(list) do
    local idx = i <= 12 and GetMacroIndexByName(m[1])
    if idx and idx > 0 then
      for _, base in ipairs(FORM_BASES) do
        PickupMacro(idx); PlaceAction(base + i); ClearCursor()
      end
    end
  end
  -- 숫자키가 비어 있으면 기본 단축바에 연결
  local changed = false
  for i, key in ipairs(KEYS) do
    local cmd = "ACTIONBUTTON"..i
    local cur = GetBindingAction(key)
    if not GetBindingKey(cmd) and (cur == nil or cur == "") then SetBinding(key, cmd); changed = true end
  end
  if changed and SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
end

-- 꾹 누르기(연속 시전)는 매크로에선 안 되므로, 연타 스킬은 폼별 단축바에 주문을 직접 올린다.
-- {단축바 시작, {칸번호 = 주문ID}}
local SPELLBARS = {
  {0,   {[1]="DM 섬광곰", [2]=5176, [3]=339,   [4]=770,   [5]=2637, [8]={2912,"DM8 생존"}}},  -- 사람: 섬광곰 천벌 뿌리 요정불꽃 겨울잠 / 5.0: 8 별빛섬광(20렙, 원거리 첫 타)
  {72,  {[1]=1082, [2]=1822, [3]="DM 표범마무리", [4]={16857,770}, [5]="DM 돌진발톱", [8]=5221}},    -- 표범: 할퀴기 갈퀴 마무리(이빨, Shift 도려내기) 요정불꽃(야성) 도려내기 / 8 칼날발톱
  {84,  {[1]={9005,5221,1082}, [2]={6785,1822,1082}, [3]={5221,1082}, [4]={16857,770}, [5]="DM 돌진발톱", [8]=5221}},    -- 숨기: 암습 찢어발기기 칼날발톱 (못 배웠으면 할퀴기·갈퀴로 대신)
  {96,  {[1]="DM3 마무리", [2]=6807, [3]=779,  [4]={16857,770}, [5]=6795, [8]={1328617,"DM8 생존"}}}, -- 곰: 1위협의포효(매크로) 2후려치기 3휘둘러치기 4요정불꽃 5포효 / 5.0: 8 가르기(25렙 특성, 안 찍었으면 원래 매크로)
  {108, {[1]=5176, [2]=8921, [3]=339,   [4]=770,   [5]=2637}},              -- 달빛야수
}
local function BookSlot(name)
  local best, bestID
  pcall(function()
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local info = C_SpellBook.GetSpellBookSkillLineInfo(i)
      for j = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
        local it = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
        if it and it.name == name and it.spellID then best, bestID = j, it.spellID end -- 마지막 = 최고 등급
      end
    end
  end)
  return best, bestID
end
local function PlaceSpell(slot, id)
  if type(id) == "table" then -- 앞에서부터 배운 첫 주문
    local pick = id[#id]
    for _, x in ipairs(id) do if type(x) == "string" or Known(x) then pick = x; break end end
    id = pick
  end
  if type(id) == "string" then -- 매크로로 둘 칸(자동 공격 필요)
    local idx = GetMacroIndexByName(id)
    local t, aid = GetActionInfo(slot)
    if idx and idx > 0 and not (t == "macro" and aid == idx) then
      ClearCursor(); PickupMacro(idx); PlaceAction(slot); ClearCursor()
    end
    return
  end
  if not Known(id) then
    if HasAction(slot) then PickupAction(slot); ClearCursor() end
    return
  end
  local name = N(id, nil)
  local j, topID = BookSlot(name)
  local t, aid = GetActionInfo(slot)
  if t == "spell" and (aid == topID or (not topID and aid == id)) then return end
  ClearCursor()
  if j then pcall(C_SpellBook.PickupSpellBookItem, j, Enum.SpellBookSpellBank.Player) end
  if not GetCursorInfo() then pcall((C_Spell and C_Spell.PickupSpell) or PickupSpell, name or id) end
  if GetCursorInfo() then PlaceAction(slot) end
  ClearCursor()
end
local function PlaceSpells()
  for _, bar in ipairs(SPELLBARS) do
    for i, id in pairs(bar[2]) do PlaceSpell(bar[1] + i, id) end
  end
end

local function Restore()
  local b = DruidMacrosDB and DruidMacrosDB.backup
  if not b then P("저장해 둔 원래 배치가 없어요."); return end
  ClearAll()
  for slot, a in pairs(b) do
    local fn
    if a[1] == "spell" then fn = (C_Spell and C_Spell.PickupSpell) or PickupSpell
    elseif a[1] == "item" then fn = (C_Item and C_Item.PickupItem) or PickupItem
    elseif a[1] == "macro" then fn = PickupMacro end
    if fn then pcall(fn, a[2]) end
    if GetCursorInfo() then PlaceAction(slot) end
    ClearCursor()
  end
  P("원래 단축바 배치로 되돌렸어요.")
end

local BINDV = 5
local function BindKeys(force)
  -- 4.3: 지도는 ` 키(사용자 요청). M도 그대로 둔다
  if GetBindingAction("`") ~= "TOGGLEWORLDMAP" then
    SetBinding("`", "TOGGLEWORLDMAP")
    if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
  end
  -- 5.0: Shift+숫자는 와우 기본이 '단축바 페이지 넘기기'라서 Shift+3(도려내기) 등을 누르면 바가 3페이지로 넘어가 폼 바가 안 바뀌었다.
  -- Shift+숫자를 같은 칸 버튼에 묶어 매크로의 [mod:shift]가 나가게 하고, 페이지가 넘어가 있으면 1페이지로 되돌린다
  local sc = false
  for i, key in ipairs(KEYS) do
    local cmd = "ACTIONBUTTON"..i
    if GetBindingAction("SHIFT-"..key) ~= cmd then SetBinding("SHIFT-"..key, cmd); sc = true end
  end
  if sc and SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
  if GetActionBarPage and ChangeActionBarPage and GetActionBarPage() ~= 1 then ChangeActionBarPage(1) end
  if DruidMacrosDB.bindv == BINDV and not force then return end
  for _, m in ipairs(BuildList()) do
    if m[3] then for _, key in ipairs(m[3]) do SetBindingMacro(key, m[1]) end end
  end
  if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
  local first = DruidMacrosDB.bindv ~= BINDV
  DruidMacrosDB.bindv = BINDV
  if first then
    PlaceAll(); PlaceSpells()
    P("레벨에 맞춘 배치로 바꿨어요. 아직 안 배운 스킬은 배우면 자동으로 켜져요.")
    P("1~5는 꾹 누르면 연타돼요. 1공격 2출혈 3마무리 4요정불꽃 5도발/도려내기 6회복 7재생 8나무껍질(Shift 정신자극) 9숨기/질주 0버프 -해제 =부활")
    P("휠 클릭 숨기(사람이면 표범 변신 후 한 번 더) Q 변신(물속 바다표범·밖 치타·그외 표범, Shift 표범) E곰 R 곰 강타·표범 엘룬의 빛·사람 자연의 손아귀(Shift+R 반대) F분노(Shift 광포한재생력)/질주/나무껍질 F1변신해제")
  end
end


-- 바에 없는 배운 스킬 전부(매크로에 든 것도)·귀환석을 위쪽 빈 칸(61~72, 49~60, 그다음 오른쪽 바 25~48)에 채운다. 단축키는 건드리지 않는다.
local HEARTH = 6948
local EXTRA_SLOTS = {61,62,63,64,65,66,67,68,69,70,71,72,49,50,51,52,53,54,55,56,57,58,59,60,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48}
local SKIP_EXTRA = {[6603]=true} -- 자동 공격
local FORCE_EXTRA = {[467]=true, [1126]=true} -- 가시, 야생의 징표는 매크로에 있어도 따로 칸에 둔다
-- 화면에 실제로 보이는 칸인지(숨긴 바·2페이지·폼 전용 페이지는 안 보임)
local BAR_OF = {{25,36,"MultiBarRight"},{37,48,"MultiBarLeft"},{49,60,"MultiBarBottomRight"},{61,72,"MultiBarBottomLeft"}}
local function Visible(slot)
  if slot <= 12 then return true end
  for _, b in ipairs(BAR_OF) do
    if slot >= b[1] and slot <= b[2] then
      local fr = _G[b[3]]
      return fr == nil or (fr.IsShown and fr:IsShown()) or false
    end
  end
  return false
end
local function PlaceExtras()
  if InCombatLockdown() then return end
  DruidMacrosDB = DruidMacrosDB or {}
  local EXV = 2
  -- 버전이 바뀌면 위쪽 두 줄(61~72, 49~60)을 비우고 처음부터 중복 없이 다시 채운다
  if DruidMacrosDB.extrav ~= EXV then
    for _, slot in ipairs(EXTRA_SLOTS) do
      if slot >= 49 and HasAction(slot) then PickupAction(slot); ClearCursor() end
    end
    DruidMacrosDB.extrav = EXV
  end
  -- 칸에 든 것의 키(주문은 이름, 매크로·아이템은 번호)
  local function ActKey(slot)
    local ok, t, id = pcall(GetActionInfo, slot)
    if not ok or not id then return nil end
    if t == "spell" then return N(id, nil)
    elseif t == "item" then return "item:"..id
    elseif t == "macro" then return "macro:"..id end
  end
  -- 4.5: 채우는 칸(EXTRA_SLOTS)에 이미 든 것은 바가 아직 안 보여도 '있음'으로 친다.
  -- (접속 직후 오른쪽 바가 아직 안 켜져 있으면 못 보고 또 넣어서 중복이 쌓이던 버그)
  -- 그리고 채우는 칸끼리 겹친 것은 하나만 남기고 지운다.
  local have, isExtra = {}, {}
  for _, slot in ipairs(EXTRA_SLOTS) do isExtra[slot] = true end
  for slot = 1, 12 do local k = ActKey(slot); if k then have[k] = true end end
  local removed = 0
  for _, slot in ipairs(EXTRA_SLOTS) do
    local k = ActKey(slot)
    if k then
      if have[k] then PickupAction(slot); ClearCursor(); removed = removed + 1
      else have[k] = true end
    end
  end
  for slot = 13, 120 do
    if not isExtra[slot] and Visible(slot) then local k = ActKey(slot); if k then have[k] = true end end
  end
  if removed > 0 then P("겹쳐 들어간 칸 "..removed.."개를 정리했어요.") end
  local want, seen = {}, {}
  local function addSpell(name, bookIdx)
    if not name or seen[name] or have[name] then return end
    seen[name] = true
    want[#want+1] = {"spell", name, bookIdx}
  end
  local hasHearth = 0
  pcall(function() hasHearth = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(HEARTH)) or (GetItemCount and GetItemCount(HEARTH)) or 0 end)
  if hasHearth > 0 and not have["item:"..HEARTH] then want[#want+1] = {"item", HEARTH} end
  for _, mn in ipairs({"DM 섬광곰", "DM 위상"}) do
    local mi = GetMacroIndexByName(mn)
    if mi and mi > 0 and not have["macro:"..mi] then have["macro:"..mi] = true; want[#want+1] = {"macro", mi} end
  end
  -- 주문책 전체(하나가 실패해도 나머지는 계속)
  local nLines = 0
  pcall(function() nLines = C_SpellBook.GetNumSpellBookSkillLines() end)
  for i = 1, nLines do
    local okL, info = pcall(C_SpellBook.GetSpellBookSkillLineInfo, i)
    if okL and info and not info.isGuild then
      for j = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
        pcall(function()
          local it = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
          if not it or not it.spellID or not it.name then return end
          if Enum.SpellBookItemType and it.itemType and it.itemType ~= Enum.SpellBookItemType.Spell then return end
          if SKIP_EXTRA[it.spellID] or it.isOffSpec then return end
          local passive = it.isPassive
          if passive == nil and C_Spell and C_Spell.IsSpellPassive then passive = C_Spell.IsSpellPassive(it.spellID) end
          if passive then return end
          addSpell(it.name, j)
        end)
      end
    end
  end
  -- 주문책 읽기가 막혀도 빠지지 않게: 드루이드 주문 목록으로 한 번 더
  local ALL = {1328618,1328617,1259799,20580,437138,5176,8921,2912,774,8936,5185,1126,467,339,770,2637,16689,1066,768,5487,9634,783,6807,6795,99,779,5211,5229,22842,16979,1082,1822,1079,22568,5221,6785,9005,5215,1850,5217,8998,2782,2893,8946,20484,50769,18960,29166,22812,24858,5570,2908,5225,16914,740,17116,5209}
  for _, id in ipairs(ALL) do
    pcall(function() if Known(id) then addSpell(N(id, nil), nil) end end)
  end
  -- 두 줄로 모자라면 오른쪽 세로 바(25~36)를 켠다
  local free = 0
  for _, slot in ipairs(EXTRA_SLOTS) do if not HasAction(slot) and Visible(slot) then free = free + 1 end end
  if #want > free then
    pcall(function()
      if SetActionBarToggles then SetActionBarToggles(1, 1, 1, 0, 0) end
      if MultiActionBar_Update then MultiActionBar_Update() end
    end)
  end
  local wi, added = 1, 0
  for _, slot in ipairs(EXTRA_SLOTS) do
    if wi > #want then break end
    if not HasAction(slot) and Visible(slot) then
      local w = want[wi]; wi = wi + 1
      ClearCursor()
      pcall(function()
        if w[1] == "macro" then PickupMacro(w[2])
        elseif w[1] == "item" then ((C_Item and C_Item.PickupItem) or PickupItem)(w[2])
        else
          local j = w[3] or BookSlot(w[2])
          if j then C_SpellBook.PickupSpellBookItem(j, Enum.SpellBookSpellBank.Player) end
          if not GetCursorInfo() then ((C_Spell and C_Spell.PickupSpell) or PickupSpell)(w[2]) end
        end
      end)
      if GetCursorInfo() then PlaceAction(slot); added = added + 1 end
      ClearCursor()
    end
  end
  if added > 0 then P("바에 없던 스킬·귀환석 "..added.."개를 위쪽 빈 칸에 넣었어요.") end
  if wi <= #want then P("빈 칸이 모자라 "..(#want - wi + 1).."개를 못 넣었어요.") end
end

-- 5.4: Q·E로 폼을 풀고 같은 순간 다시 변신하면 포에버 클라이언트가 보너스 바 값을 0으로 남긴다
-- (몸은 표범/곰인데 GetBonusBarOffset()=0 → 기본 바가 1페이지(사람)에 멈춤). 게임 안에서 직접 재현·확인함.
-- 보너스 바가 정상이면(b) 아무것도 안 한다. 폼은 있는데 보너스 바가 없을 때만 표범 7·은신 8·곰 9로 바꾸고,
-- 그 뒤 사람으로 돌아오면(n) 원래 페이지로 되돌린다. 상태 이름은 숫자를 쓰면 안 된다(숫자로 넘어와 페이지 0 오류, 5.3 실패 원인).
local fixHdr, fixCond
local FIX_STATE = [[
local m = self:GetFrameRef("mab")
if not m then return end
if newstate == "b" then self:SetAttribute("dmon", nil) return end
if newstate == "n" then
  if self:GetAttribute("dmon") then
    self:SetAttribute("dmon", nil)
    local p = GetActionBarPage()
    if not p or p < 1 or p > 6 then p = 1 end
    m:SetAttribute("actionpage", p)
    self:RunAttribute("dmref")
  end
  return
end
local pg = (newstate == "s" and 8) or (newstate == "c" and 7) or (newstate == "r" and 9)
if not pg then return end
m:SetAttribute("actionpage", pg)
self:SetAttribute("dmon", 1)
self:RunAttribute("dmref")
]]
local FIX_REF = [[
local n = (self:GetAttribute("dmt") or 0) + 1
self:SetAttribute("dmt", n)
for i = 1, 12 do
  local b = self:GetFrameRef("b"..i)
  if b then b:SetAttribute("dmfix", n) end
end
]]
local function FixBar()
  if not MainActionBar or not RegisterStateDriver or InCombatLockdown() then return end
  if not fixHdr then
    local ok, h = pcall(CreateFrame, "Frame", "DruidMacrosBarFix", UIParent, "SecureHandlerStateTemplate")
    if not ok or not h then return end
    fixHdr = h
    h:SetFrameRef("mab", MainActionBar)
    for i = 1, 12 do local b = _G["ActionButton"..i]; if b then h:SetFrameRef("b"..i, b) end end
    h:SetAttribute("dmref", FIX_REF)
    h:SetAttribute("_onstate-dmfix", FIX_STATE)
  end
  local FB = FormIndex({5487, 9634}, "1")
  local FC = FormIndex({768}, "3")
  local cond = "[bonusbar]b;[form:"..FC..",stealth]s;[form:"..FC.."]c;[form:"..FB.."]r;n"
  if fixCond == cond then return end
  if pcall(RegisterStateDriver, fixHdr, "dmfix", cond) then fixCond = cond end
end

local pending
local function Run(mode)
  if not IsDruid() then P("드루이드 캐릭터에서만 작동해요."); return end
  if InCombatLockdown() then
    pending = mode; P("전투가 끝나면 바로 이어서 할게요."); return
  end
  if mode == "restore" then Restore(); return end
  local ok_n, fail = MakeMacros()
  FixBar()
  if mode == "setup" then
    Backup(); ClearAll(); PlaceAll()
    DruidMacrosDB.placed = true
    BindKeys(true); PlaceSpells(); PlaceExtras()
    P("매크로 "..ok_n.."개를 만들고 단축바 1~= 에 배치했어요. 표범·곰으로 변신해도 같은 숫자키예요.")
    P("원래대로 돌리려면 /dmacro 복구")
  else
    BindKeys()
    PlaceSpells()
    PlaceExtras()
    if fail > 0 then P("매크로 "..fail.."개를 못 만들었어요. 캐릭터 전용 매크로 칸이 꽉 찼을 수 있어요.") end
  end
end

local f = CreateFrame("Frame")
for _, ev in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_LEVEL_UP","LEARNED_SPELL_IN_SKILL_LINE","LEARNED_SPELL_IN_TAB"}) do
  pcall(f.RegisterEvent, f, ev)
end
f:SetScript("OnEvent", function(self, ev)
  DruidMacrosDB = DruidMacrosDB or {}
  if ev == "PLAYER_ENTERING_WORLD" then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    C_Timer.After(3, function()
      if not IsDruid() then return end
      DumpSpells()
      -- 키를 꾹 누르고 있으면 계속 시전
      pcall(function() if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar("ActionButtonUseKeyHeldSpell", "1") elseif SetCVar then SetCVar("ActionButtonUseKeyHeldSpell", "1") end end)
      Run(DruidMacrosDB.placed and "refresh" or "setup")
    end)
  elseif ev == "PLAYER_REGEN_ENABLED" then
    if pending then local m = pending; pending = nil; Run(m) end
  else
    -- 새 기술(광포한 곰, 독 해제 등)을 배우면 매크로 내용만 갱신
    if ev ~= "PLAYER_REGEN_ENABLED" then
      C_Timer.After(1, function() if IsDruid() and DruidMacrosDB.placed then Run("refresh") end end)
    end
  end
end)

SLASH_DRUIDMACROS1 = "/dmacro"
SlashCmdList.DRUIDMACROS = function(msg)
  msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "복구" or msg == "restore" then Run("restore")
  elseif msg == "배치" or msg == "setup" then Run("setup")
  else
    P("/dmacro 배치 : 단축바를 비우고 추천 배치로 다시 놓기")
    P("/dmacro 복구 : 처음 깔기 전 원래 배치로 되돌리기")
  end
end

-- GatherMate2 약초·광맥 데이터 자동 가져오기
local gmf = CreateFrame("Frame")
gmf:RegisterEvent("PLAYER_LOGIN")
gmf:SetScript("OnEvent", function()
  local ok, err = pcall(function()
    if C_AddOns and C_AddOns.EnableAddOn then C_AddOns.EnableAddOn("GatherMate2_Data") end
    if not LibStub or not LibStub("AceAddon-3.0", true) then return end
    local GM = LibStub("AceAddon-3.0"):GetAddon("GatherMate2", true)
    if not GM then return end
    local v = GM.db.profile.importers["GatherMate2_Data"]
    v.Databases.Herbs = true
    v.Databases.Mines = true
    v.autoImport = true
    if (v.lastImport or 0) == 0 then
      GM:GetModule("Config"):CheckAutoImport()
      if (v.lastImport or 0) > 0 then
        print("|cff33ff99[약초지도]|r 약초·광맥 위치를 지도에 넣었어요.")
      else
        print("|cffff5555[약초지도]|r 가져오기 실패: GatherMate2_Data가 꺼져 있을 수 있어요.")
      end
    end
  end)
  if not ok then print("|cffff5555[약초지도]|r 오류: "..tostring(err)) end
end)

-- 약초지도 표시 켜기/끄기 (Shift+M, /약초)
local function HerbToggle()
  local GM = LibStub and LibStub("AceAddon-3.0", true) and LibStub("AceAddon-3.0"):GetAddon("GatherMate2", true)
  if not GM then print("|cffff5555[약초지도]|r GatherMate2가 꺼져 있어요.") return end
  local p = GM.db.profile
  local on = not (p.showMinimap or p.showWorldMap)
  p.showMinimap, p.showWorldMap = on, on
  GM:GetModule("Config"):UpdateConfig()
  print("|cff33ff99[약초지도]|r " .. (on and "표시 켬" or "표시 끔"))
end
SLASH_DMHERB1, SLASH_DMHERB2 = "/약초", "/herb"
SlashCmdList.DMHERB = HerbToggle
local hb = CreateFrame("Button", "DMHerbToggleButton", UIParent)
hb:SetScript("OnClick", HerbToggle)
local hbf = CreateFrame("Frame")
hbf:RegisterEvent("PLAYER_LOGIN")
hbf:SetScript("OnEvent", function()
  if InCombatLockdown() then return end
  for _, key in ipairs({"SHIFT-M", "ALT-M"}) do
    local a = GetBindingAction(key)
    if a == "CLICK DMHerbToggleButton:LeftButton" then return end
    if a == nil or a == "" then
      SetBindingClick(key, "DMHerbToggleButton")
      SaveBindings(GetCurrentBindingSet())
      print("|cff33ff99[약초지도]|r " .. key .. " 키로 약초 표시를 켜고 끌 수 있어요. (/약초 도 돼요)")
      return
    end
  end
end)

-- 자동 루팅 한 번 켜기
local alf = CreateFrame("Frame")
alf:RegisterEvent("PLAYER_LOGIN")
alf:SetScript("OnEvent", function()
  DruidMacrosDB = DruidMacrosDB or {}
  if DruidMacrosDB.autoloot then return end
  pcall(SetCVar, "autoLootDefault", "1")
  DruidMacrosDB.autoloot = true
  print("|cff33ff99[루팅]|r 자동 루팅을 켰어요. Shift를 누른 채 우클릭하면 루팅 창이 떠요.")
end)
