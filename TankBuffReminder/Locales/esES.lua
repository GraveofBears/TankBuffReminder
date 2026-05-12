-- Locales/esES.lua  (Español — also covers esMX)
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = TBR_L

L["Tank Buff Reminder"]                = "Recordatorio de Buffs de Tanque"
L["Select a tab below to configure."] = "Selecciona una pestaña para configurar."

L["Buffs"]       = "Buffs"
L["Appearance"]  = "Apariencia"
L["Alerts"]      = "Alertas"
L["Automation"]  = "Automatización"
L["Consumables"] = "Consumibles"

L["Only your class section is active.  * sets cast priority (top = first shown)."] =
    "Solo tu sección de clase está activa.  * establece la prioridad de lanzamiento (arriba = primero mostrado)."

L["Main Bar Appearance"]   = "Apariencia de la barra principal"
L["Glow Size"]             = "Tamaño del brillo"
L["Pulse Speed"]           = "Velocidad de pulso"
L["Frame Alpha"]           = "Alpha del marco"
L["Icon Alpha"]            = "Alpha del icono"
L["Button Spacing"]        = "Espaciado de botones"
L["Glow Color"]            = "Color del brillo"
L["Bar Scale"]             = "Escala de la barra"
L["Buff Sweep Alpha"]      = "Alpha del barrido de buff"
L["Timer Text Alpha"]      = "Alpha del texto del temporizador"
L["Text Vertical Offset"]  = "Desplazamiento vertical del texto"
L["Font Size"]             = "Tamaño de fuente"
L["Duration Text Color"]   = "Color del texto de duración"

L["Consumable Bar Appearance"] = "Apariencia de la barra de consumibles"
L["Frame & Border Alpha"]      = "Alpha del marco y borde"
L["Icon Alpha (Active)"]       = "Alpha del icono (Activo)"
L["Glow Alpha"]                = "Alpha del brillo"
L["Sweep Alpha"]               = "Alpha del barrido"
L["Cons Glow Color"]           = "Color brillo (consumibles)"
L["Timer Font Size"]           = "Tamaño de fuente del temporizador"
L["Timer Y Offset"]            = "Desplazamiento Y del temporizador"
L["Timer Alpha"]               = "Alpha del temporizador"
L["Text Color"]                = "Color del texto"
L["Hide until Mouseover"]      = "Ocultar hasta pasar el ratón"

L["Buff Alert Sound"]                        = "Sonido de alerta de buff"
L["Play sound when a buff is missing"]       = "Reproducir sonido cuando falta un buff"
L["Missing Buff Sound:"]                     = "Sonido de buff faltante:"
L["Removal Alerts"]                          = "Alertas de eliminación"
L["Enable removal alert sound (Salv/BoP)"]   = "Activar sonido de alerta de eliminación (Salv/BoP)"
L["Removal Alert Sound:"]                    = "Sonido de alerta de eliminación:"
L["Taunt Alert System"]                      = "Sistema de alerta de provocación"
L["Enable Taunt Failure Detection"]          = "Activar detección de fallo de provocación"
L["Self Warning (chat message)"]             = "Aviso propio (mensaje de chat)"
L["Announce in /Say"]                        = "Anunciar en /Decir"
L["Announce in /Party"]                      = "Anunciar en /Grupo"
L["Announce in /Raid"]                       = "Anunciar en /Banda"
L["Play sound on taunt failure"]             = "Reproducir sonido al fallar provocación"
L["Taunt Failure Sound:"]                    = "Sonido de fallo de provocación:"
L["Unknown Alert"]                           = "Alerta desconocida"

L["Combat Automation"]                          = "Automatización en combate"
L["Tools"]                                      = "Herramientas"
L["Auto-set Tank Role (5-man groups)"]          = "Establecer rol de tanque automáticamente (grupos de 5)"
L["Auto-Repair at Merchant"]                    = "Reparar automáticamente con el mercader"
L["Show Defense Cap button on Character Sheet"] = "Mostrar botón del límite de defensa"
L["Open Defense Cap Chart"]                     = "Abrir tabla del límite de defensa"
L["Chart Frame Color"]                          = "Color del marco de la tabla"
L["Reset All Settings"]                         = "Restablecer toda la configuración"
L["Caution: This wipes all settings!"]          = "¡Cuidado: Esto borra toda la configuración!"

L["Auto-remove"] = "Eliminar auto"
L["Show icon"]   = "Mostrar icono"
L["Off"]         = "Desactivado"

L["AUTOMATION_NOTE"] =
    "• |cff00ff00Eliminar auto|r: Elimina el buff |cffaaaaaa fuera de combate|r, muestra icono |cffaaaaaaen combate|r.\n\n" ..
    "• |cff00ccffMostrar icono|r: Solo muestra el icono recordatorio (nunca elimina).\n\n" ..
    "• |cffff5555Desactivado|r: Desactiva la eliminación auto y el icono."

L["Blessing of Salvation"]  = "Bendición de Salvación"
L["Blessing of Protection"] = "Bendición de Protección"

L["Consumable Bar"]          = "Barra de consumibles"
L["Show Consumable Bar"]     = "Mostrar barra de consumibles"
L["Shift+drag the bar to move.   |cff999999Color Legend:|r "] =
    "Mayús+Arrastrar para mover.   |cff999999Leyenda de colores:|r "
L["Druid-Safe (instant)  "]  = "Seguro para Druida (instantáneo)  "
L["Drops Form (cast time)"]  = "Sale de Forma (tiempo de lanzamiento)"
L["CONS_TIMING_NOTE"] =
    "|cffffd100Nota:|r Raros problemas de sincronía del servidor pueden ocasionalmente dejarte en forma de lanzador."

L["Auto-repair: %s%s%s"]                   = "Reparación auto: %s%s%s"
L["TAUNT FAILED: "]                         = "PROVOCACIÓN FALLIDA: "
L["[TBR] Defense Chart module not found."] = "[TBR] Módulo de tabla de defensa no encontrado."
L["Defense Cap Reference"]                  = "Referencia del límite de defensa"
L["Click to view crit-immunity chart."]     = "Clic para ver la tabla de inmunidad crítica."
L["Shift+drag to move."]                    = "Mayús+Arrastrar para mover."

L["Defense Skill"]  = "Habilidad de defensa"
L["Rating Needed"]  = "Valor necesario"
L["Resil Needed"]   = "Resil. necesaria"

L["Druid |cff999999(Survival of the Fittest)|r"] = "Druida |cff999999(Supervivencia del más apto)|r"
L["Warrior"]                                       = "Guerrero"
L["Paladin"]                                       = "Paladín"

L["Cannot set hotkeys in combat."]  = "No se pueden asignar atajos en combate."
L["Set Hotkey"]                     = "Asignar atajo"
L["HOTKEY_PROMPT"] =
    "Pulsa una combinación de teclas…\n|cff888888Esc para cancelar  •  Retroceso para borrar|r"
L["HOTKEY_CONFLICT_ADDON"] =
    "|cffff6060Ya asignado a:\n%s|r\nPulsa de nuevo para sobrescribir, Esc para cancelar."
L["HOTKEY_CONFLICT_WOW"] =
    "|cffff8800Ya utilizado por:\n|cffffffff%s|r\n|cffff8800Pulsa de nuevo para confirmar, Esc para cancelar.|r"
L["Cancel"] = "Cancelar"

L["Total in Bags:"]                                                           = "Total en bolsas:"
L["Hotkey:"]                                                                  = "Atajo:"
L["|cff888888Backspace|r to clear  •  |cff888888Ctrl+Click|r to rebind"]     =
    "|cff888888Retroceso|r para borrar  •  |cff888888Ctrl+Clic|r para reasignar"
L["|cff888888Ctrl+Click|r to set a hotkey"]                                   =
    "|cff888888Ctrl+Clic|r para asignar un atajo"
L["|cff00ff00Bear-safe:|r re-enters Bear or Cat Form after use."]             =
    "|cff00ff00Seguro para oso:|r Vuelve a Forma de Oso o Gato tras el uso."
L["|cffff8800Warning:|r drops Bear Form."]                                    =
    "|cffff8800Aviso:|r Sale de la Forma de Oso."

L["Righteous Fury"]   = "Furia Justa"
L["Devotion Aura"]    = "Aura de Devoción"
L["Battle Shout"]     = "Grito de Batalla"
L["Commanding Shout"] = "Grito de Mando"
L["Defensive Stance"] = "Postura Defensiva"
L["Thorns"]           = "Espinas"
L["Mark of the Wild"] = "Marca de lo Salvaje"
L["Omen of Clarity"]  = "Presagio de Claridad"

L["Recovery"]          = "Recuperación"
L["Potions"]           = "Pociones"
L["Flasks"]            = "Frascos"
L["Guardian Elixirs"]  = "Elixires de guardián"
L["Battle Elixirs"]    = "Elixires de batalla"
L["Scrolls"]           = "Pergaminos"
L["Weapon"]            = "Arma"
L["Engineering"]       = "Ingeniería"
L["Utility"]           = "Utilidad"
L["Food"]              = "Comida"
