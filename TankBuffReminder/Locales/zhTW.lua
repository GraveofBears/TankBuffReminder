-- Locales/zhTW.lua  (繁體中文)
local locale = GetLocale()
if locale ~= "zhTW" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "坦克增益提醒"
L["Select a tab below to configure."] = "選擇下方標籤進行設定。"

L["Buffs"]       = "增益"
L["Appearance"]  = "外觀"
L["Alerts"]      = "警報"
L["Automation"]  = "自動化"
L["Consumables"] = "消耗品"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "僅您的職業區域有效。* 設定施法優先順序（頂部 = 最先顯示）。"

L["Main Bar Appearance"]   = "主列外觀"
L["Glow Size"]             = "光暈大小"
L["Pulse Speed"]           = "脈衝速度"
L["Frame Alpha"]           = "框架透明度"
L["Icon Alpha"]            = "圖示透明度"
L["Button Spacing"]        = "按鈕間距"
L["Glow Color"]            = "光暈顏色"
L["Bar Scale"]             = "列縮放"
L["Buff Sweep Alpha"]      = "增益掃描透明度"
L["Timer Text Alpha"]      = "計時器文字透明度"
L["Text Vertical Offset"]  = "文字垂直偏移"
L["Font Size"]             = "字體大小"
L["Duration Text Color"]   = "持續時間文字顏色"

L["Consumable Bar Appearance"] = "消耗品列外觀"
L["Frame & Border Alpha"]      = "框架和邊框透明度"
L["Icon Alpha (Active)"]       = "圖示透明度（啟用）"
L["Glow Alpha"]                = "光暈透明度"
L["Sweep Alpha"]               = "掃描透明度"
L["Cons Glow Color"]           = "消耗品光暈顏色"
L["Timer Font Size"]           = "計時器字體大小"
L["Timer Y Offset"]            = "計時器Y偏移"
L["Timer Alpha"]               = "計時器透明度"
L["Text Color"]                = "文字顏色"
L["Hide until Mouseover"]      = "滑鼠懸停前隱藏"

L["Buff Alert Sound"]                        = "增益警報聲音"
L["Play sound when a buff is missing"]       = "缺少增益時播放聲音"
L["Missing Buff Sound:"]                     = "缺少增益聲音："
L["Removal Alerts"]                          = "移除警報"
L["Enable removal alert sound (Salv/BoP)"]   = "啟用移除警報聲音（救贖/保護）"
L["Removal Alert Sound:"]                    = "移除警報聲音："
L["Taunt Alert System"]                      = "嘲諷警報系統"
L["Enable Taunt Failure Detection"]          = "啟用嘲諷失敗偵測"
L["Self Warning (chat message)"]             = "自身警告（聊天訊息）"
L["Announce in /Say"]                        = "在/說中宣布"
L["Announce in /Party"]                      = "在/隊伍中宣布"
L["Announce in /Raid"]                       = "在/團隊中宣布"
L["Play sound on taunt failure"]             = "嘲諷失敗時播放聲音"
L["Taunt Failure Sound:"]                    = "嘲諷失敗聲音："
L["Unknown Alert"]                           = "未知警報"

L["Combat Automation"]                          = "戰鬥自動化"
L["Tools"]                                      = "工具"
L["Auto-set Tank Role (5-man groups)"]          = "自動設定坦克角色（5人小隊）"
L["Auto-Repair at Merchant"]                    = "在商人處自動修理"
L["Show Defense Cap button on Character Sheet"] = "在角色面板顯示防禦上限按鈕"
L["Open Defense Cap Chart"]                     = "開啟防禦上限圖表"
L["Chart Frame Color"]                          = "圖表框顏色"
L["Reset All Settings"]                         = "重置所有設定"
L["Caution: This wipes all settings!"]          = "注意：這將清除所有設定！"

L["Auto-remove"] = "自動移除"
L["Show icon"]   = "顯示圖示"
L["Off"]         = "關閉"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00自動移除|r：|cffaaaaaa戰鬥外|r移除增益，|cffaaaaaa戰鬥中|r顯示圖示。\n\n" ..
    "• |cff00ccff顯示圖示|r：僅顯示提醒圖示（從不移除）。\n\n" ..
    "• |cffff5555關閉|r：停用自動移除和圖示。"

L["Blessing of Salvation"]  = "救贖祝福"
L["Blessing of Protection"] = "保護祝福"

L["Consumable Bar"]          = "消耗品列"
L["Show Consumable Bar"]     = "顯示消耗品列"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Shift+拖曳移動列。   |cff999999顏色圖例：|r "
L["Druid-Safe (instant)  "]  = "德魯伊安全（即時）  "
L["Drops Form (cast time)"]  = "脫出形態（施法時間）"
L["CONS_TIMING_NOTE"] =
    "|cffffd100注意：|r 罕見的伺服器時序問題可能偶爾使您停留在施法者形態。"

L["Auto-repair: %s%s%s"]                   = "自動修理：%s%s%s"
L["TAUNT FAILED: "]                         = "嘲諷失敗："
L["[TBR] Defense Chart module not found."] = "[TBR] 未找到防禦圖表模組。"
L["Defense Cap Reference"]                  = "防禦上限參考"
L["Click to view crit-immunity chart."]     = "點擊查看暴擊免疫圖表。"
L["Shift+drag to move."]                    = "Shift+拖曳移動。"

L["Defense Skill"]  = "防禦技能"
L["Rating Needed"]  = "所需評分"
L["Resil Needed"]   = "所需韌性"

L["Druid |cff999999(Survival of the Fittest)|r"] = "德魯伊 |cff999999（適者生存）|r"
L["Warrior"]                                       = "戰士"
L["Paladin"]                                       = "聖騎士"

L["Cannot set hotkeys in combat."]  = "戰鬥中無法設定快捷鍵。"
L["Set Hotkey"]                     = "設定快捷鍵"
L["HOTKEY_PROMPT"] =
    "按任意鍵組合…\n|cff888888Esc取消  •  退格鍵清除|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060已綁定至：\n%s|r\n再次按下覆蓋，Esc取消。"
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800已被使用：\n|cffffffff%s|r\n|cffff8800再次按下確認，Esc取消。|r"
L["Cancel"] = "取消"

L["Total in Bags:"]                                                           = "背包總計："
L["Hotkey:"]                                                                  = "快捷鍵："
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888退格鍵|r清除  •  |cff888888Ctrl+點擊|r重新綁定"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+點擊|r設定快捷鍵"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00熊安全：|r使用後重新進入熊或貓形態。"
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800警告：|r脫出熊形態。"

L["Righteous Fury"]   = "正義之怒"
L["Devotion Aura"]    = "虔誠光環"
L["Battle Shout"]     = "戰鬥怒吼"
L["Commanding Shout"] = "命令怒吼"
L["Defensive Stance"] = "防禦姿態"
L["Thorns"]           = "荊棘"
L["Mark of the Wild"] = "野性印記"
L["Omen of Clarity"]  = "清醒預兆"

L["Recovery"]          = "恢復"
L["Potions"]           = "藥水"
L["Flasks"]            = "藥劑"
L["Guardian Elixirs"]  = "守護者藥劑"
L["Battle Elixirs"]    = "戰鬥藥劑"
L["Scrolls"]           = "卷軸"
L["Weapon"]            = "武器"
L["Engineering"]       = "工程學"
L["Utility"]           = "實用"
L["Food"]              = "食物"
