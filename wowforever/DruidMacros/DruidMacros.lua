-- DruidMacros 5.12: 드루이드 한글 매크로 자동 생성 + 단축바 자동 배치
local TAG = "|cffff7d0a[드루이드 매크로]|r "
local function P(msg) print(TAG .. msg) end

-- 5.5: 새 PC 첫 접속 직후에는 GetCurrentBindingSet()이 1·2가 아닌 값을 돌려줘 SaveBindings가 오류를 냈다
-- ("Usage: SaveBindings(1|2)"). 값이 정상일 때만 저장하고, 아니면 잠시 뒤 다시 시도한다(최대 5번).
local function SaveB(try)
  if not (SaveBindings and GetCurrentBindingSet) then return end
  local s = GetCurrentBindingSet()
  if s == 1 or s == 2 then pcall(SaveBindings, s); return end
  try = (try or 0) + 1
  if try <= 5 and C_Timer and C_Timer.After then C_Timer.After(5, function() SaveB(try) end) end
end

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
  local FT = Known(783) and FormIndex({783}, nil) or nil -- 5.5: 치타(30렙). 배웠을 때만 실제 폼 번호를 쓴다
  local function F(t) return (t:gsub("form:1/3", "form:"..FB.."/"..FC):gsub("form:1", "form:"..FB):gsub("form:3", "form:"..FC)) end
  local claw, rake, bite, rip = K(1082,"할퀴기"), K(1822,"갈퀴 발톱"), (K(1328618,"흉포한 이빨") or K(22568,"흉포한 이빨")), K(1079,"도려내기")
  local shred, ravage, pounce = K(5221,"칼날 발톱"), K(6785,"찢어발기기"), K(9005,"암습")
  local maul, swipe, demo, growl = K(6807,"후려치기"), K(779,"휘둘러치기"), K(99,"위협의 포효"), K(6795,"포효")
  local bash, enrage, frenzy = K(5211,"강타"), K(5229,"분노"), K(22842,"광포한 재생력")
  -- 포에버 야성의 돌진 특성(1238122). 표범 폼에서는 등 뒤로 도약하는 표범판(414924)으로 바뀐다
  local charge = K(414924,"야성의 돌진") or K(1238122,"야성의 돌진") or K(16979,"야성의 돌진")
  local bearcharge = K(1238122,"야성의 돌진") or K(16979,"야성의 돌진") -- 5.6: 곰판(이동 불가+시전 방해, 15초)
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
  local MOC = "[mod:ctrl,@mouseover,help,nodead][mod:ctrl,help,nodead][mod:ctrl,@player] "
  local T, SA = "#showtooltip\n", "#showtooltip\n/startattack\n"
  -- 5.8: 매크로 24개 → 15개. 1·2·4·5(공격/출혈/요정불꽃/포효)는 폼별 단축바에 주문을 바로 올리므로 매크로가 필요 없었다.
  local list = {
    -- 치유 한 키(T): 기본 회복, Shift 재생, Ctrl 치유의 손길 (마우스오버 대상 → 대상 → 자신)
    {"DM 치유", T..CAST{{MOS,regrowth},{MOC,ht},{MO,rejuv}}},
    {"DM 버프", T..CAST{{"[mod:ctrl,mod:shift,@mouseover,help,nodead][mod:ctrl,mod:shift,help,nodead][mod:ctrl,mod:shift,@player] ",thorns},{"[help,nodead][@player] ",motw}}}, -- Ctrl+Z 야생의 징표, Ctrl+Shift+Z 가시(바 클릭도 징표)
    {"DM 해제", T..CAST{{MOS,poison},{MO,curse}}},                          -- X: 저주 해제, Shift 독 해제
    {"DM 부활", T.."/cast [combat,@mouseover,help,dead][combat] "..(rebirth or "환생").."; [@mouseover,help,dead][] 되살리기"}, -- V
    -- E: 곰. 이미 곰이면 풀고 바로 다시 곰(이동 불가·감속 풀기)
    {"DME 곰", T..(bear and "/cancelform [form:1,nomod:shift]\n" or "")..CAST{{"[mod:shift,form:1] ",nil,true},{"",BANG(bear)}}.."\n/click [nomod] DruidMacrosBarBear", {"E","SHIFT-E"}},
    -- 5.11 Q: 항상 표범(물속도 표범). 이미 표범·바다표범·치타면 풀고 바로 다시 표범. Shift+Q = 수영 중 바다표범, 아니면 치타(여행)
    {"DMQ 표범", T..(cat and ("/cancelform [form:3"..(aquatic and ("/"..FA) or "")..(FT and ("/"..FT) or "")..",nomod:shift]\n") or "")
      ..(((aquatic or travel) and ("/cancelform [form:"..((aquatic and travel and (FA.."/"..FT)) or FA or FT)..",mod:shift]\n") or ""))
      ..CAST{{"[mod:shift,swimming] ",BANG(aquatic)},{"[mod:shift] ",BANG(travel),not travel},{"",BANG(cat)}}
      .."\n/click [mod:shift] DruidMacrosBarOff; [nomod] DruidMacrosBarCat", {"Q","SHIFT-Q"}},
    {"DMR 강타", "#showtooltip\n/startattack [form:1]\n"..CAST{{"[mod:shift,form:1/3] ",grasp},{"[form:1] ",bash},{"[form:3] ",elune},{"[mod:shift] ",elune},{"",grasp}}, {"R","SHIFT-R"}}, -- R 곰 강타/표범 엘룬의 빛/사람 자연의 손아귀, Shift+R 반대
    {"DMF 생존기", T..CAST{{"[form:1,mod:shift] ",frenzy},{"[mod:shift] ",innerv},{"[form:1] ",enrage},{"[form:3] ",dash},{"",bark}}, {"F","SHIFT-F"}}, -- F 곰 분노/표범 질주/사람 나무껍질, Shift+F 곰 광포한 재생력/그 외 정신 자극
    {"DM 변신해제", T.."/cancelform", {"F1"}},
    {"DM 숨기", T..CAST{{"[noform:3] ",BANG(cat)},{"",prowl}}, {"BUTTON3"}}, -- 휠 클릭: 사람·곰이면 표범, 표범이면 숨기, 은신 중 한 번 더 누르면 은신 해제
    {"DM 섬광곰", (ff and moonfire and bear) and (T.."/cancelform [form:1]\n/castsequence reset=target/combat "..ff..", "..moonfire..", "..bear) or ""},
    {"DM 위상", "/ls swap"},
    -- 5번 한 칸 합침(표범·은신·곰): 표범은 등 뒤 돌진 → 한 번 더 누르면 칼날 발톱(없으면 할퀴기), 곰은 포효·Shift 야성의 돌진(특성)
    {"DM 돌진", (function()
      local b = SA
      local any = false
      if (shred or claw) then
        if charge then b = b.."/cast [form:3,harm,nodead] "..charge.."\n" end
        b = b.."/cast [form:3] "..(shred or claw).."\n"; any = true
      end
      local g = CAST{{"[form:1,mod:shift,harm,nodead] ",bearcharge},{"[form:1] ",growl}}
      if g ~= "" then b = b..g.."\n"; any = true end
      return any and b or ""
    end)()},
{"DM 표범마무리", (bite or rip) and (SA..CAST{{"[mod:shift] ",rip},{"",bite or rip}}) or ""}, -- 표범 3: 흉포한 이빨, Shift 도려내기
  }
  for _, m in ipairs(list) do m[2] = F(m[2]) end
  return list
end

-- 배운 주문 목록을 저장(매크로 맞춤용)
local CHECK = {8998,5209,5225,740,1328618,1328617,1259799,2912,2908,20580,437138,1238122,414924,1082,1822,22568,1079,6807,779,99,8921,5176,770,6795,5211,9005,6785,5221,5487,9634,768,783,1066,5215,1850,339,2637,774,8936,5185,1126,467,2782,2893,8946,20484,22812,5229,22842,16689,16857,16979,5570,24858,29166,18960}
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
local OLD = {"DM8 변신","표범공격","표범변신","곰공격","이동변신","MO회복","MO재생","MO뿌리","요정의불꽃","야생의징표","부활",
  "DM1 공격","DM2 출혈","DM3 마무리","DM4 요정불꽃","DM5 포효","DM6 회복","DM7 재생","DM8 생존","DM9 숨기질주","DM0 버프","DM- 해제","DM= 부활","DM 곰포효","DM 돌진발톱","DM 칼날할퀴기"} -- 5.8/5.10: 옛 이름은 지운다
-- 1~12 기본바, 73~84 표범, 85~96 숨기, 97~108 곰, 109~120 달빛야수
local FORM_BASES = {0, 72, 84, 96, 108}
local KEYS = {"1","2","3","4","5","6","7","8","9","0","-","="} -- 칸 이름(도움말·이전 버전 호환)
-- 5.7: 전투 키는 WASD 근처만. 칸 6~8·10~12는 T/G/C/Z/X/V. 칸 9는 키 없음(질주=표범 F, 숨기=휠클릭).
local SLOT_BIND = {"1","2","3","4","5","T",false,"Z",false,false,"X","V"}
-- 5.11: 칸 8 전투(별빛섬광/칼날/가르기)는 Z. 버프(칸 10)는 Ctrl+Z / Ctrl+Shift+Z. C는 비움(캐릭터 창).
local FAR_KEYS = {"6","7","8","9","0","-","="}
local OLD_KEYS = {"G","C"} -- 5.7 G=재생, 5.8~5.10 C=칸8. 둘 다 비움
local function BindSlotKeys()
  local changed = false
  local function act(k)
    local a = GetBindingAction(k)
    return a and a ~= "" and a
  end
  local function clear(k)
    local a = act(k)
    if a and (a:find("^ACTIONBUTTON") or a:find("^ACTIONPAGE") or a:find("ACTIONBAR") or a:find("^MACRO")) then SetBinding(k); changed = true end
  end
  for _, key in ipairs(FAR_KEYS) do clear(key); clear("SHIFT-"..key) end
  for _, key in ipairs(OLD_KEYS) do clear(key); clear("SHIFT-"..key) end
  -- 예전 버프 키 Z·Shift+Z(칸 10)는 이제 칸 8 전투 키라, ACTIONBUTTON10이면 끊는다
  for _, k in ipairs({"Z","SHIFT-Z"}) do
    if act(k) == "ACTIONBUTTON10" then SetBinding(k); changed = true end
  end
  for i, key in ipairs(SLOT_BIND) do
    if key then
      local cmd = "ACTIONBUTTON"..i
      if GetBindingAction(key) ~= cmd then SetBinding(key, cmd); changed = true end
      if GetBindingAction("SHIFT-"..key) ~= cmd then SetBinding("SHIFT-"..key, cmd); changed = true end
    end
  end
  -- Ctrl+T = 치유의 손길(DM 치유 매크로의 [mod:ctrl])
  if GetBindingAction("CTRL-T") ~= "ACTIONBUTTON6" then SetBinding("CTRL-T", "ACTIONBUTTON6"); changed = true end
  -- Ctrl+Z = 야생의 징표, Ctrl+Shift+Z = 가시 (칸 10)
  if GetBindingAction("CTRL-Z") ~= "ACTIONBUTTON10" then SetBinding("CTRL-Z", "ACTIONBUTTON10"); changed = true end
  if GetBindingAction("CTRL-SHIFT-Z") ~= "ACTIONBUTTON10" then SetBinding("CTRL-SHIFT-Z", "ACTIONBUTTON10"); changed = true end
  -- 5.10까지 칸 8이던 C는 기본 캐릭터 창으로 되돌린다
  local ca = GetBindingAction("C")
  if ca == "" or ca == "ACTIONBUTTON8" then SetBinding("C", "TOGGLECHARACTER0"); changed = true end
  return changed
end

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

-- 5.8: 모든 폼 바에 같은 칸으로 놓는 매크로(칸 번호 → 이름). 1~5·8은 폼마다 달라서 아래 SPELLBARS가 맡는다.
local COMMON = {[6]="DM 치유", [10]="DM 버프", [11]="DM 해제", [12]="DM 부활"}
local function PlaceAll()
  for slot, name in pairs(COMMON) do
    local idx = GetMacroIndexByName(name)
    if idx and idx > 0 then
      for _, base in ipairs(FORM_BASES) do
        PickupMacro(idx); PlaceAction(base + slot); ClearCursor()
      end
    end
  end
  -- 1~5와 T/C/Z/X/V만 단축바에 연결(6~0, -, = 와 G는 전투 키에서 제외)
  if BindSlotKeys() then SaveB() end
end

-- 꾹 누르기(연속 시전)는 매크로에선 안 되므로, 연타 스킬은 폼별 단축바에 주문을 직접 올린다.
-- {단축바 시작, {칸번호 = 주문ID}}
local SPELLBARS = {
  {0,   {[1]="DM 섬광곰", [2]=5176, [3]=339,   [4]=770,   [5]=2637, [8]=2912}},  -- 사람: 섬광곰 천벌 뿌리 요정불꽃 겨울잠 / 8 별빛섬광(20렙)
  {72,  {[1]=1082, [2]=1822, [3]="DM 표범마무리", [4]={16857,770}, [5]="DM 돌진", [8]=5221}},    -- 5.10: 1할퀴기(꾹 연타) 2갈퀴 3이빨(Shift 도려내기) 4요정불꽃 5돌진→칼날 8칼날(Z). 칼날→할퀴기 매크로는 포에버에서 할퀴기가 안 나가 제거
  {84,  {[1]={9005,6785,5221,1082}, [2]={{9005,6785},1822,1082}, [3]={5221,1082}, [4]={16857,770}, [5]="DM 돌진", [8]=1822}},    -- 숨기: 1 암습(36렙)·없으면 찢어발기기(32렙) 2 찢어발기기(암습 배운 뒤)·그 전엔 갈퀴 3 칼날발톱 8 갈퀴
  {96,  {[1]=6807, [2]=779, [3]=99, [4]={16857,770}, [5]={{{1238122,16979},"DM 돌진"},6795}, [8]=1328617}}, -- 곰: 1후려치기 2휘둘러치기 3위협의 포효 4요정불꽃 5포효(특성 찍으면 Shift 야성의 돌진) 8가르기(특성)
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
    for _, x in ipairs(id) do
      if type(x) == "table" then -- 5.6: {조건 주문(들), 놓을 것} = 조건 주문을 배웠을 때만
        local req, ok = x[1], false
        for _, r in ipairs(type(req) == "table" and req or {req}) do if Known(r) then ok = true end end
        if ok and (type(x[2]) == "string" or Known(x[2])) then pick = x[2]; break end
      elseif type(x) == "string" or Known(x) then pick = x; break end
    end
    if type(pick) == "table" then pick = pick[#pick] end
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

local BINDV = 10 -- 5.11: Q 항상 표범, Shift+Q 수영=바다표범/아니면 여행, Z=전투, Ctrl+Z 버프
local function BindKeys(force)
  -- 4.3: 지도는 ` 키(사용자 요청). M도 그대로 둔다
  if GetBindingAction("`") ~= "TOGGLEWORLDMAP" then
    SetBinding("`", "TOGGLEWORLDMAP")
    SaveB()
  end
  -- 5.0/5.7: Shift+키는 와우 기본이 단축바 페이지 넘기기인 경우가 있어, 같은 칸 버튼에 묶는다. 6~0, -, = 는 끊고 T/G/C/Z/X/V로 옮긴다.
  if BindSlotKeys() then SaveB() end
  if GetActionBarPage and ChangeActionBarPage and GetActionBarPage() ~= 1 then ChangeActionBarPage(1) end
  if DruidMacrosDB.bindv == BINDV and not force then return end
  for _, m in ipairs(BuildList()) do
    if m[3] then for _, key in ipairs(m[3]) do SetBindingMacro(key, m[1]) end end
  end
  SaveB()
  local first = DruidMacrosDB.bindv ~= BINDV
  DruidMacrosDB.bindv = BINDV
  if first then
    PlaceAll(); PlaceSpells()
    P("레벨에 맞춘 배치로 바꿨어요. 아직 안 배운 스킬은 배우면 자동으로 켜져요.")
    P("전투 키는 WASD 근처에 있어요. 1~5는 꾹 누르면 연타돼요.")
    P("표범 1할퀴기 2갈퀴 3이빨(Shift 도려내기) 4요정불꽃 5돌진→칼날 Z칼날발톱  /  곰 1후려치기 2휘둘러치기 3위협의 포효 5포효(Shift 돌진) Z가르기")
    P("Q 항상 표범(이미 변신 중이면 풀고 다시)  Shift+Q 수영 중 바다표범, 아니면 치타  E 곰  R 곰 강타·표범 엘룬의 빛·사람 자연의 손아귀(Shift+R 반대)  F 분노·질주·나무껍질(Shift 광포한 재생력·정신 자극)  F1 변신해제  휠 클릭 숨기")
    P("T 회복(Shift 재생, Ctrl 치유의 손길)  Z 사람 별빛섬광·표범 칼날발톱·곰 가르기  Ctrl+Z 야생의 징표  Ctrl+Shift+Z 가시  X 저주 해제(Shift 독 해제)  V 환생·되살리기")
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

-- 5.4/5.12 바 수정: Q·E로 폼을 풀고 바로 다시 변신하면(이동 불가·감속 풀기) 포에버가
-- 보너스 바 값을 0으로 남기거나, 같은 상태로 봐서 드라이버가 다시 안 돈다.
-- 5.4는 [bonusbar]가 먼저 맞으면(b) 아무것도 안 했다. CC 중 재변신 뒤에는 [bonusbar]가
-- 한동안 참이거나 이미 b인 채로 클라이언트만 1페이지로 돌아가, _onstate가 안 불린다.
-- UPDATE_* 이벤트에서 actionpage를 바꾸면 전투 중에는 보호 제약이 걸린다.
-- 5.12: (1) 폼·보너스바를 서로 다른 상태 이름으로 나눠 1→0 전환에도 다시 맞춘다.
-- (2) Q/E 매크로 끝의 /click이 보안 핸들러에서 페이지를 다시 넣고, 잠시 폼이
-- 없다고 나와도(holding) 표범 7·은신 8·곰 9를 유지한다. F1 변신해제는 holding이 없다.
-- 상태 이름은 숫자를 쓰면 안 된다(5.3 실패 원인).
local fixHdr, fixCond
local FIX_STATE = [[
local m = self:GetFrameRef("mab")
if not m then return end
local p
if newstate == "s" then p = 8
elseif newstate == "cb" or newstate == "cf" then p = 7
elseif newstate == "rb" or newstate == "rf" then p = 9
elseif newstate == "kb" or newstate == "kf" then p = 10
elseif newstate == "n" then
  if self:GetAttribute("holding") then p = self:GetAttribute("lastpage") or 1 else p = 1 end
else return end
if p and p > 1 then
  self:SetAttribute("lastpage", p)
  if newstate ~= "n" then self:SetAttribute("holding", nil) end
end
m:SetAttribute("actionpage", p)
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
local HOLD_CLICK = [[
local m = self:GetFrameRef("mab")
local hdr = self:GetFrameRef("hdr")
local p = self:GetAttribute("holdpage")
if m and p then m:SetAttribute("actionpage", p) end
if hdr then
  if self:GetAttribute("dohold") and p and p > 1 then
    hdr:SetAttribute("holding", 1)
    hdr:SetAttribute("lastpage", p)
  else
    hdr:SetAttribute("holding", nil)
  end
  hdr:RunAttribute("dmref")
end
]]
local function MakeBarClick(name, page, hold)
  local ok, b = pcall(CreateFrame, "Button", name, UIParent, "SecureHandlerClickTemplate")
  if not ok or not b then return end
  pcall(function() b:RegisterForClicks("AnyUp", "AnyDown") end)
  b:SetAttribute("holdpage", page)
  if hold then b:SetAttribute("dohold", 1) end
  b:SetFrameRef("mab", MainActionBar)
  b:SetFrameRef("hdr", fixHdr)
  b:SetAttribute("_onclick", HOLD_CLICK)
  pcall(function() b:Hide() end)
  return b
end
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
    MakeBarClick("DruidMacrosBarCat", 7, true)
    MakeBarClick("DruidMacrosBarBear", 9, true)
    MakeBarClick("DruidMacrosBarOff", 1, false)
  end
  local FB = FormIndex({5487, 9634}, "1")
  local FC = FormIndex({768}, "3")
  -- bonusbar:N 과 form:FC 를 다른 이름(cb/cf)으로 둬야, 보너스만 0으로 떨어져도 핸들러가 다시 돈다
  local cond = "[form:"..FC..",stealth]s;[bonusbar:2]s;[bonusbar:1]cb;[form:"..FC.."]cf;[bonusbar:3]rb;[form:"..FB.."]rf"
  local FK = FormIndex({24858}, nil)
  if FK then cond = cond..";[bonusbar:4]kb;[form:"..FK.."]kf" end
  cond = cond..";n"
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
      -- 5.5: Lua 오류 팝업 끄기(사용자 요청). 다른 애드온의 일회성 오류가 화면을 가리지 않게 한다. 다시 보려면 /console scriptErrors 1
      pcall(function() if C_CVar and C_CVar.SetCVar then C_CVar.SetCVar("scriptErrors", "0") elseif SetCVar then SetCVar("scriptErrors", "0") end end)
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
      SaveB()
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
