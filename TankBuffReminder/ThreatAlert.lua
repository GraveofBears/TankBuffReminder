-- ThreatAlert.lua
local L = TBR_L

-- Upvalues
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID
local GetTime = GetTime
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local SendChatMessage = SendChatMessage
local PlaySound = PlaySound
local C_Timer = C_Timer

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local MSG_PREFIX = "|cFFFF6600[TBR]|r "
local SPAM_THROTTLE = 3.0
local DEFAULT_WINDOW = 5

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
local playerGUID = nil
local pvpShield = false
local inCombat = false
local combatStartTime = 0
local lastAlertTime = 0
local isThrottling = false

local eventBuffer = {}
local formattedLines = {}
local dedupHash = {}

-- Active CC tracking to avoid spam
local activeCCs = {}

-- Per-spell last-alert timestamps. Prevents AoE abilities (Demo Shout, Consecration,
-- Swipe, Cleave, etc.) from flooding alerts by firing once per spellID per SPAM_THROTTLE.
local spellAlertCooldowns = {}

-------------------------------------------------------------------------------
-- Categories: CC, Root, Silence, Disarm, Snare
-------------------------------------------------------------------------------
local CC_SPELLS = {
    -- ── Druid ──────────────────────────────────────────────────────────────
    -- Roots
    [339]   = "Root",  [1062]  = "Root",  [5195]  = "Root",  [5196]  = "Root",  -- Entangling Roots r1-4
    [9852]  = "Root",  [9853]  = "Root",  [26989] = "Root",                      -- Entangling Roots r5-7
    [19975] = "Root",  [19974] = "Root",  [19973] = "Root",  [19972] = "Root",  -- Nature's Grasp r1-4
    [19971] = "Root",  [19970] = "Root",  [27010] = "Root",                      -- Nature's Grasp r5-7
    [19675] = "Root",  [45334] = "Root",                                          -- Feral Charge Effect
    -- Stun
    [9005]  = "Stun", [9823]  = "Stun", [9827]  = "Stun", [27006] = "Stun",  -- Pounce r1-4
    [5211]  = "Stun", [6798]  = "Stun", [8983]  = "Stun",                    -- Bash r1-3
    [22570] = "Stun",  -- Maim
    [16922] = "Stun",  -- Starfire Stun
    -- Incapacitate
    [2637]  = "Incap", [18657] = "Incap", [18658] = "Incap",  -- Hibernate r1-3
    [33786] = "Incap",  -- Cyclone

    -- ── Hunter ─────────────────────────────────────────────────────────────
    -- Fear
    [1513]  = "Fear", [14326] = "Fear", [14327] = "Fear",   -- Scare Beast r1-3
    -- Incapacitate
    [3355]  = "Incap", [14308] = "Incap", [14309] = "Incap",  -- Freezing Trap r1-3
    [19386] = "Incap", [24132] = "Incap", [24133] = "Incap", [27068] = "Incap",  -- Wyvern Sting r1-4
    [19503] = "Incap",  -- Scatter Shot
    -- Stun
    [19410] = "Stun", [28445] = "Stun",  -- Improved Concussive Shot
    [24394] = "Stun",  -- Intimidation
    -- Silence
    [34490] = "Silence",  -- Silencing Shot
    -- Root
    [19306] = "Root", [20909] = "Root", [20910] = "Root", [27067] = "Root",  -- Counterattack r1-4
    [19229] = "Root",  -- Improved Wing Clip
    [19185] = "Root",  -- Entrapment
    [4167]  = "Root", [4168] = "Root", [4169] = "Root",  -- Spider Web r1-3
    [25999] = "Root",  -- Boar Charge
    -- Snare
    [2974]  = "Snare", [14267] = "Snare", [14268] = "Snare",  -- Wing Clip r1-3
    [5116]  = "Snare",  -- Concussive Shot
    [15571] = "Snare",  -- Dazed (Aspect of the Cheetah/Pack)
    [13809] = "Snare", [13810] = "Snare",  -- Frost Trap / Frost Trap Aura
    [35101] = "Snare",  -- Concussive Barrage

    -- ── Mage ───────────────────────────────────────────────────────────────
    -- Polymorph
    [118]   = "Poly", [12824] = "Poly", [12825] = "Poly", [12826] = "Poly",  -- Polymorph r1-4
    [28271] = "Poly", [28272] = "Poly",  -- Polymorph: Turtle / Pig
    -- Stun
    [12355] = "Stun",  -- Impact
    [31661] = "Stun", [33041] = "Stun", [33042] = "Stun", [33043] = "Stun",  -- Dragon's Breath r1-4
    -- Silence
    [18469] = "Silence",  -- Counterspell - Silenced (Improved Counterspell)
    -- Root
    [122]   = "Root", [865]   = "Root", [6131]  = "Root", [10230] = "Root", [27088] = "Root",  -- Frost Nova r1-5
    [12494] = "Root",  -- Frostbite
    [33395] = "Root",  -- Water Elemental Freeze
    -- Snare
    [12484] = "Snare", [12485] = "Snare", [12486] = "Snare",  -- Chilled (Improved Blizzard) r1-3
    [120]   = "Snare", [8492]  = "Snare", [10159] = "Snare", [10160] = "Snare", [10161] = "Snare", [27087] = "Snare",  -- Cone of Cold r1-6
    [116]   = "Snare", [205]   = "Snare", [837]   = "Snare", [7322]  = "Snare", [8406]  = "Snare", [8407]  = "Snare",  -- Frostbolt r1-6
    [8408]  = "Snare", [10179] = "Snare", [10180] = "Snare", [10181] = "Snare", [25304] = "Snare", [27071] = "Snare",  -- Frostbolt r7-12
    [27072] = "Snare", [38697] = "Snare",  -- Frostbolt r13-14
    [11113] = "Snare", [13018] = "Snare", [13019] = "Snare", [13020] = "Snare", [13021] = "Snare", [27133] = "Snare", [33933] = "Snare",  -- Blast Wave r1-7
    [31589] = "Snare",  -- Slow

    -- ── Paladin ────────────────────────────────────────────────────────────
    -- Stun
    [853]   = "Stun", [5588]  = "Stun", [5589]  = "Stun", [10308] = "Stun",  -- Hammer of Justice r1-4
    [20170] = "Stun",  -- Stun (Seal of Justice)
    -- Incapacitate
    [20066] = "Incap",  -- Repentance
    -- Fear
    [2878]  = "Fear", [5627]  = "Fear", [10326] = "Fear",  -- Turn Undead r1-2 / Turn Evil
    -- Snare
    [31935] = "Snare", [32699] = "Snare", [32700] = "Snare",  -- Avenger's Shield r1-3

    -- ── Priest ─────────────────────────────────────────────────────────────
    -- Silence
    [15487] = "Silence",  -- Silence (talent)
    -- Stun
    [15269] = "Stun",  -- Blackout
    -- Mind Control
    [605]   = "MC", [10911] = "MC", [10912] = "MC",  -- Mind Control r1-3
    -- Fear
    [8122]  = "Fear", [8124]  = "Fear", [10888] = "Fear", [10890] = "Fear",  -- Psychic Scream r1-4
    -- Incapacitate
    [9484]  = "Incap", [9485]  = "Incap", [10955] = "Incap",  -- Shackle Undead r1-3
    -- Root
    [44041] = "Root", [44043] = "Root", [44044] = "Root", [44045] = "Root", [44046] = "Root", [44047] = "Root",  -- Chastise r1-6
    -- Snare
    [15407] = "Snare", [17311] = "Snare", [17312] = "Snare", [17313] = "Snare", [17314] = "Snare", [18807] = "Snare", [25387] = "Snare",  -- Mind Flay r1-7

    -- ── Rogue ──────────────────────────────────────────────────────────────
    -- Blind
    [2094]  = "Blind",
    -- Stun
    [408]   = "Stun", [8643]  = "Stun",  -- Kidney Shot r1-2
    [1833]  = "Stun",  -- Cheap Shot
    [5530]  = "Stun",  -- Mace Stun
    -- Incapacitate
    [6770]  = "Incap", [2070]  = "Incap", [11297] = "Incap",  -- Sap r1-3
    [1776]  = "Incap", [1777]  = "Incap", [8629]  = "Incap", [11285] = "Incap", [11286] = "Incap", [38764] = "Incap",  -- Gouge r1-6
    -- Silence
    [1330]  = "Silence",  -- Garrote - Silence
    [18425] = "Silence",  -- Kick - Silenced (Improved Kick)
    -- Disarm
    [14251] = "Disarm",  -- Riposte
    -- Snare
    [3409]  = "Snare", [11201] = "Snare",  -- Crippling Poison r1-2
    [26679] = "Snare",  -- Deadly Throw
    [31125] = "Snare",  -- Dazed (Blade Twisting)

    -- ── Shaman ─────────────────────────────────────────────────────────────
    -- Stun
    [39796] = "Stun",  -- Stoneclaw Stun
    -- Snare
    [8056]  = "Snare", [8058]  = "Snare", [10472] = "Snare", [10473] = "Snare", [25464] = "Snare",  -- Frost Shock r1-5
    [3600]  = "Snare",  -- Earthbind Totem

    -- ── Warlock ────────────────────────────────────────────────────────────
    -- Banish
    [710]   = "Banish", [18647] = "Banish",  -- Banish r1-2
    -- Fear
    [5782]  = "Fear", [6213]  = "Fear", [6215]  = "Fear",   -- Fear r1-3
    [5484]  = "Fear", [17928] = "Fear",  -- Howl of Terror r1-2
    [6789]  = "Fear", [17925] = "Fear", [17926] = "Fear", [27223] = "Fear",  -- Death Coil r1-4
    -- Stun
    [22703] = "Stun",  -- Inferno Effect
    [18093] = "Stun",  -- Pyroclasm
    [30283] = "Stun", [30413] = "Stun", [30414] = "Stun",  -- Shadowfury r1-3
    -- Silence
    [31117] = "Silence",  -- Unstable Affliction
    [24259] = "Silence",  -- Spell Lock (Felhunter)
    -- Snare
    [18223] = "Snare",  -- Curse of Exhaustion
    [18118] = "Snare",  -- Aftermath
    [89]    = "Snare",  -- Cripple (Doomguard)
    -- Warlock Pets
    [32752] = "Stun",   -- Summoning Disorientation
    [6358]  = "Incap",  -- Seduction (Succubus)
    [19482] = "Stun",   -- War Stomp (Doomguard)
    [30153] = "Stun", [30195] = "Stun", [30197] = "Stun",  -- Felguard Intercept Stun r1-3

    -- ── Warrior ────────────────────────────────────────────────────────────
    -- Stun
    [7922]  = "Stun",  -- Charge
    [20253] = "Stun", [20614] = "Stun", [20615] = "Stun", [25273] = "Stun", [25274] = "Stun",  -- Intercept r1-5
    [12798] = "Stun",  -- Revenge Stun
    [12809] = "Stun",  -- Concussion Blow
    -- Fear
    [5246]  = "Fear", [20511] = "Fear",  -- Intimidating Shout
    -- Disarm
    [676]   = "Disarm",  -- Disarm
    -- Silence
    [18498] = "Silence",  -- Shield Bash - Silenced (Improved Shield Bash)
    -- Root
    [23694] = "Root",  -- Improved Hamstring
    -- Snare
    [29703] = "Snare",  -- Dazed (Shield Bash)
    [1715]  = "Snare", [7372]  = "Snare", [7373]  = "Snare", [25212] = "Snare",  -- Hamstring r1-4
    [12705] = "Snare",  -- Long Daze (Shield Bash)
    [12323] = "Snare",  -- Piercing Howl

    -- ── Racials / Items / Engineering / World ───────────────────────────────
    -- Silence
    [25046] = "Silence", [28730] = "Silence",  -- Arcane Torrent (blood elf)
    [19821] = "Silence",  -- Arcane Bomb
    [18278] = "Silence",  -- Silence (Silent Fang)
    -- Disarm
    [15752] = "Disarm",  -- Linken's Boomerang
    -- Root
    [8312]  = "Root",  -- Hunting Net
    [8346]  = "Root",  -- Mobility Malfunction
    [13099] = "Root", [13119] = "Root", [13138] = "Root", [16566] = "Root",  -- Net-o-Matic
    -- CC (items/racials/environment)
    [56]    = "CC", [835]   = "CC", [4159]  = "CC",
    [17308] = "CC", [23454] = "CC", [9179]  = "CC",
    [13327] = "CC",  -- Reckless Charge (Goblin Rocket Helmet)
    [20549] = "CC",  -- War Stomp (Tauren racial)
    [13181] = "CC", [26740] = "CC",  -- Gnomish Mind Control Cap
    [8345]  = "CC",  -- Control Machine
    [13235] = "CC",  -- Forcefield Collapse
    [13158] = "CC", [8893]  = "CC",  -- Rocket Boots Malfunction
    [13466] = "CC",  -- Goblin Dragon Gun
    [8224]  = "CC", [8225]  = "CC",  -- Cowardice / Run Away!
    [23444] = "CC", [23447] = "CC", [23456] = "CC", [23457] = "CC",  -- Transporter Malfunction
    [8510]  = "CC", [8511]  = "CC",  -- Seaforium Backfire
    [13237] = "CC", [13238] = "CC",  -- Goblin Mortar
    [5134]  = "CC",  -- Flash Bomb
    [4064]  = "CC", [4065]  = "CC", [4066]  = "CC", [4067]  = "CC", [4068]  = "CC", [4069]  = "CC",  -- Bronze/Copper/Iron Bombs
    [12543] = "CC", [12562] = "CC", [12421] = "CC",  -- Hi-Explosive / Big One / Mithril Frag
    [19784] = "CC", [19769] = "CC", [13808] = "CC",  -- Dark Iron Bomb / Thorium Grenade / M73
    [21188] = "CC",  -- Stun Bomb Attack
    [9159]  = "CC", [700]   = "CC", [1090]  = "CC", [12098] = "CC",  -- Sleep effects
    [20663] = "CC", [20669] = "CC", [8064]  = "CC", [17446] = "CC",  -- More sleep
    [29124] = "CC", [14621] = "CC", [27760] = "CC", [28406] = "CC",  -- Polymorph (world)
    [851]   = "CC",  -- Polymorph: Sheep
    [16707] = "CC", [16708] = "CC", [16709] = "CC", [18503] = "CC",  -- Hex
    [20683] = "CC", [17286] = "CC",  -- Highlord's Justice / Crusader's Hammer
    [12096] = "CC", [27641] = "CC", [29168] = "CC", [30002] = "CC",  -- Fear (world)
    [15398] = "CC", [26042] = "CC", [27610] = "CC",  -- Psychic Scream (world)
    [10794] = "CC",  -- Spirit Shock
    [25]    = "CC", [101]   = "CC", [2880]  = "CC", [5648]  = "CC", [5649]  = "CC",
    [5726]  = "CC", [5727]  = "CC", [5703]  = "CC",
    [5918]  = "CC", [3446]  = "CC", [3109]  = "CC",
    [3143]  = "CC", [5403]  = "CC", [3260]  = "CC",
    [3263]  = "CC", [3271]  = "CC", [5106]  = "CC",
    [6266]  = "CC", [6730]  = "CC", [6982]  = "CC",
    [6749]  = "CC", [6754]  = "CC", [6927]  = "CC",
    [7961]  = "CC", [8151]  = "CC", [3635]  = "CC",
    [9992]  = "CC", [6614]  = "CC", [5543]  = "CC",
    [6664]  = "CC", [6669]  = "CC", [5951]  = "CC",
    [4538]  = "CC", [6580]  = "CC", [6894]  = "CC",
    [7184]  = "CC", [8901]  = "CC", [8902]  = "CC",
    [9454]  = "CC", [7056]  = "CC", [7082]  = "CC",
    [6537]  = "CC", [8672]  = "CC",
    [6409]  = "CC", [14902] = "CC", [8338]  = "CC",
    [23055] = "CC", [8646]  = "CC", [11650] = "CC",
    [21990] = "CC", [19725] = "CC", [19469] = "CC",
    [10134] = "CC", [12613] = "CC",
    [13488] = "CC", [17738] = "CC",
    [20019] = "CC", [19136] = "CC", [20685] = "CC",
    [16803] = "CC", [14100] = "CC", [17276] = "CC",
    [13360] = "CC", [11430] = "CC", [16451] = "CC",
    [25260] = "CC", [23275] = "CC", [24919] = "CC",
    [21167] = "CC", [26641] = "CC", [28315] = "CC",
    [21898] = "CC", [20672] = "CC", [31365] = "CC",
    [25815] = "CC", [12134] = "CC",
    [16096] = "CC", [27177] = "CC", [18395] = "CC",
    [28323] = "CC", [28314] = "CC",
    [28127] = "CC", [17011] = "CC", [14102] = "CC",
    [15652] = "CC", [23269] = "CC", [22357] = "CC",
    [10451] = "CC", [15252] = "CC", [27615] = "CC",
    [24213] = "CC", [21936] = "CC", [11444] = "CC",
    [14871] = "CC", [25056] = "CC", [24647] = "CC",
    [17691] = "CC", [11481] = "CC", [20310] = "CC",
    [23775] = "CC", [23676] = "CC", [11983] = "CC",
    [9612]  = "CC", [4150]  = "CC", [6530]  = "CC",
    [5101]  = "CC", [6576]  = "CC", [7093]  = "CC",
    [8715]  = "CC", [8817]  = "CC", [9458]  = "CC",
    [3442]  = "CC", [25772] = "CC", [16053] = "CC",
    [15859] = "CC", [20740] = "CC", [11446] = "CC",
    [20668] = "CC", [21330] = "CC", [26108] = "CC",
    [24753] = "CC", [21847] = "CC", [21848] = "CC", [21980] = "CC",
    [27880] = "CC", [23010] = "CC",
    [24360] = "CC", [15822] = "CC",
    [15283] = "CC", [21152] = "CC", [16600] = "CC",
    [13907] = "CC", [18798] = "CC", [17500] = "CC",
    [34510] = "CC", [46567] = "CC",
    [35474] = "CC", [351357]= "CC",
    [28504] = "CC", [30216] = "CC",
    [30217] = "CC", [30461] = "CC",
    [36940] = "CC", [51581] = "CC",
    [12565] = "CC", [35182] = "CC", [40307] = "CC",
    [35236] = "CC", [29117] = "CC", [34088] = "CC",
    -- PVE / Dungeon / Raid CCs
    [32904] = "CC", [38177] = "CC", [39810] = "CC",
    [41621] = "CC", [43906] = "CC", [32913] = "CC",
    [33810] = "CC", [37450] = "CC", [38318] = "CC",
    [38915] = "CC", [41128] = "CC",
    [22901] = "CC", [31988] = "CC", [37323] = "CC",
    [37221] = "CC", [38774] = "CC", [33384] = "CC",
    [36145] = "CC", [42185] = "CC",
    [44881] = "CC", [37216] = "CC", [29909] = "CC",
    [46370] = "CC", [30298] = "CC", [49750] = "CC",
    [42380] = "CC", [42408] = "CC",
    [42695] = "CC",
    [42435] = "CC", [47718] = "CC", [47442] = "CC",
    [51413] = "CC", [47340] = "CC", [29044] = "CC",
    [30838] = "CC", [35840] = "CC", [39293] = "CC",
    [40400] = "CC", [42805] = "CC", [45665] = "CC",
    [26661] = "CC", [31358] = "CC", [31404] = "CC", [32040] = "CC",
    [32241] = "CC", [32709] = "CC", [33829] = "CC",
    [33924] = "CC", [34259] = "CC", [35198] = "CC", [35954] = "CC",
    [36629] = "CC", [36950] = "CC", [37939] = "CC",
    [38065] = "CC", [38154] = "CC", [39048] = "CC",
    [39119] = "CC", [39176] = "CC", [39210] = "CC", [39661] = "CC",
    [39914] = "CC", [40221] = "CC", [40259] = "CC",
    [40636] = "CC", [40669] = "CC", [41436] = "CC",
    [42690] = "CC", [42869] = "CC", [44142] = "CC",
    [50368] = "CC", [27983] = "CC",
    [29516] = "CC", [29903] = "CC", [30657] = "CC", [30688] = "CC",
    [30790] = "CC", [30832] = "CC", [30850] = "CC",
    [30857] = "CC", [31274] = "CC", [31292] = "CC", [31390] = "CC",
    [31539] = "CC", [31541] = "CC", [31548] = "CC", [31733] = "CC",
    [31819] = "CC", [31843] = "CC", [31864] = "CC",
    [31964] = "CC", [31994] = "CC", [32015] = "CC",
    [32021] = "CC", [32023] = "CC", [32104] = "CC",
    [32105] = "CC", [32150] = "CC", [32416] = "CC",
    [32779] = "CC", [32905] = "CC", [33128] = "CC", [33241] = "CC",
    [33422] = "CC", [33463] = "CC", [33487] = "CC",
    [33542] = "CC", [33637] = "CC", [33781] = "CC",
    [33792] = "CC", [33965] = "CC", [33937] = "CC",
    [34016] = "CC", [34023] = "CC", [34024] = "CC",
    [34108] = "CC", [34243] = "CC", [34357] = "CC",
    [34620] = "CC", [34815] = "CC", [34885] = "CC", [35202] = "CC",
    [35313] = "CC", [35382] = "CC", [35424] = "CC",
    [35492] = "CC", [35570] = "CC", [35614] = "CC",
    [35856] = "CC", [35957] = "CC", [36138] = "CC",
    [36254] = "CC", [36402] = "CC", [36449] = "CC",
    [36474] = "CC", [36509] = "CC", [36575] = "CC",
    [36642] = "CC", [36671] = "CC",
    [36732] = "CC", [36809] = "CC", [36824] = "CC",
    [36877] = "CC", [37012] = "CC", [37073] = "CC",
    [37103] = "CC", [37417] = "CC", [37493] = "CC",
    [37592] = "CC", [37768] = "CC", [37833] = "CC",
    [37919] = "CC", [38006] = "CC", [38009] = "CC",
    [38021] = "CC", [38169] = "CC", [38240] = "CC",
    [38357] = "CC", [38510] = "CC",
    [38554] = "CC", [38757] = "CC", [38863] = "CC",
    [39229] = "CC", [39568] = "CC", [39594] = "CC",
    [39622] = "CC", [39668] = "CC", [40135] = "CC",
    [40262] = "CC", [40358] = "CC", [40370] = "CC",
    [40380] = "CC", [40511] = "CC",
    [40398] = "CC", [40510] = "CC", [40409] = "CC",
    [40447] = "CC", [40490] = "CC", [40497] = "CC",
    [40503] = "CC", [40563] = "CC", [40578] = "CC",
    [40774] = "CC", [40835] = "CC", [40846] = "CC",
    [40951] = "CC", [41182] = "CC", [41358] = "CC",
    [41421] = "CC", [41528] = "CC", [41534] = "CC",
    [41592] = "CC", [41962] = "CC", [42386] = "CC",
    [42621] = "CC", [42648] = "CC", [43528] = "CC",
    [44031] = "CC", [44138] = "CC", [44415] = "CC",
    [44432] = "CC", [44836] = "CC", [44994] = "CC",
    [45574] = "CC", [45676] = "CC", [45889] = "CC",
    [45947] = "CC", [46188] = "CC", [46590] = "CC",
    [48342] = "CC", [50876] = "CC",
	[38461] = "CC",
    -- ── Named boss abilities with non-obvious names (fallback won't catch these) ──
    -- Lady Vashj (SSC)
    [38509] = "Stun",   -- Shock Blast
    [38316] = "Root",   -- Entangle
    -- Nightbane (Karazhan)
    [30127] = "Fear",   -- Bellowing Roar
    [35491] = "Stun",   -- Charcoal Depiction (disorient)
    -- High King Maulgar / Gruul's Lair
    [33613] = "Stun",   -- Intercept Stun (Olm the Summoner)
    [33936] = "Stun",   -- Magnetic Pull (Gruul)
    -- Magtheridon
    [30225] = "Stun",   -- Blastnova
    -- Void Reaver (The Eye)
    [34841] = "Stun",   -- Arcane Orb
    -- Kael'thas (The Eye)
    [36797] = "Stun",   -- Pyroblast knockback
    [36990] = "Stun",   -- Gravity Lapse
    -- Leotheras the Blind (SSC)
    [37674] = "Stun",   -- Chaos Blast
    -- Morogrim Tidewalker (SSC)
    [37688] = "Stun",   -- Earthquake
    -- Fathom-Lord Karathress (SSC)
    [38008] = "Stun",   -- Cataclysmic Bolt knockback
    -- Rage Winterchill (Hyjal)
    [31249] = "Fear",   -- Death and Decay
    [27808] = "Stun",   -- Icebolt
    -- Anetheron (Hyjal)
    [31306] = "Sleep",  -- Sleep
    -- Archimonde (Hyjal)
    [31447] = "Fear",   -- Grip of the Legion
    [32325] = "Stun",   -- Finger of Death
    -- Mother Shahraz (BT)
    [40243] = "Stun",   -- Sinful Beam
    -- Illidari Council (BT)
    [41475] = "Stun",   -- Judgment of Blood
    -- Illidan (BT)
    [40683] = "Fear",   -- Agonizing Flames
    [33031] = "Stun",   -- Eyebeam
    -- Zul'jin (ZA)
    [42556] = "Stun",   -- Claw Rage
    [43299] = "Stun",   -- Feather Storm knockdown
    [9915]  = "Root", [14907] = "Root", [22645] = "Root",  -- Frost Nova (world)
    [15091] = "Snare", [17277] = "Snare", [23039] = "Snare", [23113] = "Snare",  -- Blast Wave (world)
    [23115] = "Snare", [19133] = "Snare", [21030] = "Snare",  -- Frost Shock (world)
    [11538] = "Snare", [21369] = "Snare", [20297] = "Snare", [20806] = "Snare", [20819] = "Snare",
    [12737] = "Snare", [20792] = "Snare", [20822] = "Snare", [23412] = "Snare", [24942] = "Snare",
    [23102] = "Snare", [20828] = "Snare", [22746] = "Snare",  -- Frostbolt/Cone of Cold (world)
    [20717] = "Snare", [16568] = "Snare", [16094] = "Snare", [16340] = "Snare",
    [17174] = "Snare", [27634] = "Snare",  -- Concussive Shot (world)
    [20654] = "Root",  [22800] = "Root",  [20699] = "Root",   -- Entangling Roots (world)
    [18546] = "Root",  [22935] = "Root",
    [12023] = "Root",  [13608] = "Root",  [10017] = "Root",  [23279] = "Root",
    [3542]  = "Root",  [5567]  = "Root",  [5424]  = "Root",  [4246]  = "Root",
    [5219]  = "Root",  [9576]  = "Root",  [7950]  = "Root",  [7761]  = "Root",
    [6714]  = "Root",  [6716]  = "Root",

    -- Stuns / Hard CC
    [3242]  = "CC", -- Ravage
    [3589]  = "CC", -- Deafening Screech
    [3636]  = "CC", -- Crystalline Slumber
    [5164]  = "CC", -- Knockdown
    [5708]  = "CC", -- Swoop
    [6253]  = "CC", -- Backhand
    [6304]  = "CC", -- Rhahk'Zor Slam
    [6435]  = "CC", -- Smite Slam
    [7803]  = "CC", -- Thundershock
    [7964]  = "CC", -- Smoke Bomb
    [7967]  = "CC", -- Naralex's Nightmare
    [8040]  = "CC", -- Druid's Slumber
    [8285]  = "CC", -- Rampage
    [8391]  = "CC", -- Ravage
    [11020] = "CC", -- Petrify
    [11430] = "CC", -- Slam
    [11836] = "CC", -- Freeze Solid
    [12461] = "CC", -- Backhand
    [13005] = "Stun", -- Hammer of Justice (NPC)
    [39077] = "Stun", -- Hammer of Justice (TK squires / Kael'thas trash)
    [13902] = "CC", -- Fist of Ragnaros
    [15655] = "CC", -- Shield Slam
    [15847] = "CC", -- Tail Sweep
    [15878] = "CC", -- Ice Blast
    [16075] = "CC", -- Throw Axe
    [16497] = "CC", -- Stun Bomb
    [16727] = "CC", -- War Stomp
    [16790] = "CC", -- Knockdown
    [16803] = "CC", -- Flash Freeze
    [17276] = "CC", -- Scald
    [18103] = "CC", -- Backhand
    [18144] = "CC", -- Swoop
    [18763] = "CC", -- Freeze
    [18812] = "CC", -- Knockdown
    [19128] = "CC", -- Knockdown
    [19136] = "CC", -- Stormbolt
    [19364] = "CC", -- Ground Stomp
    [19641] = "CC", -- Pyroclast Barrage
    [19780] = "CC", -- Hand of Ragnaros
    [19798] = "CC", -- Earthquake
    [20276] = "CC", -- Knockdown
    [20277] = "CC", -- Fist of Ragnaros
    [21748] = "CC", -- Thorn Volley
    [22289] = "CC", -- Brood Power: Green
    [22592] = "CC", -- Knockdown
    [23364] = "CC", -- Tail Lash
    [23919] = "CC", -- Swoop
    [24213] = "CC", -- Ravage
    [24333] = "CC", -- Ravage
    [24600] = "CC", -- Web Spin
    [25189] = "CC", -- Enveloping Winds
    [25852] = "CC", -- Lash
    [27758] = "CC", -- War Stomp
    [27993] = "CC", -- Stomp
    [28125] = "CC", -- War Stomp
    [29670] = "CC", -- Ice Tomb
    [29676] = "CC", -- Rolling Pin
    [29690] = "CC", -- Drunken Skull Crack
    [29711] = "CC", -- Knockdown
    [30761] = "CC", -- Wide Swipe
    [31286] = "CC", -- Lash
    [31422] = "CC", -- Time Stop
    [31718] = "CC", -- Enveloping Winds
    [31994] = "CC", -- Shoulder Charge
    [32015] = "CC", -- Knockdown
    [32023] = "CC", -- Hoof Stomp
    [32361] = "CC", -- Crystal Prison
    [32588] = "CC", -- Concussion Blow
    [32651] = "CC", -- Howling Screech
    [32654] = "CC", -- Talon of Justice
    [33709] = "CC", -- Charge
    [33919] = "CC", -- Earthquake
    [34108] = "CC", -- Spine Break
    [34885] = "CC", -- Petrify
    [35238] = "CC", -- War Stomp
    [35783] = "CC", -- Knockdown
    [36254] = "CC", -- Judgement of the Flame
    [3635]  = "CC", -- Crystal Gaze
    [36835] = "CC", -- War Stomp
    [36924] = "CC", -- Mind Rend
    [36929] = "CC", -- Mind Rend
    [37012] = "CC", -- Swoop
    [385807]= "CC", -- Knockdown
    [39017] = "CC", -- Mind Rend
    [39021] = "CC", -- Mind Rend
    [39229] = "CC", -- Talon of Justice
    [39427] = "CC", -- Bellowing Roar

    -- Charms / Mind Control
    [7645]  = "MC", -- Dominate Mind
    [12888] = "MC", -- Cause Insanity
    [14515] = "MC", -- Dominate Mind
    [17405] = "MC", -- Domination
    [24327] = "MC", -- Cause Insanity
    [29490] = "Incap", -- Seduction
    [29546] = "MC", -- Oath of Fealty
    [31865] = "Incap", -- Seduction
    [35120] = "MC", -- Charm
    [35280] = "MC", -- Domination
    [36866] = "MC", -- Domination

    -- Fears / Horror
    [7399]  = "Fear", -- Terrify
    [12542] = "Fear", -- Fear
    [13704] = "Fear", -- Psychic Scream
    [16508] = "Fear", -- Intimidating Roar
    [18431] = "Fear", -- Bellowing Roar
    [19134] = "Fear", -- Frightening Shout
    [19408] = "Fear", -- Panic
    [21869] = "Fear", -- Repulsive Gaze
    [22678] = "Fear", -- Fear
    [22686] = "Fear", -- Bellowing Roar
    [25260] = "Fear", -- Wings of Despair
    [25815] = "Fear", -- Frightening Shriek
    [26070] = "Fear", -- Fear
    [26580] = "Fear", -- Fear
    [27641] = "Fear", -- Fear
    [27990] = "Fear", -- Fear
    [29321] = "Fear", -- Fear
    [29544] = "Fear", -- Frightening Shout
    [29685] = "Fear", -- Terrifying Roar
    [30584] = "Fear", -- Fear
    [30615] = "Fear", -- Fear
    [30752] = "Fear", -- Terrifying Howl
    [31013] = "Fear", -- Frightened Scream
    [32421] = "Fear", -- Soul Scream
    [33547] = "Fear", -- Fear
    [33789] = "Fear", -- Frightening Shout
    [34259] = "Fear", -- Fear
    [34322] = "Fear", -- Psychic Scream
    [35198] = "Fear", -- Terrify
    [36629] = "Fear", -- Terrifying Roar
    [36922] = "Fear", -- Bellowing Roar
    [38154] = "Fear", -- Fear
    [38660] = "Fear", -- Fear
    [39119] = "Fear", -- Fear
    [39415] = "Fear", -- Fear
    [40454] = "Fear", -- Frighten

    -- Sleep / Incapacitate
    [700]   = "Sleep", -- Sleep
    [1090]  = "Sleep", -- Sleep
    [3636]  = "Stun",  -- Crystalline Slumber (already in Stuns, keep one)
    [7967]  = "Sleep", -- Naralex's Nightmare
    [8040]  = "Sleep", -- Druid's Slumber
    [8399]  = "Sleep", -- Sleep
    [12098] = "Sleep", -- Sleep
    [15970] = "Sleep", -- Sleep
    [16798] = "Sleep", -- Enchanting Lullaby
    [20663] = "Sleep", -- Sleep
    [20989] = "Sleep", -- Sleep
    [24335] = "Incap", -- Wyvern Sting
    [29679] = "Sleep", -- Bad Poetry
    [31292] = "Sleep", -- Sleep
    [34801] = "Sleep", -- Sleep
    [36333] = "Sleep", -- Anesthetic
    [36402] = "Sleep", -- Sleep

    -- Silence
    [6726]  = "Silence", -- Silence
    [22666] = "Silence", -- Silence
    [26069] = "Silence", -- Silence
    [30225] = "Silence", -- Silence
    [33390] = "Silence", -- Arcane Torrent
    [34087] = "Silence", -- Chilling Words
    [3589]  = "Silence", -- Deafening Screech
    [6942]  = "Silence", -- Overwhelming Stench
    [8281]  = "Silence", -- Sonic Burst
    [8988]  = "Silence", -- Silence
    [9552]  = "Silence", -- Searing Flames
    [12528] = "Silence", -- Silence
    [12946] = "Silence", -- Putrid Stench
    [16838] = "Silence", -- Banshee Shriek
    [18327] = "Silence", -- Silence
    [19393] = "Silence", -- Soul Burn
    [23918] = "Silence", -- Sonic Burst
    [29505] = "Silence", -- Banshee Shriek
    [29904] = "Silence", -- Sonic Burst
    [30849] = "Silence", -- Spell Lock
    [31069] = "Silence", -- Brain Wipe
    [31273] = "Silence", -- Screech
    [34088] = "Silence", -- Feeble Weapons
    [34089] = "Silence", -- Doubting Mind
    [34922] = "Silence", -- Shadows Embrace
    [35892] = "Silence", -- Suppression
    [36022] = "Silence", -- Arcane Torrent
    [36297] = "Silence", -- Reverberation
    [38913] = "Silence", -- Silence

    -- Snares / Slows
    [89]    = "Snare", -- Cripple
    [246]   = "Snare", -- Slow
    [6136]  = "Snare", -- Chilled
    [6146]  = "Snare", -- Slow
    [6984]  = "Snare", -- Frost Shot
    [7321]  = "Snare", -- Chilled
    [7992]  = "Snare", -- Slowing Poison
    [8147]  = "Snare", -- Thunderclap
    [9080]  = "Snare", -- Hamstring
    [11436] = "Snare", -- Slow
    [12531] = "Snare", -- Chilling Touch
    [12551] = "Snare", -- Frost Shot
    [13747] = "Snare", -- Slow
    [14897] = "Snare", -- Slowing Poison
    [15548] = "Snare", -- Thunderclap
    [15588] = "Snare", -- Thunderclap
    [16050] = "Snare", -- Slowing Ooze
    [17165] = "Snare", -- Mind Flay
    [17174] = "Snare", -- Concussive Shot
    [18099] = "Snare", -- Chill Nova
    [18101] = "Snare", -- Chilled
    [18328] = "Snare", -- Incapacitating Shout
    [18972] = "Snare", -- Slow
    [22356] = "Snare", -- Slow
    [22914] = "Snare", -- Concussive Shot
    [22919] = "Snare", -- Mind Flay
    [23600] = "Snare", -- Piercing Howl
    [23931] = "Snare", -- Thunderclap
    [25603] = "Snare", -- Slow
    [25809] = "Snare", -- Crippling Poison
    [26141] = "Snare", -- Hamstring
    [26143] = "Snare", -- Mind Flay
    [26211] = "Snare", -- Hamstring
    [26379] = "Snare", -- Piercing Shriek
    [29292] = "Snare", -- Frost Mist
    [29407] = "Snare", -- Mind Flay
    [29540] = "Snare", -- Curse of Past Burdens
    [29570] = "Snare", -- Mind Flay
    [29667] = "Snare", -- Hamstring
    [29990] = "Snare", -- Slow
    [30035] = "Snare", -- Mass Slow
    [30109] = "Snare", -- Slime Burst
    [30494] = "Snare", -- Sticky Ooze
    [30633] = "Snare", -- Thunderclap
    [30981] = "Snare", -- Crippling Poison
    [30984] = "Snare", -- Wound Poison
    [30989] = "Snare", -- Hamstring
    [31467] = "Snare", -- Time Lapse
    [31473] = "Snare", -- Sand Breath
    [31478] = "Snare", -- Sand Breath
    [31553] = "Snare", -- Hamstring
    [32000] = "Snare", -- Mind Sear
    [32013] = "Snare", -- Mucky Sludge
    [32065] = "Snare", -- Fungal Decay
    [32922] = "Snare", -- Slow
    [33061] = "Snare", -- Blast Wave
    [33628] = "Snare", -- Lightning Tether
    [33967] = "Snare", -- Thunderclap
    [35032] = "Snare", -- Slow
    [35240] = "Snare", -- Bloodmaul Intoxication
    [35244] = "Snare", -- Choking Vines
    [35263] = "Snare", -- Frost Attack
    [35493] = "Snare", -- Forked Lightning Tether
    [35507] = "Snare", -- Mind Flay
    [35919] = "Snare", -- Welding Beam
    [36148] = "Snare", -- Chill Nova
    [36214] = "Snare", -- Thunderclap
    [36464] = "Snare", -- The Den Mother's Mark
    [36508] = "Snare", -- Energy Surge
    [36518] = "Snare", -- Shadowsurge
    [36659] = "Snare", -- Tail Sting
    [36706] = "Snare", -- Thunderclap
    [36824] = "Snare", -- Overwhelming Odor
    [36839] = "Snare", -- Impairing Poison
    [36843] = "Snare", -- Slow
    [36974] = "Snare", -- Wound Poison
    [37330] = "Snare", -- Mind Flay
    [37359] = "Snare", -- Rush
    [37591] = "Snare", -- Drunken Haze
    [37621] = "Snare", -- Mind Flay
    [37654] = "Snare", -- Lightning Tether
    [37986] = "Snare", -- Ancient Fire
    [38243] = "Snare", -- Mind Flay
    [38537] = "Snare", -- Thunderclap
    [38767] = "Snare", -- Daze
    [38985] = "Snare", -- Focused Bursts
    [39049] = "Snare", -- Sand Breath
    [43130] = "Snare", -- Creeping Vines
    [43131] = "Snare", -- Lingering Vines
}

local function IsCCSpell(spellID, spellName)
    if CC_SPELLS[spellID] then
        return CC_SPELLS[spellID]
    end
    if spellName then
        local lower = spellName:lower()
        -- Check specific types first, most-specific to least
        if lower:find("polymorph") then return "Poly" end
        if lower:find("banish") then return "Banish" end
        if lower:find("seduct") then return "Incap" end
        if lower:find("mind control") or lower:find("domination") or lower:find("charm") then return "MC" end
        if lower:find("fear") or lower:find("terrif") or lower:find("horrif") or lower:find("frighten") then return "Fear" end
        if lower:find("sleep") or lower:find("slumber") or lower:find("lullaby") then return "Sleep" end
        if lower:find("stun") or lower:find("bash") or lower:find("kidney") or lower:find("concussion") or
           lower:find("knockdown") or lower:find("knockback") or lower:find("intercept") then return "Stun" end
        if lower:find("blind") then return "Blind" end
        if lower:find("incapacitat") or lower:find("gouge") or lower:find("sap") then return "Incap" end
        if lower:find("disorient") then return "Stun" end
        if lower:find("silence") then return "Silence" end
        if lower:find("disarm") then return "Disarm" end
        if lower:find("root") or lower:find("entangl") or lower:find("frost nova") or lower:find("immobiliz") then return "Root" end
        if lower:find("snare") or lower:find("crippl") or lower:find("hamstring") or lower:find("slow") then return "Snare" end
    end
    return nil
end

-------------------------------------------------------------------------------
-- Tank Detection
-------------------------------------------------------------------------------
local function IsTanking()
    if not TankBuffReminderCharDB or not TankBuffReminderCharDB.threatEnabled then
        return false
    end
    local _, class = UnitClass("player")
    if class == "DRUID" then
        for i = 1, 40 do
            local name = UnitBuff("player", i)
            if not name then break end
            if name == "Bear Form" or name == "Dire Bear Form" then
                return UnitGroupRolesAssigned("player") == "TANK"
            end
        end
        return false
    end
    return UnitGroupRolesAssigned("player") == "TANK"
end

-------------------------------------------------------------------------------
-- Event Queue
-------------------------------------------------------------------------------
local function FlushBuffer()
    isThrottling = false
    if #eventBuffer == 0 then return end

    table.wipe(formattedLines)
    table.wipe(dedupHash)

    for i = 1, #eventBuffer, 3 do
        local spellName  = eventBuffer[i] or "Ability"
        local targetName = eventBuffer[i+1] or ""
        local eventType  = eventBuffer[i+2] or "Event"

        -- Translate raw type tags to localized display labels
        local displayType = L[eventType] or eventType

        local entry = targetName ~= ""
            and (targetName .. " " .. displayType:lower() .. " " .. spellName)
            or  (spellName .. " (" .. displayType .. ")")

        if not dedupHash[entry] then
            table.insert(formattedLines, entry)
            dedupHash[entry] = true
        end
    end

    table.wipe(eventBuffer)
    lastAlertTime = GetTime()

    local prefix = L["THREAT_ALERT_PREFIX"] or "Pull issue — "
    local msg = prefix .. table.concat(formattedLines, ", ")

    if TankBuffReminderCharDB.threatWarning ~= false then
        print(MSG_PREFIX .. msg)
    end

    if TankBuffReminderCharDB.threatSoundEnabled ~= false then
        PlaySound(TankBuffReminderCharDB.threatSoundID or 8959, "Master")
    end

    if IsInGroup() then
        if TankBuffReminderCharDB.threatRaid and IsInRaid() then
            SendChatMessage(msg, "RAID")
        elseif TankBuffReminderCharDB.threatParty then
            SendChatMessage(msg, "PARTY")
        elseif TankBuffReminderCharDB.threatSay then
            pcall(SendChatMessage, msg, "SAY")
        elseif TankBuffReminderCharDB.threatYell then
            pcall(SendChatMessage, msg, "YELL")
        end
    elseif TankBuffReminderCharDB.threatSay then
        pcall(SendChatMessage, msg, "SAY")
    elseif TankBuffReminderCharDB.threatYell then
        pcall(SendChatMessage, msg, "YELL")
    end
end

local function QueueEvent(spellName, targetName, eventType)
    table.insert(eventBuffer, spellName or "")
    table.insert(eventBuffer, targetName or "")
    table.insert(eventBuffer, eventType or "Event")

    if not isThrottling then
        isThrottling = true
        C_Timer.After(0.15, FlushBuffer)
    end
end

-------------------------------------------------------------------------------
-- Should Listen?
-------------------------------------------------------------------------------
local function IsListening(isCC)
    local db = TankBuffReminderCharDB
    if not db or not db.threatEnabled then return false end
    if pvpShield or not inCombat then return false end
    if not IsTanking() then return false end

    if isCC and db.threatCCFullCombat then
        return true
    else
        local window = db.threatWindow or DEFAULT_WINDOW
        return (GetTime() - combatStartTime) <= window
    end
end

-------------------------------------------------------------------------------
-- CC Detection via UNIT_AURA
-------------------------------------------------------------------------------
local function CheckPlayerCCs()
    if not TankBuffReminderCharDB.threatCC then return end
    if not IsListening(true) then return end

    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitDebuff("player", i)
        if not name then break end

        local ccType = IsCCSpell(spellID, name)
        if ccType and not activeCCs[spellID] then
            activeCCs[spellID] = true
            QueueEvent(name, "", ccType)
        end
    end
end

-------------------------------------------------------------------------------
-- Main Event Frame
-------------------------------------------------------------------------------
local tA = CreateFrame("Frame")
tA:RegisterEvent("PLAYER_LOGIN")
tA:RegisterEvent("PLAYER_ENTERING_WORLD")
tA:RegisterEvent("PLAYER_REGEN_DISABLED")
tA:RegisterEvent("PLAYER_REGEN_ENABLED")
tA:RegisterEvent("UNIT_AURA")

local function ToggleThreatRegistration()
    if TankBuffReminderCharDB and TankBuffReminderCharDB.threatEnabled then
        tA:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        tA:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

tA:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
        local db = TankBuffReminderCharDB
        if db then
            -- Apply defaults only when the key has never been set (nil).
            -- Never flip existing values — that was corrupting settings on every login.
            if db.threatEnabled      == nil then db.threatEnabled      = false end
            if db.threatWarning      == nil then db.threatWarning      = false end
            if db.threatSay          == nil then db.threatSay          = false end
            if db.threatYell         == nil then db.threatYell         = false end
            if db.threatParty        == nil then db.threatParty        = false end
            if db.threatRaid         == nil then db.threatRaid         = false end
            if db.threatSoundEnabled == nil then db.threatSoundEnabled = false end
            if db.threatMiss         == nil then db.threatMiss         = false end
            if db.threatResist       == nil then db.threatResist       = false end
            if db.threatCC           == nil then db.threatCC           = false end
            if db.threatCCFullCombat == nil then db.threatCCFullCombat = false end
            if db.threatWindow       == nil then db.threatWindow       = DEFAULT_WINDOW end
        end
        ToggleThreatRegistration()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        local _, instanceType = IsInInstance()
        pvpShield = (instanceType == "pvp" or instanceType == "arena")
        ToggleThreatRegistration()
        return
    end

    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        combatStartTime = GetTime()
        lastAlertTime = 0
        table.wipe(eventBuffer)
        table.wipe(activeCCs)
        table.wipe(spellAlertCooldowns)
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        table.wipe(eventBuffer)
        table.wipe(activeCCs)
        table.wipe(spellAlertCooldowns)
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            CheckPlayerCCs()
        end
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName, _, _,
              spellID, spellName, _, missType = CombatLogGetCurrentEventInfo()

        -- === SPELL / RANGED MISSES ===
        if sourceGUID == playerGUID and (subEvent == "SPELL_MISSED" or subEvent == "RANGE_MISSED") then
            if IsListening(false) then
                if (missType == "RESIST" and TankBuffReminderCharDB.threatResist) or
                   (missType ~= "RESIST" and TankBuffReminderCharDB.threatMiss) then

                    -- Per-spell cooldown: AoE abilities (Demo Shout, Consecration,
                    -- Swipe, Cleave, etc.) hit multiple targets simultaneously.
                    -- Only queue the first miss per spellID within SPAM_THROTTLE seconds
                    -- so we get one alert for the ability, not one per target hit.
                    local now = GetTime()
                    local lastSpellAlert = spellAlertCooldowns[spellID] or 0
                    if (now - lastSpellAlert) >= SPAM_THROTTLE then
                        spellAlertCooldowns[spellID] = now
                        QueueEvent(spellName or "Spell", destName or "", missType)
                    end
                end
            end
        end
    end
end)