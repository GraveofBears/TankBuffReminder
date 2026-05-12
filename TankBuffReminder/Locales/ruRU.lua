-- Locales/ruRU.lua  (Русский)
local locale = GetLocale()
if locale ~= "ruRU" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "Напоминание о баффах танка"
L["Select a tab below to configure."] = "Выберите вкладку для настройки."

L["Buffs"]       = "Баффы"
L["Appearance"]  = "Внешний вид"
L["Alerts"]      = "Оповещения"
L["Automation"]  = "Автоматизация"
L["Consumables"] = "Расходники"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "Активен только раздел вашего класса.  * устанавливает приоритет применения (вверху = показывается первым)."

L["Main Bar Appearance"]   = "Внешний вид главной панели"
L["Glow Size"]             = "Размер свечения"
L["Pulse Speed"]           = "Скорость пульсации"
L["Frame Alpha"]           = "Прозрачность рамки"
L["Icon Alpha"]            = "Прозрачность иконки"
L["Button Spacing"]        = "Расстояние между кнопками"
L["Glow Color"]            = "Цвет свечения"
L["Bar Scale"]             = "Масштаб панели"
L["Buff Sweep Alpha"]      = "Прозрачность развёртки баффа"
L["Timer Text Alpha"]      = "Прозрачность текста таймера"
L["Text Vertical Offset"]  = "Вертикальное смещение текста"
L["Font Size"]             = "Размер шрифта"
L["Duration Text Color"]   = "Цвет текста длительности"

L["Consumable Bar Appearance"] = "Внешний вид панели расходников"
L["Frame & Border Alpha"]      = "Прозрачность рамки и границы"
L["Icon Alpha (Active)"]       = "Прозрачность иконки (Активная)"
L["Glow Alpha"]                = "Прозрачность свечения"
L["Sweep Alpha"]               = "Прозрачность развёртки"
L["Cons Glow Color"]           = "Цвет свечения (расходники)"
L["Timer Font Size"]           = "Размер шрифта таймера"
L["Timer Y Offset"]            = "Смещение Y таймера"
L["Timer Alpha"]               = "Прозрачность таймера"
L["Text Color"]                = "Цвет текста"
L["Hide until Mouseover"]      = "Скрывать до наведения курсора"

L["Buff Alert Sound"]                        = "Звук оповещения о баффе"
L["Play sound when a buff is missing"]       = "Воспроизводить звук при отсутствии баффа"
L["Missing Buff Sound:"]                     = "Звук отсутствия баффа:"
L["Removal Alerts"]                          = "Оповещения об удалении"
L["Enable removal alert sound (Salv/BoP)"]   = "Включить звук оповещения об удалении (Salv/BoP)"
L["Removal Alert Sound:"]                    = "Звук оповещения об удалении:"
L["Taunt Alert System"]                      = "Система оповещения о провокации"
L["Enable Taunt Failure Detection"]          = "Включить обнаружение неудачной провокации"
L["Self Warning (chat message)"]             = "Личное предупреждение (сообщение в чате)"
L["Announce in /Say"]                        = "Объявить в /Сказать"
L["Announce in /Party"]                      = "Объявить в /Группа"
L["Announce in /Raid"]                       = "Объявить в /Рейд"
L["Play sound on taunt failure"]             = "Воспроизводить звук при неудаче провокации"
L["Taunt Failure Sound:"]                    = "Звук неудачной провокации:"
L["Unknown Alert"]                           = "Неизвестное оповещение"

L["Combat Automation"]                          = "Автоматизация в бою"
L["Tools"]                                      = "Инструменты"
L["Auto-set Tank Role (5-man groups)"]          = "Авто-установка роли танка (группы по 5)"
L["Auto-Repair at Merchant"]                    = "Авторемонт у торговца"
L["Show Defense Cap button on Character Sheet"] = "Показать кнопку предела защиты"
L["Open Defense Cap Chart"]                     = "Открыть таблицу предела защиты"
L["Chart Frame Color"]                          = "Цвет рамки таблицы"
L["Reset All Settings"]                         = "Сбросить все настройки"
L["Caution: This wipes all settings!"]          = "Осторожно: Это удалит все настройки!"

L["Auto-remove"] = "Авто-удаление"
L["Show icon"]   = "Показать иконку"
L["Off"]         = "Выкл"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00Авто-удаление|r: Удаляет бафф |cffaaaaaaaвне боя|r, показывает иконку |cffaaaaaaв бою|r.\n\n" ..
    "• |cff00ccffПоказать иконку|r: Показывает только иконку напоминания (никогда не удаляет).\n\n" ..
    "• |cffff5555Выкл|r: Отключает авто-удаление и иконку."

L["Blessing of Salvation"]  = "Благословение Спасения"
L["Blessing of Protection"] = "Благословение Защиты"

L["Consumable Bar"]          = "Панель расходников"
L["Show Consumable Bar"]     = "Показать панель расходников"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Shift+перетащить для перемещения.   |cff999999Легенда цветов:|r "
L["Druid-Safe (instant)  "]  = "Безопасно для друида (мгновенно)  "
L["Drops Form (cast time)"]  = "Снимает форму (время применения)"
L["CONS_TIMING_NOTE"] =
    "|cffffd100Примечание:|r Редкие проблемы с синхронизацией сервера могут иногда оставить вас в форме заклинателя."

L["Auto-repair: %s%s%s"]                   = "Авторемонт: %s%s%s"
L["TAUNT FAILED: "]                         = "ПРОВОКАЦИЯ ПРОВАЛЕНА: "
L["[TBR] Defense Chart module not found."] = "[TBR] Модуль таблицы защиты не найден."
L["Defense Cap Reference"]                  = "Справочник предела защиты"
L["Click to view crit-immunity chart."]     = "Нажмите для просмотра таблицы иммунитета к крит. ударам."
L["Shift+drag to move."]                    = "Shift+перетащить для перемещения."

L["Defense Skill"]  = "Навык защиты"
L["Rating Needed"]  = "Нужный рейтинг"
L["Resil Needed"]   = "Нужная стойкость"

L["Druid |cff999999(Survival of the Fittest)|r"] = "Друид |cff999999(Выживание сильнейшего)|r"
L["Warrior"]                                       = "Воин"
L["Paladin"]                                       = "Паладин"

L["Cannot set hotkeys in combat."]  = "Невозможно задать горячие клавиши в бою."
L["Set Hotkey"]                     = "Задать горячую клавишу"
L["HOTKEY_PROMPT"] =
    "Нажмите любую комбинацию клавиш…\n|cff888888Esc для отмены  •  Backspace для очистки|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060Уже назначено на:\n%s|r\nНажмите ещё раз для замены, Esc для отмены."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800Уже используется:\n|cffffffff%s|r\n|cffff8800Нажмите ещё раз для подтверждения, Esc для отмены.|r"
L["Cancel"] = "Отмена"

L["Total in Bags:"]                                                           = "Всего в сумках:"
L["Hotkey:"]                                                                  = "Горячая клавиша:"
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888Backspace|r для очистки  •  |cff888888Ctrl+Клик|r для переназначения"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+Клик|r для назначения горячей клавиши"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00Безопасно для медведя:|r Повторно входит в форму Медведя или Кота после использования."
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800Предупреждение:|r Выходит из формы Медведя."

L["Righteous Fury"]   = "Праведный Гнев"
L["Devotion Aura"]    = "Аура Преданности"
L["Battle Shout"]     = "Боевой Клич"
L["Commanding Shout"] = "Командный Клич"
L["Defensive Stance"] = "Защитная Стойка"
L["Thorns"]           = "Шипы"
L["Mark of the Wild"] = "Метка Дикой Природы"
L["Omen of Clarity"]  = "Предзнаменование Ясности"

L["Recovery"]          = "Восстановление"
L["Potions"]           = "Зелья"
L["Flasks"]            = "Флаконы"
L["Guardian Elixirs"]  = "Защитные эликсиры"
L["Battle Elixirs"]    = "Боевые эликсиры"
L["Scrolls"]           = "Свитки"
L["Weapon"]            = "Оружие"
L["Engineering"]       = "Инженерное дело"
L["Utility"]           = "Утилиты"
L["Food"]              = "Еда"
