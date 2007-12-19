--简体中文汉化by二区轻风之语@钻石武力 血煞天魂
if( GetLocale() ~= "zhCN" ) then
	return
end

SSAFLocals = setmetatable({
SSAFLocals["SSArena Frames Slash Commands"] = "SSArena Frames命令行";
	SSAFLocals["Water Elemental"] = "水元素";
	
	SSAFLocals["ui - Pulls up the configuration page"] = "ui - 显示配置页面";
	
	SSAFLocals["The Arena battle has begun!"] = "竞技比赛已经开始了!";
	
	SSAFLocals["%s's pet, %s %s"] = "%s's 宠物, %s %s",
	SSAFLocals["%s's pet, %s"] = "%s's 宠物, %s",

	SSAFLocals["%s's %s"] = "%s's %s";
	SSAFLocals["([a-zA-Z]+)%'s Minion"] = "([a-zA-Z]+)%'s 仆从";
	SSAFLocals["([a-zA-Z]+)%'s Pet"] = "([a-zA-Z]+)%'s 宠物";
	
	SSAFLocals["Pet"] = "宠物";
	SSAFLocals["Minion"] = "仆从";
	SSAFLocals["Enable for class"] = "开启职业支持";
	
	SSAFLocals["Enabled"] = "开启";
	SSAFLocals["Disabled"] = "关闭";
	
	SSAFLocals["Classes: %s"] = "职业: %s";
	SSAFLocals["Modifier: %s"] = "控制键: %s";
	SSAFLocals["Mouse: %s"] = "鼠标: %s";
	
	SSAFLocals["SSArena Frames"] = "SSArena Frames",
	
	SSAFLocals["CLASSES"] = {
		["MAGE"] = "法师",
		["WARRIOR"] = "战士",
		["SHAMAN"] = "萨满祭司",
		["PALADIN"] = "圣骑士",
		["PRIEST"] = "牧师",
		["DRUID"] = "德鲁伊",
		["ROGUE"] = "潜行者",
		["HUNTER"] = "猎人",
		["WARLOCK"] = "术士",
	};
	
	SSAFLocals["Arena Preparation"] = "竞技场准备";
	
	SSAFLocals["General"] = "通用";
	SSAFLocals["Frame"] = "窗口";
	SSAFLocals["Color"] = "颜色";
	SSAFLocals["Display"] = "显示";
	SSAFLocals["None"] = "无";
	
	SSAFLocals["Enable"] = "开启";
	SSAFLocals["Modifiers"] = "控制键";
	SSAFLocals["Macro Text"] = "宏内容";
	
	SSAFLocals["Command to execute when clicking the frame using the above modifier/mouse button"] = "当使用控制键/鼠标单击窗口执行指令";
	
	SSAFLocals["Enables the macro for a specific class, or for pets only."] = "为特定职业开启宏支持或只为宠物开启宏支持.";
	
	SSAFLocals["All"] = "All";
	SSAFLocals["CTRL"] = "CTRL";
	SSAFLocals["SHIFT"] = "SHIFT";
	SSAFLocals["ALT"] = "ALT";
	
	SSAFLocals["Any button"] = "任意按键";
	SSAFLocals["Left button"] = "左键";
	SSAFLocals["Right button"] = "右键";
	SSAFLocals["Middle button"] = "中间键";
	SSAFLocals["Button 4"] = "4号按键";
	SSAFLocals["Button 5"] = "5号按键";
	
	SSAFLocals["Modifier key"] = "控制键";
	SSAFLocals["Mouse button"] = "鼠标按键";
	
	SSAFLocals["Click Actions"] = "单击执行动作";
	SSAFLocals["Action #%d"] = "动作 #%d";
	
	SSAFLocals["Edit"] = "编辑";
	SSAFLocals["Mana"] = "魔法";
	
	SSAFLocals["Enable macro case"] = "开启宏施法";
	SSAFLocals["Enables the macro text entered to be ran on the specified modifier key and mouse button combo."] = "战斗中,在使用设定控制按键和鼠标按键时,开启宏命令运行支持。";
	
	SSAFLocals["Report enemies to battleground chat"] = "发送消息到战场频道";
	SSAFLocals["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."] = "当你的鼠标覆盖敌对目标时，发送他的名字,服务器,职业,种族,公会到战场频道。";
	
	SSAFLocals["Show talents when available"] = "如果目标天赋是可用的将显示天赋";
	SSAFLocals["Requires Remembrance, ArenaEnemyInfo or Tattle."] = "需要有记录插件支持, 例如:ArenaEnemyInfo 或 Tattle。";
	
	SSAFLocals["Show enemy mage/warlock minions"] = "显示敌对方法师/术士的仆从";
	SSAFLocals["Will display Warlock and Mage minions in the arena frames below all the players."] = "在玩家的下方显示法师和术士的仆从。";
	
	SSAFLocals["Show enemy hunter pets"] = "显示敌对方猎人的宠物";
	SSAFLocals["Will display Hunter pets in the arena frames below all the players."] = "在玩家的下方显示猎人的宠物。";
	
	SSAFLocals["Show class icon"] = "显示职业图标";
	SSAFLocals["Displays the players class icon to the left of the arena frame on their row."] = "显示敌对玩家的职业图标。";
	
	SSAFLocals["Show row number"] = "显示行编号";
	SSAFLocals["Shows the row number next to the name, can be used in place of names for other SSAF/SSPVP users to identify enemies."] = "在名字旁边显示行编号,可以方便和其他使用SSAF/SSPVP的用户,方便的用编号来代替人名标识敌对目标。";
	
	SSAFLocals["Bar texture"] = "目标条的纹理";
	SSAFLocals["Texture to use for health, mana and party target bars."] = "敌对目标生命魔法条的纹理。";

	SSAFLocals["Pet health bar color"] = "宠物生命条的颜色";
	SSAFLocals["Hunter pet health bar color."] = "猎人宠物条的颜色。";
	
	SSAFLocals["Minion health bar color"] = "仆从生命条的颜色";
	SSAFLocals["Warlock and Mage pet health bar color."] = "法师和术士仆从生命条的颜色。";
	
	SSAFLocals["Name and health text font color"] = "名字和生命条的颜色和字体";
	
	SSAFLocals["Lock arena frame"] = "锁定窗口";
	SSAFLocals["Allows you to move the arena frames around, will also show a few examples. You will be unable to target anything while the arena frames are unlocked."] = "解锁后将显示一个测试窗口，允许你移动窗口， 但是你将不能选择目标,直到你锁定窗口为止。";
	
	
	SSAFLocals["Frame Scale: %d%%"] = "窗口缩放比例: %d%%";
	SSAFLocals["Allows you to increase, or decrease the total size of the arena frames."] = "允许你调整窗口的大小。";
	
	SSAFLocals["Show mana bars"] = "显示魔法条";
	SSAFLocals["Shows a mana bar at the bottom of the health bar, requires you or a party member to target the enemy for them to update."] = "在生命条的下面显示魔法条, 这个功能需要你或你的使用了SSAF的队友选择了这个目标才会更新到最新值(SSAF有多人同步功能)。";
	
	SSAFLocals["Mana bar height"] = "魔法条的高度";
	SSAFLocals["Height of the mana bars, the health bar will not resize for this however."] = "设置魔法条的高度, 生命条是系统默认不能设定大小。";
	
	SSAFLocals["Show whos targeting an enemy"] = "显示敌对目标的目标";
	SSAFLocals["Shows a little button to the right side of the enemies row for whos targeting them, it's colored by class of the person targeting them."] = "显示一个小按键在敌对目标行的右边,这个按键表示了敌对目标选择了谁为目标(你的队友), 按键颜色使用敌对目标对应的职业色彩。";
}, { __index = SSAFLocals })