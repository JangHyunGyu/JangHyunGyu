# 와우 포에버 세팅 (장현규)

다른 PC에서는 PowerShell에서 아래 한 줄이면 됩니다. 애드온 목록·버전, 드루이드 매크로, 단축키까지 같게 설치됩니다.

```powershell
irm https://raw.githubusercontent.com/JangHyunGyu/JangHyunGyu/main/wowforever/setup.ps1 | iex
```

- 게임 폴더 `_forever_`를 찾고, 작업내역서의 애드온을 **그날 최신**으로 설치합니다.
- `DruidMacros`는 이 저장소 파일만 씁니다(현재 **5.11**). 매크로와 키 바인딩은 로그인 때 애드온이 적용합니다. 게임이 켜져 있으면 SavedVariables는 건드리지 않습니다.
- 설치 금지: MovementSpeed / WidgetTools, ElvUI / Bartender4 / Dominos, Combo Points Forever / ForeverComboBar, QuestieTrace.

자세한 키 표·버전 이력은 `작업내역서_와우포에버_애드온.md` 4-7절(5.11 키 배치)을 보세요.

## DruidMacros 5.11 키 (요약)

| 키 | 동작 |
|---|---|
| 표범 1 / 2 / 3 / 4 / 5 | 할퀴기 / 갈퀴 / 이빨(Shift 도려내기) / 요정불꽃 / 돌진→칼날 |
| 곰 1 / 2 / 3 / 5 / Z | 후려치기 / 휘둘러치기 / 위협의 포효 / 포효(Shift 돌진) / 가르기 |
| Z | 사람 별빛 섬광, 표범 칼날 발톱, 곰 가르기 |
| Ctrl+Z / Ctrl+Shift+Z | 야생의 징표 / 가시 |
| T | 회복 (Shift 재생, Ctrl 치유의 손길) |
| Q | 항상 표범(물속도). 이미 변신이면 풀고 다시 |
| Shift+Q | 수영 중 바다표범, 아니면 치타 |
| E R F F1 휠클릭 X V | 곰 / 강타·엘룬·손아귀 / 생존기 / 변신해제 / 숨기 / 해제 / 부활 |
| C | 캐릭터 창 |

lua MD5 `3d7c61ef96b77d68d5a19e7243ccf7be` / toc MD5 `c62593dfc25227247e30f127d4e7d2f1`
