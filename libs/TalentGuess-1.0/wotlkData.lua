if( not IS_WRATH_BUILD ) then return end

local major = "TalentGuessData-1.0"
local minor = tonumber(string.match("$Revision: 703$", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local Data = LibStub:NewLibrary(major, minor)
if( not Data ) then return end

-- The format is pretty simple
-- [spellID] = "tree #:points required:checkBuffs:isCastOnly"
Data.Spells = {
	-- ROGUES

	--[[ Assassination ]]--
	-- Remorseless Attacks
	[14143] = "1:1",
	[14149] = "1:2",
	-- Cold Blood
	[14177] = "1:21",
	-- Quick Recovery
	[31663] = "1:23",
	-- Focused Attacks
	[51637] = "1:38",
	-- Mutilate
	[1329] = "1:41",
	[34411] = "1:41",
	[34412] = "1:41",
	[34413] = "1:41",
	[48663] = "1:41",
	[48666] = "1:41",
	-- Hunger For Blood
	[51662] = "1:51",
	
	--[[ Combat ]]--
	-- Riposte
	[14251] = "2:11",
	-- Blade Flurry
	[13877] = "2:21",
	-- Adrenaline Rush
	[13750] = "2:31",
	-- Throwing Specialization
	[51680] = "2:37",
	-- Combat Potency
	[35542] = "2:36",
	[35545] = "2:37",
	[35546] = "2:38",
	[35547] = "2:39",
	[35548] = "2:40",
	-- Killing Spree
	[51690] = "2:51",

	--[[ Subtlety ]]--
	-- Relentless Strikes
	[14181] = "3:5",
	-- Ghostly Strike
	[14278] = "3:11",
	-- Hemorrhage
	[16511] = "3:21",
	[17347] = "3:21",
	[17348] = "3:21",
	[26864] = "3:21",
	[48660] = "3:21",
	-- Preparation
	[14185] = "3:21",
	-- Premedition
	[14183] = "3:31",
	-- Cheat Death
	[45182] = "3:33",
	-- Shadowstep
	[36554] = "3:41",
	-- Shadow Dance
	[51713] = "3:51",

	--[[ DRUIDS ]]
	
	--[[ Balance ]]--
	-- Nature's Grace
	[16886] = "1:11:true",
	-- Insect Swarm
	[5570] = "1:21",
	[24974] = "1:21",
	[24975] = "1:21",
	[24976] = "1:21",
	[24977] = "1:21",
	[27013] = "1:21",
	[48468] = "1:21",
	-- Moonkin Form
	[24858] = "1:31:true",
	-- Owlkin Frenzy
	[48391] = "1:38",
	-- Typhoon
	[50516] = "1:41",
	[53223] = "1:41",
	[53225] = "1:41",
	[53226] = "1:41",
	[53227] = "1:41",
	-- Treants
	[33831] = "1:41",
	-- Eclipse
	[48517] = "1:43",
	[48518] = "1:43",
	-- Starfall
	[48505] = "1:51",
	[53199] = "1:51",
	[53200] = "1:51",
	[53201] = "1:51",
	
	--[[ Feral ]]--
	-- Faerie Fire
	[16857] = "2:11",
	[17390] = "2:11",
	[17391] = "2:11",
	[17392] = "2:11",
	[27011] = "2:11",
	[48475] = "2:11",
	-- Primal Fury
	[16959] = "2:17",	
	[16953] = "2:17",
	-- Feral Charge
	[16979] = "2:21",
	[49376] = "2:21",
	-- Mangle (Cat/Bear)
	[33878] = "2:41",
	[33986] = "2:41",
	[33987] = "2:41",
	[48563] = "2:41",
	[48564] = "2:41",
	[33876] = "2:41",
	[33982] = "2:41",
	[33983] = "2:41",
	[48565] = "2:41",
	[48566] = "2:41",
	-- Berserk
	[50334] = "2:51",
	
	--[[ Resto ]]--
	-- Omen of Clarity
	[16870] = "3:11",
	-- Master Shapeshifter
	[48418] = "3:13",
	[48420] = "3:13",
	[48421] = "3:13",
	[48422] = "3:13",
	-- Nature's Swiftness
	[17116] = "3:21",
	-- Swiftmend
	[18562] = "3:31",
	-- Natural Perfection
	[45281] = "3:32:true",
	[45282] = "3:33:true",
	[45283] = "3:34:true",
	-- Tree of Life
	[33891] = "3:41",
	-- Flourish
	[48438] = "3:51",
	[53248] = "3:51",
	[53249] = "3:51",
	[53251] = "3:51",
	
	-- HUNTERS
	
	--[[ Beast Mastery ]]--
	-- Improved Aspect of the Hawk
	[6150] = "1:5",
	-- Improved Mend Pet
	[24406] = "1:17",
	-- Intimidation
	[19577] = "1:21",
	-- Spirit Bond
	[19579] = "1:22:true",
	[24529] = "1:23:true",
	-- Beastial Wrath
	[19574] = "1:31",
	-- The Beast Within
	[34471] = "1:41",
	
	--[[ Marksmanship ]]--
	-- Aimed Shot
	[19434] = "2:11",
	[20900] = "2:11",
	[20901] = "2:11",
	[20902] = "2:11",
	[20903] = "2:11",
	[20904] = "2:11",
	[27065] = "2:11",
	[49049] = "2:11",
	[49050] = "2:11",
	-- Rapid Killing
	[35098] = "2:12",
	[35099] = "2:13",
	-- Scatter Shot
	[19503] = "2:21",
	-- Silencing Shot
	[34490] = "2:41",
	-- Improved Steady Shot
	[53220] = "2:43",
	-- Chimera Shot
	[53209] = "2:51",
	
	--[[ Survival ]]--
	-- Lock and Load
	[56453] = "3:18",
	-- Counterattack
	[19306] = "3:21",
	[20909] = "3:21",
	[20910] = "3:21",
	[27067] = "3:21",
	[48998] = "3:21",
	[48999] = "3:21",
	-- Wyvern Sting
	[19386] = "3:31",
	[24132] = "3:31",
	[24133] = "3:31",
	[27068] = "3:31",
	[49011] = "3:31",
	[49012] = "3:31",
	-- Readiness
	[23989] = "3:41",
	-- Explosive Shot
	[53301] = "3:51",
	
	-- MAGES
	
	--[[ Arcane ]]--
	-- Magic Absorption
	[29442] = "1:7",
	-- Clearcasting
	[12536] = "1:10",
	-- Focus Magic
	[54646] = "1:11",
	[54648] = "1:11",
	[54650] = "1:11",
	[54652] = "1:11",
	[54653] = "1:11",
	[54654] = "1:11",
	[54655] = "1:11",
	-- Presence of Mind
	[12043] = "1:21",
	-- Improved Blink
	[46989] = "1:22",
	[47000] = "1:23",
	-- Arcane Power
	[12042] = "1:31",
	-- Incanter's Absorption
	[44413] = "1:33",
	-- Slow
	[31589] = "1:41",
	-- Missle Barrage
	[44401] = "1:45",
	-- Arcane Barrage
	[44425] = "1:51",
	[44780] = "1:51",
	[44781] = "1:51",
	
	--[[ Fire ]]--
	-- Burning Determination
	[54748] = "2:7",
	-- Master of Elements
	[29077] = "2:18",
	-- Blast Wave
	[11113] = "2:21",
	[13018] = "2:21",
	[13019] = "2:21",
	[13020] = "2:21",
	[13021] = "2:21",
	[27133] = "2:21",
	[33933] = "2:21",
	-- Blazing Speed
	[31643] = "2:27",
	-- Combustion
	[11129] = "2:31",
	-- Dragon's Breath
	[31661] = "2:41",
	[33041] = "2:41",
	[33042] = "2:41",
	[33043] = "2:41",
	[42949] = "2:41",
	[42950] = "2:41",
	-- Fire Starter
	[54741] = "2:43",
	-- Hot Streak
	[48108] = "2:43",
	-- Living Bomb
	[44457] = "2:51",
	[55359] = "2:51",
	[55360] = "2:51",

	--[[ Frost ]]--
	-- Icy Veins
	[12472] = "3:11",
	-- Cold Snap
	[11958] = "3:21",
	-- Ice Barrier
	[11426] = "3:31",
	[13031] = "3:31",
	[13032] = "3:31",
	[13033] = "3:31",
	[27134] = "3:31",
	[33405] = "3:31",
	[43038] = "3:31",
	[43039] = "3;31",
	-- Summon Water Element
	[31687] = "3:41",
	-- Brain Freeze
	[57761] = "3:44",
	-- Deep Freeze
	[44572] = "3:51",
	[54776] = "3:51",
	[54777] = "3:51",
	[54778] = "3:51",
	
	-- PALADINS
	
	--[[ Holy ]]--
	-- Illumination
	[20272] = "1:15",
	-- Divine Favor
	[20216] = "1:21",
	-- Holy Shock
	[20473] = "1:31",
	[20929] = "1:31",
	[20930] = "1:31",
	[27174] = "1:31",
	[33072] = "1:31",
	[48824] = "1:31",
	[48825] = "1:31",
	-- Light's Grace
	[31834] = "1:33",
	-- Divine Illumination
	[31842] = "1:41",
	-- Judgement of the Pure
	[53655] = "1:46",
	[53656] = "1:47",
	[53657] = "1:48",
	[54152] = "1:49",
	[54153] = "1:50",
	-- Beacon of Light
	[53563] = "1:51",
	
	--[[ Protection ]]--
	-- Blessing of Kings
	[20217] = "2:1:nil:true",
	[25898] = "2:1:nil:true",
	-- Blessing of Sanctuary
	[20911] = "2:21:nil:true",
	[25899] = "2:21:nil:true",
	-- Reckoning
	[20178] = "2:25",
	-- Holy Shield
	[20925] = "2:31",
	[20927] = "2:31",
	[20928] = "2:31",
	[27179] = "2:31",
	[48951] = "2:31",
	[48952] = "2:31",
	-- Redoubt
	[20128] = "2:36",
	[20131] = "2:37",
	[20132] = "2:38",
	-- Avenger's Shield
	[31935] = "2:41",
	[32699] = "2:41",
	[32700] = "2:41",
	[48826] = "2:41",
	[48827] = "2:41",
	-- Hammer of the Righteous
	[53595] = "2:51",
	
	--[[ Retribution ]]--
	-- Seal of command
	[20375] = "3:11",
	[20050] = "3:26",
	[20052] = "3:27",
	[20053] = "3:28",
	-- Repentance
	[20066] = "3:31",
	-- The Art of War
	[53489] = "3:33",
	-- Crusader Strike
	[35395] = "3:41",
	-- Divine Storm
	[53385] = "3:51",
	
	
	-- PRIESTS
	
	--[[ Disc ]]--
	
	--[[ Holy ]]--
	
	--[[ Shadow ]]--
	
	-- SHAMANS
	
	--[[ Elemental ]]--
	
	--[[ Enhancement ]]--
	
	--[[ Resto ]]--
	
	-- WARRIOR
	
	--[[ Arms ]]--
	
	--[[ Fury ]]--
	
	--[[ Protection ]]--
	
	-- WARLOCKS
	
	--[[ Affliction ]]--

	--[[ Demon ]]--
	
	--[[ Destro ]]--
}