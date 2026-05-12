-- Locales/koKR.lua  (한국어)
local locale = GetLocale()
if locale ~= "koKR" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "탱크 버프 알림"
L["Select a tab below to configure."] = "아래 탭을 선택하여 설정하세요."

L["Buffs"]       = "버프"
L["Appearance"]  = "모양"
L["Alerts"]      = "경보"
L["Automation"]  = "자동화"
L["Consumables"] = "소모품"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "자신의 직업 섹션만 활성화됩니다.  * 시전 우선순위 설정 (상단 = 먼저 표시)."

L["Main Bar Appearance"]   = "메인 바 외관"
L["Glow Size"]             = "발광 크기"
L["Pulse Speed"]           = "펄스 속도"
L["Frame Alpha"]           = "프레임 투명도"
L["Icon Alpha"]            = "아이콘 투명도"
L["Button Spacing"]        = "버튼 간격"
L["Glow Color"]            = "발광 색상"
L["Bar Scale"]             = "바 크기"
L["Buff Sweep Alpha"]      = "버프 스윕 투명도"
L["Timer Text Alpha"]      = "타이머 텍스트 투명도"
L["Text Vertical Offset"]  = "텍스트 수직 오프셋"
L["Font Size"]             = "글꼴 크기"
L["Duration Text Color"]   = "지속 시간 텍스트 색상"

L["Consumable Bar Appearance"] = "소모품 바 외관"
L["Frame & Border Alpha"]      = "프레임 및 테두리 투명도"
L["Icon Alpha (Active)"]       = "아이콘 투명도 (활성)"
L["Glow Alpha"]                = "발광 투명도"
L["Sweep Alpha"]               = "스윕 투명도"
L["Cons Glow Color"]           = "소모품 발광 색상"
L["Timer Font Size"]           = "타이머 글꼴 크기"
L["Timer Y Offset"]            = "타이머 Y 오프셋"
L["Timer Alpha"]               = "타이머 투명도"
L["Text Color"]                = "텍스트 색상"
L["Hide until Mouseover"]      = "마우스 오버까지 숨기기"

L["Buff Alert Sound"]                        = "버프 경보 사운드"
L["Play sound when a buff is missing"]       = "버프가 없을 때 사운드 재생"
L["Missing Buff Sound:"]                     = "버프 없음 사운드:"
L["Removal Alerts"]                          = "제거 경보"
L["Enable removal alert sound (Salv/BoP)"]   = "제거 경보 사운드 활성화 (살베이션/보호)"
L["Removal Alert Sound:"]                    = "제거 경보 사운드:"
L["Taunt Alert System"]                      = "도발 경보 시스템"
L["Enable Taunt Failure Detection"]          = "도발 실패 감지 활성화"
L["Self Warning (chat message)"]             = "자신 경고 (채팅 메시지)"
L["Announce in /Say"]                        = "/말하기에서 알림"
L["Announce in /Party"]                      = "/파티에서 알림"
L["Announce in /Raid"]                       = "/공격대에서 알림"
L["Play sound on taunt failure"]             = "도발 실패 시 사운드 재생"
L["Taunt Failure Sound:"]                    = "도발 실패 사운드:"
L["Unknown Alert"]                           = "알 수 없는 경보"

L["Combat Automation"]                          = "전투 자동화"
L["Tools"]                                      = "도구"
L["Auto-set Tank Role (5-man groups)"]          = "탱크 역할 자동 설정 (5인 그룹)"
L["Auto-Repair at Merchant"]                    = "상인에서 자동 수리"
L["Show Defense Cap button on Character Sheet"] = "캐릭터 시트에 방어 상한 버튼 표시"
L["Open Defense Cap Chart"]                     = "방어 상한 차트 열기"
L["Chart Frame Color"]                          = "차트 프레임 색상"
L["Reset All Settings"]                         = "모든 설정 초기화"
L["Caution: This wipes all settings!"]          = "주의: 모든 설정이 삭제됩니다!"

L["Auto-remove"] = "자동 제거"
L["Show icon"]   = "아이콘 표시"
L["Off"]         = "끄기"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00자동 제거|r: |cffaaaaaa전투 외|r에서 버프 제거, |cffaaaaaa전투 중|r 아이콘 표시.\n\n" ..
    "• |cff00ccff아이콘 표시|r: 알림 아이콘만 표시 (제거하지 않음).\n\n" ..
    "• |cffff5555끄기|r: 자동 제거 및 아이콘 비활성화."

L["Blessing of Salvation"]  = "구원의 축복"
L["Blessing of Protection"] = "보호의 축복"

L["Consumable Bar"]          = "소모품 바"
L["Show Consumable Bar"]     = "소모품 바 표시"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Shift+드래그로 이동.   |cff999999색상 범례:|r "
L["Druid-Safe (instant)  "]  = "드루이드 안전 (즉시)  "
L["Drops Form (cast time)"]  = "변신 해제 (시전 시간)"
L["CONS_TIMING_NOTE"] =
    "|cffffd100참고:|r 드문 서버 타이밍 문제로 인해 가끔 캐스터 형태로 남아있을 수 있습니다."

L["Auto-repair: %s%s%s"]                   = "자동 수리: %s%s%s"
L["TAUNT FAILED: "]                         = "도발 실패: "
L["[TBR] Defense Chart module not found."] = "[TBR] 방어 차트 모듈을 찾을 수 없습니다."
L["Defense Cap Reference"]                  = "방어 상한 참조"
L["Click to view crit-immunity chart."]     = "치명타 면역 차트를 보려면 클릭하세요."
L["Shift+drag to move."]                    = "Shift+드래그로 이동."

L["Defense Skill"]  = "방어 스킬"
L["Rating Needed"]  = "필요 평점"
L["Resil Needed"]   = "필요 회복력"

L["Druid |cff999999(Survival of the Fittest)|r"] = "드루이드 |cff999999(적자생존)|r"
L["Warrior"]                                       = "전사"
L["Paladin"]                                       = "성기사"

L["Cannot set hotkeys in combat."]  = "전투 중 단축키를 설정할 수 없습니다."
L["Set Hotkey"]                     = "단축키 설정"
L["HOTKEY_PROMPT"] =
    "키 조합을 누르세요…\n|cff888888Esc 취소  •  백스페이스 지우기|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060이미 바인딩됨:\n%s|r\n다시 누르면 덮어쓰기, Esc 취소."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800이미 사용 중:\n|cffffffff%s|r\n|cffff8800다시 누르면 확인, Esc 취소.|r"
L["Cancel"] = "취소"

L["Total in Bags:"]                                                           = "가방 총계:"
L["Hotkey:"]                                                                  = "단축키:"
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888백스페이스|r 지우기  •  |cff888888Ctrl+클릭|r 재바인딩"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+클릭|r 단축키 설정"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00곰 안전:|r 사용 후 곰 또는 고양이 형태로 다시 들어갑니다."
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800경고:|r 곰 형태를 해제합니다."

L["Righteous Fury"]   = "신성한 분노"
L["Devotion Aura"]    = "헌신의 오라"
L["Battle Shout"]     = "전투의 함성"
L["Commanding Shout"] = "명령의 함성"
L["Defensive Stance"] = "수비 자세"
L["Thorns"]           = "가시"
L["Mark of the Wild"] = "야생의 표식"
L["Omen of Clarity"]  = "명료함의 전조"

L["Recovery"]          = "회복"
L["Potions"]           = "물약"
L["Flasks"]            = "플라스크"
L["Guardian Elixirs"]  = "수호 엘릭서"
L["Battle Elixirs"]    = "전투 엘릭서"
L["Scrolls"]           = "두루마리"
L["Weapon"]            = "무기"
L["Engineering"]       = "공학"
L["Utility"]           = "유틸리티"
L["Food"]              = "음식"
