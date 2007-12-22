if ( GetLocale() ~= "zhTW" ) then
	return
end

SSAFLocals = setmetatable({
	["SSArena Frames Slash Commands"] = "SSArena Frames命令行", 
	["Water Elemental"] = "水元素", 

	["ui - Pulls up the configuration page"] = "ui -顯示配置頁面", 

	["The Arena battle has begun!"] = "競技比賽已經開始了!", 

	["%s's pet, %s %s"] = "%s's pet, %s %s",
	["%s's pet, %s"] = "%s's pet, %s",

	["%s's %s"] = "%s's %s", 
	["([a-zA-Z]+)%'s Minion"] = "([a-zA-Z]+)%'s僕從", 
	["([a-zA-Z]+)%'s Pet"] = "([a-zA-Z]+)%'s寵物", 

	["Pet"] = "寵物", 
	["Minion"] = "僕從", 
	["Enable for class"] = "開啟職業支持", 

	["Enabled"] = "開啟", 
	["Disabled"] = "關閉", 

	["Classes: %s"] = "職業: %s", 
	["Modifier: %s"] = "控制鍵: %s", 
	["Mouse: %s"] = "鼠標: %s", 

	["SSArena Frames"] = "SSArena Frames",

	["CLASSES"] = { 
	["MAGE"] = "法師", 
	["WARRIOR"] = "戰士", 
	["SHAMAN"] = "薩滿祭司", 
	["PALADIN"] = "聖騎士", 
	["PRIEST"] = "牧師", 
	["DRUID"] = "德魯伊", 
	["ROGUE"] = "盜賊", 
	["HUNTER"] = "獵人", 
	["WARLOCK"] = "術士", 
	}, 

	["Arena Preparation"] = "競技場準備", 

	["General"] = "通用", 
	["Frame"] = "窗口", 
	["Color"] = "顏色", 
	["Display"] = "顯示", 
	["None"] = "無", 

	["Enable"] = "開啟", 
	["Modifiers"] = "控制鍵", 
	["Macro Text"] = "宏內容", 

	["Command to execute when clicking the frame using the above modifier/mouse button"] = "當使用控制鍵/鼠標單擊窗口執行指令", 

	["Enables the macro for a specific class, or for pets only."] = "為特定職業開啟宏支持或只為寵物開啟宏支持.", 

	["All"] = "All", 
	["CTRL"] = "CTRL", 
	["SHIFT"] = "SHIFT", 
	["ALT"] = "ALT", 

	["Any button"] = "任意按鍵", 
	["Left button"] = "左鍵", 
	["Right button"] = "右鍵", 
	["Middle button"] = "中間鍵", 
	["Button 4"] = "4號按鍵", 
	["Button 5"] = "5號按鍵", 

	["Modifier key"] = "控制鍵", 
	["Mouse button"] = "鼠標按鍵", 

	["Click Actions"] = "單擊執行動作", 
	["Action #%d"] = "動作#%d", 

	["Edit"] = "Edit", 
	["Mana"] = "Mana", 

	["Enable macro case"] = "開啟宏施法", 
	["Enables the macro text entered to be ran on the specified modifier key and mouse button combo."] = "戰鬥中,在使用設定控制按鍵和鼠標按鍵時,開啟宏命令運行支持.", 

	["Report enemies to battleground chat"] = "發送消息到戰場頻道", 
	["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."] = "當你的鼠標覆蓋敵對目標時，發送他的名字,服務器,職業,種族,公會到戰場頻道.", 

	["Show talents when available"] = "如果目標天賦是可用的將顯示天賦", 
	["Requires Remembrance, ArenaEnemyInfo or Tattle."] = "需要有記錄插件支持,例如:ArenaEnemyInfo或Tattle.", 

	["Show enemy mage/warlock minions"] = "顯示敵對方法師/術士的僕從", 
	["Will display Warlock and Mage minions in the arena frames below all the players."] = "將顯示法師和術士的僕從,在玩家的下方.", 

	["Show enemy hunter pets"] = "顯示敵對方獵人的寵物", 
	["Will display Hunter pets in the arena frames below all the players."] = "將顯示獵人的寵物,在玩家的下方.", 

	["Show class icon"] = "顯示職業圖標", 
	["Displays the players class icon to the left of the arena frame on their row."] = "顯示敵對玩家的職業圖標.", 

	["Show row number"] = "顯示行編號", 
	["Shows the row number next to the name, can be used in place of names for other SSAF/SSPVP users to identify enemies."] = "在名字旁邊顯示行編號,可以方便和其他使用SSAF/SSPVP的用戶,方便的用編號來代替人名標識敵對目標.", 

	["Bar texture"] = "目標條的紋理", 
	["Texture to use for health, mana and party target bars."] = "敵對目標生命魔法條的紋理.", 

	["Pet health bar color"] = "寵物生命條的顏色", 
	["Hunter pet health bar color."] = "獵人寵物條的顏色.", 

	["Minion health bar color"] = "僕從生命條的顏色", 
	["Warlock and Mage pet health bar color."] = "法師和術士僕從生命條的顏色.", 

	["Name and health text font color"] = "名字和生命條的顏色和字體", 

	["Lock arena frame"] = "鎖定窗口", 
	["Allows you to move the arena frames around, will also show a few examples. You will be unable to target anything while the arena frames are unlocked."] = "解鎖後將顯示一個測試窗口，允許你移動窗口.但是你將不能選擇目標,直到你鎖定窗口為止.", 


	["Frame Scale: %d%%"] = "窗口縮放比例: %d%%", 
	["Allows you to increase, or decrease the total size of the arena frames."] = "允許你增加或減少整個窗口的大小.", 

	["Show mana bars"] = "顯示魔法條", 
	["Shows a mana bar at the bottom of the health bar, requires you or a party member to target the enemy for them to update."] = "在生命條的下面顯示魔法條,這個功能需要你或你的使用了SSAF的隊友選擇了這個目標才會更新到最新值(SSAF有多人同步功能).", 

	["Mana bar height"] = "魔法條的高度", 
	["Height of the mana bars, the health bar will not resize for this however."] = "設置魔法條的高度,生命條是系統默認不能設定大小.", 

	["Show whos targeting an enemy"] = "顯示敵對目標的目標", 
	["Shows a little button to the right side of the enemies row for whos targeting them, it's colored by class of the person targeting them."] = "顯示一個小按鍵在敵對目標行的右邊,這個按鍵表示了敵對目標選擇了誰為目標(你的隊友),按鍵顏色使用敵對目標對應的職業色彩.", 
}, { __index =  SSAFLocals})

