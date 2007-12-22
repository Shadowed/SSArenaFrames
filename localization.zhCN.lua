if ( GetLocale() ~= "zhCN" ) then
	return
end

SSAFLocals = setmetatable({
	["SSArena Frames Slash Commands"] = "SSArena Frames命令行",
	["Water Elemental"] = "水元素",
	
	["ui - Pulls up the configuration page"] = "ui - 显示配置页面",
	
	["The Arena battle has begun!"] = "竞技比赛已经开始了!",
	
	["%s's pet, %s %s"] = "%s's pet, %s %s",
	["%s's pet, %s"] = "%s's pet, %s",

	["%s's %s"] = "%s's %s",
	["([a-zA-Z]+)%'s Minion"] = "([a-zA-Z]+)%'s 仆从",
	["([a-zA-Z]+)%'s Pet"] = "([a-zA-Z]+)%'s 宠物",
	
	["Pet"] = "宠物",
	["Minion"] = "仆从",
	["Enable for class"] = "开启职业支持",
	
	["Enabled"] = "开启",
	["Disabled"] = "关闭",
	
	["Classes: %s"] = "职业: %s",
	["Modifier: %s"] = "控制键: %s",
	["Mouse: %s"] = "鼠标: %s",
	
	["SSArena Frames"] = "SSArena Frames",
	
	["CLASSES"] = {
		["MAGE"] = "法师",
		["WARRIOR"] = "战士",
		["SHAMAN"] = "萨满祭司",
		["PALADIN"] = "圣骑士",
		["PRIEST"] = "牧师",
		["DRUID"] = "德鲁伊",
		["ROGUE"] = "潜行者",
		["HUNTER"] = "猎人",
		["WARLOCK"] = "术士",
	},
	
	["Arena Preparation"] = "竞技场准备",
	
	["General"] = "通用",
	["Frame"] = "窗口",
	["Color"] = "颜色",
	["Display"] = "显示",
	["None"] = "无",
	
	["Enable"] = "开启",
	["Modifiers"] = "控制键",
	["Macro Text"] = "宏内容",
	
	["Command to execute when clicking the frame using the above modifier/mouse button"] = "当使用控制键/鼠标单击窗口执行指令",
	
	["Enables the macro for a specific class, or for pets only."] = "为特定职业开启宏支持或只为宠物开启宏支持.",
	
	["All"] = "All",
	["CTRL"] = "CTRL",
	["SHIFT"] = "SHIFT",
	["ALT"] = "ALT",
	
	["Any button"] = "任意按键",
	["Left button"] = "左键",
	["Right button"] = "右键",
	["Middle button"] = "中间键",
	["Button 4"] = "4号按键",
	["Button 5"] = "5号按键",
	
	["Modifier key"] = "控制键",
	["Mouse button"] = "鼠标按键",
	
	["Click Actions"] = "单击执行动作",
	["Action #%d"] = "动作 #%d",
	
	["Edit"] = "Edit",
	["Mana"] = "Mana",
	
	["Enable macro case"] = "开启宏施法",
	["Enables the macro text entered to be ran on the specified modifier key and mouse button combo."] = "战斗中,在使用设定控制按键和鼠标按键时,开启宏命令运行支持.",
	
	["Report enemies to battleground chat"] = "发送消息到战场频道",
	["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."] = "当你的鼠标覆盖敌对目标时，发送他的名字,服务器,职业,种族,公会到战场频道.",
	
	["Show talents when available"] = "如果目标天赋是可用的将显示天赋",
	["Requires Remembrance, ArenaEnemyInfo or Tattle."] = "需要有记录插件支持, 例如:ArenaEnemyInfo 或 Tattle.",
	
	["Show enemy mage/warlock minions"] = "显示敌对方法师/术士的仆从",
	["Will display Warlock and Mage minions in the arena frames below all the players."] = "将显示法师和术士的仆从,在玩家的下方.",
	
	["Show enemy hunter pets"] = "显示敌对方猎人的宠物",
	["Will display Hunter pets in the arena frames below all the players."] = "将显示猎人的宠物,在玩家的下方.",
	
	["Show class icon"] = "显示职业图标",
	["Displays the players class icon to the left of the arena frame on their row."] = "显示敌对玩家的职业图标.",
	
	["Show row number"] = "显示行编号",
	["Shows the row number next to the name, can be used in place of names for other SSAF/SSPVP users to identify enemies."] = "在名字旁边显示行编号,可以方便和其他使用SSAF/SSPVP的用户,方便的用编号来代替人名标识敌对目标.",
	
	["Bar texture"] = "目标条的纹理",
	["Texture to use for health, mana and party target bars."] = "敌对目标生命魔法条的纹理.",

	["Pet health bar color"] = "宠物生命条的颜色",
	["Hunter pet health bar color."] = "猎人宠物条的颜色.",
	
	["Minion health bar color"] = "仆从生命条的颜色",
	["Warlock and Mage pet health bar color."] = "法师和术士仆从生命条的颜色.",
	
	["Name and health text font color"] = "名字和生命条的颜色和字体",
	
	["Lock arena frame"] = "锁定窗口",
	["Allows you to move the arena frames around, will also show a few examples. You will be unable to target anything while the arena frames are unlocked."] = "解锁后将显示一个测试窗口，允许你移动窗口. 但是你将不能选择目标,直到你锁定窗口为止.",
	
	
	["Frame Scale: %d%%"] = "窗口缩放比例: %d%%",
	["Allows you to increase, or decrease the total size of the arena frames."] = "允许你增加或减少整个窗口的大小.",
	
	["Show mana bars"] = "显示魔法条",
	["Shows a mana bar at the bottom of the health bar, requires you or a party member to target the enemy for them to update."] = "在生命条的下面显示魔法条, 这个功能需要你或你的使用了SSAF的队友选择了这个目标才会更新到最新值(SSAF有多人同步功能).",
	
	["Mana bar height"] = "魔法条的高度",
	["Height of the mana bars, the health bar will not resize for this however."] = "设置魔法条的高度, 生命条是系统默认不能设定大小.",
	
	["Show whos targeting an enemy"] = "显示敌对目标的目标",
	["Shows a little button to the right side of the enemies row for whos targeting them, it's colored by class of the person targeting them."] = "显示一个小按键在敌对目标行的右边,这个按键表示了敌对目标选择了谁为目标(你的队友), 按键颜色使用敌对目标对应的职业色彩.",
}, { __index = SSAFLocals })
