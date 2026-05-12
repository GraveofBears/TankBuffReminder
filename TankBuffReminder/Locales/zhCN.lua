-- Locales/zhCN.lua  (简体中文)
local locale = GetLocale()
if locale ~= "zhCN" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "坦克增益提醒"
L["Select a tab below to configure."] = "选择下方标签进行配置。"

L["Buffs"]       = "增益"
L["Appearance"]  = "外观"
L["Alerts"]      = "警报"
L["Automation"]  = "自动化"
L["Consumables"] = "消耗品"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "仅您的职业区域有效。* 设置施法优先级（顶部 = 最先显示）。"

L["Main Bar Appearance"]   = "主栏外观"
L["Glow Size"]             = "光晕大小"
L["Pulse Speed"]           = "脉冲速度"
L["Frame Alpha"]           = "框架透明度"
L["Icon Alpha"]            = "图标透明度"
L["Button Spacing"]        = "按钮间距"
L["Glow Color"]            = "光晕颜色"
L["Bar Scale"]             = "栏缩放"
L["Buff Sweep Alpha"]      = "增益扫描透明度"
L["Timer Text Alpha"]      = "计时器文字透明度"
L["Text Vertical Offset"]  = "文字垂直偏移"
L["Font Size"]             = "字体大小"
L["Duration Text Color"]   = "持续时间文字颜色"

L["Consumable Bar Appearance"] = "消耗品栏外观"
L["Frame & Border Alpha"]      = "框架和边框透明度"
L["Icon Alpha (Active)"]       = "图标透明度（激活）"
L["Glow Alpha"]                = "光晕透明度"
L["Sweep Alpha"]               = "扫描透明度"
L["Cons Glow Color"]           = "消耗品光晕颜色"
L["Timer Font Size"]           = "计时器字体大小"
L["Timer Y Offset"]            = "计时器Y偏移"
L["Timer Alpha"]               = "计时器透明度"
L["Text Color"]                = "文字颜色"
L["Hide until Mouseover"]      = "悬停前隐藏"

L["Buff Alert Sound"]                        = "增益警报声音"
L["Play sound when a buff is missing"]       = "缺少增益时播放声音"
L["Missing Buff Sound:"]                     = "缺少增益声音："
L["Removal Alerts"]                          = "移除警报"
L["Enable removal alert sound (Salv/BoP)"]   = "启用移除警报声音（救赎/保护）"
L["Removal Alert Sound:"]                    = "移除警报声音："
L["Taunt Alert System"]                      = "嘲讽警报系统"
L["Enable Taunt Failure Detection"]          = "启用嘲讽失败检测"
L["Self Warning (chat message)"]             = "自身警告（聊天消息）"
L["Announce in /Say"]                        = "在/说中宣布"
L["Announce in /Party"]                      = "在/队伍中宣布"
L["Announce in /Raid"]                       = "在/团队中宣布"
L["Play sound on taunt failure"]             = "嘲讽失败时播放声音"
L["Taunt Failure Sound:"]                    = "嘲讽失败声音："
L["Unknown Alert"]                           = "未知警报"

L["Combat Automation"]                          = "战斗自动化"
L["Tools"]                                      = "工具"
L["Auto-set Tank Role (5-man groups)"]          = "自动设置坦克角色（5人小队）"
L["Auto-Repair at Merchant"]                    = "在商人处自动修理"
L["Show Defense Cap button on Character Sheet"] = "在角色面板显示防御上限按钮"
L["Open Defense Cap Chart"]                     = "打开防御上限图表"
L["Chart Frame Color"]                          = "图表框颜色"
L["Reset All Settings"]                         = "重置所有设置"
L["Caution: This wipes all settings!"]          = "注意：这将清除所有设置！"

L["Auto-remove"] = "自动移除"
L["Show icon"]   = "显示图标"
L["Off"]         = "关闭"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00自动移除|r：|cffaaaaaa战斗外|r移除增益，|cffaaaaaaen战斗中|r显示图标。\n\n" ..
    "• |cff00ccff显示图标|r：仅显示提醒图标（从不移除）。\n\n" ..
    "• |cffff5555关闭|r：禁用自动移除和图标。"

L["Blessing of Salvation"]  = "救赎祝福"
L["Blessing of Protection"] = "保护祝福"

L["Consumable Bar"]          = "消耗品栏"
L["Show Consumable Bar"]     = "显示消耗品栏"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Shift+拖拽移动栏。   |cff999999颜色图例：|r "
L["Druid-Safe (instant)  "]  = "德鲁伊安全（瞬发）  "
L["Drops Form (cast time)"]  = "脱出形态（施法时间）"
L["CONS_TIMING_NOTE"] =
    "|cffffd100注意：|r 罕见的服务器时序问题可能偶尔使您停留在施法者形态。"

L["Auto-repair: %s%s%s"]                   = "自动修理：%s%s%s"
L["TAUNT FAILED: "]                         = "嘲讽失败："
L["[TBR] Defense Chart module not found."] = "[TBR] 未找到防御图表模块。"
L["Defense Cap Reference"]                  = "防御上限参考"
L["Click to view crit-immunity chart."]     = "点击查看暴击免疫图表。"
L["Shift+drag to move."]                    = "Shift+拖拽移动。"

L["Defense Skill"]  = "防御技能"
L["Rating Needed"]  = "所需评分"
L["Resil Needed"]   = "所需韧性"

L["Druid |cff999999(Survival of the Fittest)|r"] = "德鲁伊 |cff999999（适者生存）|r"
L["Warrior"]                                       = "战士"
L["Paladin"]                                       = "圣骑士"

L["Cannot set hotkeys in combat."]  = "战斗中无法设置快捷键。"
L["Set Hotkey"]                     = "设置快捷键"
L["HOTKEY_PROMPT"] =
    "按任意键组合…\n|cff888888Esc取消  •  退格键清除|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060已绑定至：\n%s|r\n再次按下覆盖，Esc取消。"
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800已被使用：\n|cffffffff%s|r\n|cffff8800再次按下确认，Esc取消。|r"
L["Cancel"] = "取消"

L["Total in Bags:"]                                                           = "背包总计："
L["Hotkey:"]                                                                  = "快捷键："
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888退格键|r清除  •  |cff888888Ctrl+点击|r重新绑定"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+点击|r设置快捷键"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00熊安全：|r使用后重新进入熊或猫形态。"
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800警告：|r脱出熊形态。"

L["Righteous Fury"]   = "正义之怒"
L["Devotion Aura"]    = "虔诚光环"
L["Battle Shout"]     = "战斗怒吼"
L["Commanding Shout"] = "命令怒吼"
L["Defensive Stance"] = "防御姿态"
L["Thorns"]           = "荆棘"
L["Mark of the Wild"] = "野性印记"
L["Omen of Clarity"]  = "清醒预兆"

L["Recovery"]          = "恢复"
L["Potions"]           = "药水"
L["Flasks"]            = "药剂"
L["Guardian Elixirs"]  = "守护者药剂"
L["Battle Elixirs"]    = "战斗药剂"
L["Scrolls"]           = "卷轴"
L["Weapon"]            = "武器"
L["Engineering"]       = "工程学"
L["Utility"]           = "实用"
L["Food"]              = "食物"
