-------------
-- version --
-------------
local fileVersion = 24

--prevent older/same version versions of this script from loading
if ModConfigMenu and ModConfigMenu.Version >= fileVersion then

	return ModConfigMenu

end

if not ModConfigMenu then

	ModConfigMenu = {}
	ModConfigMenu.Version = fileVersion
	
elseif ModConfigMenu.Version < fileVersion then

	local oldVersion = ModConfigMenu.Version
	
	--handle old versions

	ModConfigMenu.Version = fileVersion

end

-----------
-- setup --
-----------
Isaac.DebugString("Loading Mod Config Menu v" .. ModConfigMenu.Version)

--create the mod
ModConfigMenu.Mod = RegisterMod("Mod Config Menu", 1)

--require some lua libraries
local json = require("json")
local ScreenHelper = require("scripts.screenhelper")
local CallbackHelper = require("scripts.callbackhelper")
local TableHelper = require("scripts.tablehelper")
local InputHelper = require("scripts.inputhelper")

--cached values
local vecZero = Vector(0,0)

local colorDefault = Color(1,1,1,1,0,0,0)
local colorHalf = Color(1,1,1,0.5,0,0,0)


--------------------
--CUSTOM CALLBACKS--
--------------------

--MCM_POST_MODIFY_HUD_OFFSET
--gets called when the hud offset setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when hud offset is changed
--function(number hudOffset)
CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET = 4300

--this will make ScreenHelper's offset match MCM's offset when it is changed
CallbackHelper.AddCallback(ModConfigMenu.Mod, CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET, function(_, hudOffset)
	ScreenHelper.SetOffset(hudOffset)
end)

--MCM_POST_MODIFY_OVERLAYS
--gets called when the overlays setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when overlays are enabled or disabled
--function(boolean overlaysEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_OVERLAYS = 4301

--MCM_POST_MODIFY_CHARGE_BARS
--gets called when the charge bars setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when charge bars are enabled or disabled
--function(boolean chargeBarsEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_CHARGE_BARS = 4302

--MCM_POST_MODIFY_BIG_BOOKS
--gets called when the big books setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when big books are enabled or disabled
--function(boolean bigBooksEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_BIG_BOOKS = 4303

--MCM_POST_MODIFY_ANNOUNCER
--gets called when the announcer setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when the announcer mode is changed
--function(number announcerMode)
CallbackHelper.Callbacks.MCM_POST_MODIFY_ANNOUNCER = 4304


----------
--SAVING--
----------

ModConfigMenu.ConfigDefault = {

	["General"] = {
	
		HudOffset = 0, -- 0 to 10
		Overlays = true,
		ChargeBars = false,
		BigBooks = true,
		Announcer = 0 -- 0 = sometimes, 1 = never, 2 = always
		
	},

	["Mod Config Menu"] = {
	
		OpenMenuKeyboard = Keyboard.KEY_L,
		OpenMenuController = InputHelper.Controller.STICK_RIGHT,
		
		HideHudInMenu = true,
		ResetToDefault = Keyboard.KEY_R,
		ShowControls = true
		
	},
	
	--last button pressed tracker
	LastBackPressed = Keyboard.KEY_ESCAPE,
	LastSelectPressed = Keyboard.KEY_ENTER
	
}
ModConfigMenu.Config = TableHelper.CopyTable(ModConfigMenu.ConfigDefault)

function ModConfigMenu.GetSave()
	
	local saveData = TableHelper.CopyTable(ModConfigMenu.ConfigDefault)
	saveData = TableHelper.FillTable(saveData, ModConfigMenu.Config)
	
	saveData = json.encode(saveData)
	
	return saveData
	
end

function ModConfigMenu.LoadSave(fromData)

	if fromData and ((type(fromData) == "string" and json.decode(fromData)) or type(fromData) == "table") then
	
		local saveData = TableHelper.CopyTable(ModConfigMenu.ConfigDefault)
		
		if type(fromData) == "string" then
			fromData = json.decode(fromData)
		end
		saveData = TableHelper.FillTable(saveData, fromData)
		
		local currentData = TableHelper.CopyTable(ModConfigMenu.Config)
		saveData = TableHelper.FillTable(currentData, saveData)
		
		ModConfigMenu.Config = TableHelper.CopyTable(saveData)
		
		--make sure ScreenHelper's offset matches MCM's offset
		ScreenHelper.SetOffset(ModConfigMenu.Config["General"].HudOffset)
		
		return saveData
		
	end
	
end


---------------------------
--startup version display--
---------------------------

local versionPrintFont = Font()
versionPrintFont:Load("font/pftempestasevencondensed.fnt")

local versionPrintTimer = 0

CallbackHelper.AddCallback(ModConfigMenu.Mod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)

	if ModConfigMenu.Config["Mod Config Menu"].ShowControls then
	
		versionPrintTimer = 120
		
	end
	
end)

ModConfigMenu.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()

	if versionPrintTimer > 0 then
	
		versionPrintTimer = versionPrintTimer - 1
		
	end
	
end)

ModConfigMenu.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()

	if versionPrintTimer > 0 then
	
		local bottomRight = ScreenHelper.GetScreenBottomRight(0)

		local openMenuButton = Keyboard.KEY_F10
		if type(ModConfigMenu.Config["Mod Config Menu"].OpenMenuKeyboard) == "number" and ModConfigMenu.Config["Mod Config Menu"].OpenMenuKeyboard > -1 then
			openMenuButton = ModConfigMenu.Config["Mod Config Menu"].OpenMenuKeyboard
		end

		local openMenuButtonString = "Unknown Key"
		if InputHelper.KeyboardToString[openMenuButton] then
			openMenuButtonString = InputHelper.KeyboardToString[openMenuButton]
		end
		
		local text = "Press " .. openMenuButtonString .. " to open Mod Config Menu"
		local versionPrintColor = KColor(1, 1, 0, (math.min(versionPrintTimer, 60)/60) * 0.5)
		versionPrintFont:DrawString(text, 0, bottomRight.Y - 28, versionPrintColor, bottomRight.X, true)
		
	end
	
end)

------------------------------------
--set up the menu sprites and font--
------------------------------------
ModConfigMenu.IsVisible = false

function ModConfigMenu.GetMenuAnm2Sprite(animation, frame, color)

	local sprite = Sprite()
	
	sprite:Load("gfx/ui/modconfig/menu.anm2", true)
	sprite:SetFrame(animation or "Idle", frame or 0)
	
	if color then
		sprite.Color = color
	end
	
	return sprite
	
end

--main menu sprites
local MenuSprite = ModConfigMenu.GetMenuAnm2Sprite("Idle", 0)
local PopupSprite = ModConfigMenu.GetMenuAnm2Sprite("Popup", 0)

--main cursors
local CursorSpriteRight = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 0)
local CursorSpriteUp = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 1)
local CursorSpriteDown = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 2)

--subcategory pane cursors
local SubcategoryCursorSpriteLeft = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 3, colorHalf)
local SubcategoryCursorSpriteRight = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 0, colorHalf)

--options pane cursors
local OptionsCursorSpriteUp = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 1, colorHalf)
local OptionsCursorSpriteDown = ModConfigMenu.GetMenuAnm2Sprite("Cursor", 2, colorHalf)

--other options pane objects
local SubcategoryDividerSprite = ModConfigMenu.GetMenuAnm2Sprite("Divider", 0, colorHalf)
local SliderSprite = ModConfigMenu.GetMenuAnm2Sprite("Slider1", 0)

--strikeout
local StrikeOutSprite = ModConfigMenu.GetMenuAnm2Sprite("Strikeout", 0)

--back/select corner papers
local CornerSelect = ModConfigMenu.GetMenuAnm2Sprite("BackSelect", 0)
local CornerBack = ModConfigMenu.GetMenuAnm2Sprite("BackSelect", 1)
local CornerOpen = ModConfigMenu.GetMenuAnm2Sprite("BackSelect", 2)
local CornerExit = ModConfigMenu.GetMenuAnm2Sprite("BackSelect", 3)

--fonts
local Font10 = Font()
Font10:Load("font/teammeatfont10.fnt")

local Font12 = Font()
Font12:Load("font/teammeatfont12.fnt")

local Font16Bold = Font()
Font16Bold:Load("font/teammeatfont16bold.fnt")

--popups
ModConfigMenu.PopupGfx = {
	THIN_SMALL = "gfx/ui/modconfig/popup_thin_small.png",
	THIN_MEDIUM = "gfx/ui/modconfig/popup_thin_medium.png",
	THIN_LARGE = "gfx/ui/modconfig/popup_thin_large.png",
	WIDE_SMALL = "gfx/ui/modconfig/popup_wide_small.png",
	WIDE_MEDIUM = "gfx/ui/modconfig/popup_wide_medium.png",
	WIDE_LARGE = "gfx/ui/modconfig/popup_wide_large.png"
}


-------------------------
--add setting functions--
-------------------------
ModConfigMenu.OptionType = {
	TEXT = 1,
	SPACE = 2,
	SCROLL = 3,
	BOOLEAN = 4,
	NUMBER = 5,
	KEYBIND_KEYBOARD = 6,
	KEYBIND_CONTROLLER = 7,
	TITLE = 8
}

ModConfigMenu.MenuData = {}

function ModConfigMenu.GetCategoryIDByName(name)

	local categoryID = nil
	
	for i=1, #ModConfigMenu.MenuData do
		if name == ModConfigMenu.MenuData[i].Name then
			categoryID = i
			break
		end
	end
	
	return categoryID
	
end

function ModConfigMenu.GetSubcategoryIDByName(categoryID, name)

	local subcategoryID = nil
	
	for i=1, #ModConfigMenu.MenuData[categoryID].Subcategories do
		if name == ModConfigMenu.MenuData[categoryID].Subcategories[i].Name then
			subcategoryID = i
			break
		end
	end
	
	return subcategoryID
	
end

function ModConfigMenu.UpdateCategory(categoryName, dataTable)

	if type(categoryName) ~= "string" then
		error("ModConfigMenu.UpdateCategory - No valid category name provided", 2)
	end

	local categoryToChange = ModConfigMenu.GetCategoryIDByName(categoryName)
	if categoryToChange == nil then
		categoryToChange = #ModConfigMenu.MenuData+1
		ModConfigMenu.MenuData[categoryToChange] = {}
		ModConfigMenu.MenuData[categoryToChange].Subcategories = {}
	end
	
	ModConfigMenu.MenuData[categoryToChange].Name = tostring(categoryName)
	
	if dataTable.Info then
		ModConfigMenu.MenuData[categoryToChange].Info = dataTable.Info
	end
	
	if dataTable.IsOld then
		ModConfigMenu.MenuData[categoryToChange].IsOld = dataTable.IsOld
	end
	
end

function ModConfigMenu.UpdateSubcategory(categoryName, subcategoryName, dataTable)

	if type(categoryName) ~= "string" then
		error("ModConfigMenu.UpdateSubcategory - No valid category name provided", 2)
	end

	if type(subcategoryName) ~= "string" then
		error("ModConfigMenu.UpdateSubcategory - No valid subcategory name provided", 2)
	end
	
	local categoryToChange = ModConfigMenu.GetCategoryIDByName(categoryName)
	if categoryToChange == nil then
		categoryToChange = #ModConfigMenu.MenuData+1
		ModConfigMenu.MenuData[categoryToChange] = {}
		ModConfigMenu.MenuData[categoryToChange].Name = tostring(categoryName)
		ModConfigMenu.MenuData[categoryToChange].Subcategories = {}
	end
	
	local subcategoryToChange = ModConfigMenu.GetSubcategoryIDByName(categoryToChange, subcategoryName)
	if subcategoryToChange == nil then
		subcategoryToChange = #ModConfigMenu.MenuData[categoryToChange].Subcategories+1
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange] = {}
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options = {}
	end
	
	ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Name = tostring(subcategoryName)
	
	if dataTable.Info then
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Info = dataTable.Info
	end
	
end

function ModConfigMenu.AddSetting(categoryName, subcategoryName, settingTable)

	if settingTable == nil then
		settingTable = subcategoryName
		subcategoryName = nil
	end
	
	if categoryName == nil then
		error("ModConfigMenu.AddSetting - No valid category name provided", 2)
	end
	
	if subcategoryName == nil then
		subcategoryName = "Uncategorized"
	end
	
	local categoryToChange = ModConfigMenu.GetCategoryIDByName(categoryName)
	if categoryToChange == nil then
		categoryToChange = #ModConfigMenu.MenuData+1
		ModConfigMenu.MenuData[categoryToChange] = {}
		ModConfigMenu.MenuData[categoryToChange].Name = tostring(categoryName)
		ModConfigMenu.MenuData[categoryToChange].Subcategories = {}
	end
	
	local subcategoryToChange = ModConfigMenu.GetSubcategoryIDByName(categoryToChange, subcategoryName)
	if subcategoryToChange == nil then
		subcategoryToChange = #ModConfigMenu.MenuData[categoryToChange].Subcategories+1
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange] = {}
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Name = tostring(subcategoryName)
		ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options = {}
	end
	
	ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options[#ModConfigMenu.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options+1] = settingTable
	
	return settingTable
	
end

function ModConfigMenu.AddText(categoryName, subcategoryName, text, color)

	if color == nil and type(text) ~= "string" and type(text) ~= "function" then
		color = text
		text = subcategoryName
		subcategoryName = nil
	end
	
	if categoryName == nil then
		error("ModConfigMenu.AddText - No valid category name provided", 2)
	end
	
	local settingTable = {
		Type = ModConfigMenu.OptionType.TEXT,
		Display = text,
		Color = color,
		NoCursorHere = true
	}
	
	return ModConfigMenu.AddSetting(categoryName, subcategoryName, settingTable)
	
end

function ModConfigMenu.AddTitle(categoryName, subcategoryName, text, color)

	if color == nil and type(text) ~= "string" and type(text) ~= "function" then
		color = text
		text = subcategoryName
		subcategoryName = nil
	end
	
	if categoryName == nil then
		error("ModConfigMenu.AddTitle - No valid category name provided", 2)
	end
	
	local settingTable = {
		Type = ModConfigMenu.OptionType.TITLE,
		Display = text,
		Color = color,
		NoCursorHere = true
	}
	
	return ModConfigMenu.AddSetting(categoryName, subcategoryName, settingTable)
	
end

function ModConfigMenu.AddSpace(categoryName, subcategoryName)
	
	if categoryName == nil then
		error("ModConfigMenu.AddSpace - No valid category name provided", 2)
	end

	local settingTable = {
		Type = ModConfigMenu.OptionType.SPACE
	}
	
	return ModConfigMenu.AddSetting(categoryName, subcategoryName, settingTable)
	
end

--need to check if display device works and add functionality to it
function ModConfigMenu.SimpleAddSetting(settingType, categoryName, subcategoryName, configTableAttribute, minValue, maxValue, modifyBy, defaultValue, displayText, displayValueProxies, displayDevice, info, color, functionName)
	
	--set default values
	if defaultValue == nil then
		if settingType == ModConfigMenu.OptionType.BOOLEAN then
			defaultValue = false
		else
			defaultValue = 0
		end
	end
	
	if settingType == ModConfigMenu.OptionType.NUMBER then
		minValue = minValue or 0
		maxValue = maxValue or 10
		modifyBy = modifyBy or 1
	else
		minValue = nil
		maxValue = nil
		modifyBy = nil
	end
	
	functionName = functionName or "SimpleAddSetting"
	
	--erroring
	if categoryName == nil then
		error("ModConfigMenu." .. tostring(functionName) .. " - No valid category name provided", 2)
	end
	if configTableAttribute == nil then
		error("ModConfigMenu." .. tostring(functionName) .. " - No valid config table attribute provided", 2)
	end
	
	--create config value
	ModConfigMenu.Config[categoryName] = ModConfigMenu.Config[categoryName] or {}
	if ModConfigMenu.Config[categoryName][configTableAttribute] == nil then
		ModConfigMenu.Config[categoryName][configTableAttribute] = defaultValue
	end
	
	ModConfigMenu.ConfigDefault[categoryName] = ModConfigMenu.ConfigDefault[categoryName] or {}
	if ModConfigMenu.ConfigDefault[categoryName][configTableAttribute] == nil then
		ModConfigMenu.ConfigDefault[categoryName][configTableAttribute] = defaultValue
	end
	
	--setting
	local settingTable = {
		Type = settingType,
		CurrentSetting = function()
			return ModConfigMenu.Config[categoryName][configTableAttribute]
		end,
		Default = defaultValue,
		Display = function(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
		
			local currentValue = ModConfigMenu.Config[categoryName][configTableAttribute]
		
			local displayString = ""
			
			if displayText then
				displayString = displayText .. ": "
			end
			
			if settingType == ModConfigMenu.OptionType.SCROLL then
			
				displayString = displayString .. "$scroll" .. tostring(math.floor(currentValue))
				
			elseif settingType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD then
				
				local key = "None"
				
				if currentValue > -1 then
				
					key = "Unknown Key"
					
					if InputHelper.KeyboardToString[currentValue] then
						key = InputHelper.KeyboardToString[currentValue]
					end
					
				end
				
				displayString = displayString .. key
				
				if displayDevice then
					
					displayString = displayString .. " (keyboard)"
					
				end
				
			elseif settingType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
				
				local key = "None"
				
				if currentValue > -1 then
				
					key = "Unknown Button"
					
					if InputHelper.ControllerToString[currentValue] then
						key = InputHelper.ControllerToString[currentValue]
					end
					
				end
				
				displayString = displayString .. key
				
				if displayDevice then
					
					displayString = displayString .. " (controller)"
					
				end
				
			elseif displayValueProxies and displayValueProxies[currentValue] then
			
				displayString = displayString .. tostring(displayValueProxies[currentValue])
				
			else
			
				displayString = displayString .. tostring(currentValue)
				
			end
			
			return displayString
			
		end,
		OnChange = function(currentValue)
		
			if not currentNum then
			
				if settingType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or settingType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
					currentNum = -1
				end
				
			end
			
			ModConfigMenu.Config[categoryName][configTableAttribute] = currentValue
			
		end,
		Info = info,
		Color = color
	}
	
	if settingType == ModConfigMenu.OptionType.NUMBER then
	
		settingTable.Minimum = minValue
		settingTable.Maximum = maxValue
		settingTable.ModifyBy = modifyBy
		
	elseif settingType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or settingType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
		
		settingTable.PopupGfx = ModConfigMenu.PopupGfx.WIDE_SMALL
		settingTable.Popup = function()
		
			local currentValue = ModConfigMenu.Config[categoryName][configTableAttribute]
		
			local goBackString = "back"
			if ModConfigMenu.Config.LastBackPressed then
			
				if InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed]
				elseif InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed]
				end
				
			end
			
			local keepSettingString1 = ""
			local keepSettingString2 = ""
			if currentValue > -1 then
			
				local currentSettingString = nil
				if (settingType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD and InputHelper.KeyboardToString[currentValue]) then
					currentSettingString = InputHelper.KeyboardToString[currentValue]
				elseif (settingType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER and InputHelper.ControllerToString[currentValue]) then
					currentSettingString = InputHelper.ControllerToString[currentValue]
				end
				
				keepSettingString1 = "This setting is currently set to \"" .. currentSettingString .. "\"."
				keepSettingString2 = "Press this button to keep it unchanged."
				
			end
			
			local deviceString = ""
			if settingType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD then
				deviceString = "keyboard"
			elseif settingType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
				deviceString = "controller"
			end
			
			return {
				"Press a button on your " .. deviceString .. " to change this setting.",
				"",
				keepSettingString1,
				keepSettingString2,
				"",
				"Press \"" .. goBackString .. "\" to go back and clear this setting."
			}
			
		end
		
	end
	
	return ModConfigMenu.AddSetting(categoryName, subcategoryName, settingTable)
	
end

function ModConfigMenu.AddBooleanSetting(categoryName, subcategoryName, configTableAttribute, defaultValue, displayText, displayValueProxies, info, color)

	--move args around
	if type(configTableAttribute) ~= "string" then
		color = info
		info = displayValueProxies
		displayValueProxies = displayText
		displayText = defaultValue
		defaultValue = configTableAttribute
		configTableAttribute = subcategoryName
		subcategoryName = nil
	end
	
	if type(defaultValue) ~= "boolean" then
		color = info
		info = displayValueProxies
		displayValueProxies = displayText
		displayText = defaultValue
		defaultValue = false
	end

	if type(displayValueProxies) ~= "table" or type(info) == "userdata" or type(info) == "nil" then
		color = info
		info = displayValueProxies
		displayValueProxies = nil
	end
	
	return ModConfigMenu.SimpleAddSetting(ModConfigMenu.OptionType.BOOLEAN, categoryName, subcategoryName, configTableAttribute, nil, nil, nil, defaultValue, displayText, displayValueProxies, nil, info, color, "AddBooleanSetting")
	
end

function ModConfigMenu.AddNumberSetting(categoryName, subcategoryName, configTableAttribute, minValue, maxValue, modifyBy, defaultValue, displayText, displayValueProxies, info, color)

	--move args around
	if type(configTableAttribute) ~= "string" then
		color = info
		info = displayValueProxies
		displayValueProxies = displayText
		displayText = defaultValue
		defaultValue = modifyBy
		modifyBy = maxValue
		maxValue = minValue
		minValue = configTableAttribute
		configTableAttribute = subcategoryName
		subcategoryName = nil
	end
	
	if type(defaultValue) == "string" then
		color = info
		info = displayValueProxies
		displayValueProxies = displayText
		displayText = defaultValue
		defaultValue = modifyBy
		modifyBy = nil
	end

	if type(displayValueProxies) ~= "table" or type(info) == "userdata" or type(info) == "nil" then
		color = info
		info = displayValueProxies
		displayValueProxies = nil
	end
	
	--set default values
	defaultValue = defaultValue or 0
	minValue = minValue or 0
	maxValue = maxValue or 10
	modifyBy = modifyBy or 1
	
	return ModConfigMenu.SimpleAddSetting(ModConfigMenu.OptionType.NUMBER, categoryName, subcategoryName, configTableAttribute, minValue, maxValue, modifyBy, defaultValue, displayText, displayValueProxies, nil, info, color, "AddNumberSetting")
	
end

function ModConfigMenu.AddScrollSetting(categoryName, subcategoryName, configTableAttribute, defaultValue, displayText, info, color)

	--move args around
	if type(configTableAttribute) ~= "string" then
		color = info
		info = displayText
		displayText = defaultValue
		defaultValue = configTableAttribute
		configTableAttribute = subcategoryName
		subcategoryName = nil
	end
	
	if type(defaultValue) ~= "number" then
		color = info
		info = displayText
		displayText = defaultValue
		defaultValue = nil
	end
	
	--set default values
	defaultValue = defaultValue or 0

	return ModConfigMenu.SimpleAddSetting(ModConfigMenu.OptionType.SCROLL, categoryName, subcategoryName, configTableAttribute, nil, nil, nil, defaultValue, displayText, nil, nil, info, color, "AddScrollSetting")
	
end

function ModConfigMenu.AddKeyboardSetting(categoryName, subcategoryName, configTableAttribute, defaultValue, displayText, displayDevice, info, color)

	--move args around
	if type(configTableAttribute) ~= "string" then
		color = info
		info = displayDevice
		displayDevice = displayText
		displayText = defaultValue
		defaultValue = configTableAttribute
		configTableAttribute = subcategoryName
		subcategoryName = nil
	end
	
	if type(defaultValue) ~= "number" then
		color = info
		info = displayText
		displayText = defaultValue
		defaultValue = nil
	end
	
	if type(displayDevice) ~= "boolean" then
		color = info
		info = displayDevice
		displayDevice = false
	end
	
	--set default values
	defaultValue = defaultValue or -1

	return ModConfigMenu.SimpleAddSetting(ModConfigMenu.OptionType.KEYBIND_KEYBOARD, categoryName, subcategoryName, configTableAttribute, nil, nil, nil, defaultValue, displayText, nil, displayDevice, info, color, "AddKeyboardSetting")
	
end

function ModConfigMenu.AddControllerSetting(categoryName, subcategoryName, configTableAttribute, defaultValue, displayText, displayDevice, info, color)

	--move args around
	if type(configTableAttribute) ~= "string" then
		color = info
		info = displayDevice
		displayDevice = displayText
		displayText = defaultValue
		defaultValue = configTableAttribute
		configTableAttribute = subcategoryName
		subcategoryName = nil
	end
	
	if type(defaultValue) ~= "number" then
		color = info
		info = displayText
		displayText = defaultValue
		defaultValue = nil
	end
	
	if type(displayDevice) ~= "boolean" then
		color = info
		info = displayDevice
		displayDevice = false
	end
	
	--set default values
	defaultValue = defaultValue or -1

	return ModConfigMenu.SimpleAddSetting(ModConfigMenu.OptionType.KEYBIND_CONTROLLER, categoryName, subcategoryName, configTableAttribute, nil, nil, nil, defaultValue, displayText, nil, displayDevice, info, color, "AddControllerSetting")
	
end

--------------------------
--GENERAL SETTINGS SETUP--
--------------------------
ModConfigMenu.UpdateCategory("General", {
	Info = "Settings that affect the majority of mods"
})


----------------------
--HUD OFFSET SETTING--
----------------------
local hudOffsetSetting = ModConfigMenu.AddScrollSetting(
	"General", --category
	"HudOffset", --attribute in table
	ModConfigMenu.ConfigDefault["General"].HudOffset, --default value
	"Hud Offset", --display text
	{ --info
		"How far from the corners of the screen",
		"custom hud elements will be.",
		"Try to make this match your base-game setting."
	}
)

--set up screen corner display for hud offset
local HudOffsetVisualTopLeft = ModConfigMenu.GetMenuAnm2Sprite("Offset", 0)
local HudOffsetVisualTopRight = ModConfigMenu.GetMenuAnm2Sprite("Offset", 1)
local HudOffsetVisualBottomRight = ModConfigMenu.GetMenuAnm2Sprite("Offset", 2)
local HudOffsetVisualBottomLeft = ModConfigMenu.GetMenuAnm2Sprite("Offset", 3)

hudOffsetSetting.HideControls = true -- hide controls so the screen corner graphics are easier to see

local oldHudOffsetDisplay = hudOffsetSetting.Display
hudOffsetSetting.Display = function(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)

	if cursorIsAtThisOption then
	
		--render the visual
		HudOffsetVisualBottomRight:Render(ScreenHelper.GetScreenBottomRight(), vecZero, vecZero)
		HudOffsetVisualBottomLeft:Render(ScreenHelper.GetScreenBottomLeft(), vecZero, vecZero)
		HudOffsetVisualTopRight:Render(ScreenHelper.GetScreenTopRight(), vecZero, vecZero)
		HudOffsetVisualTopLeft:Render(ScreenHelper.GetScreenTopLeft(), vecZero, vecZero)
		
	end

	return oldHudOffsetDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
	
end

--set up callback
local oldHudOffsetOnChange = hudOffsetSetting.OnChange
hudOffsetSetting.OnChange = function(currentValue)

	oldHudOffsetOnChange(currentValue)
	
	--MCM_POST_MODIFY_HUD_OFFSET
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET, --callback id
		nil, --function to handle it
		{currentValue} --args to send
	)
	
end


--------------------
--OVERLAYS SETTING--
--------------------
local overlaySetting = ModConfigMenu.AddBooleanSetting(
	"General", --category
	"Overlays", --attribute in table
	ModConfigMenu.ConfigDefault["General"].Overlays, --default value
	"Overlays", --display text
	{ --value display text
		[true] = "On",
		[false] = "Off"
	},
	{ --info
		"Enable or disable custom visual overlays,",
		"like screen-wide fog."
	}
)

--set up callback
local oldOverlayOnChange = overlaySetting.OnChange
overlaySetting.OnChange = function(currentValue)

	oldOverlayOnChange(currentValue)
	
	--MCM_POST_MODIFY_OVERLAYS
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.MCM_POST_MODIFY_OVERLAYS, --callback id
		nil, --function to handle it
		{currentValue} --args to send
	)
	
end


-----------------------
--CHARGE BARS SETTING--
-----------------------
local chargeBarsSetting = ModConfigMenu.AddBooleanSetting(
	"General", --category
	"ChargeBars", --attribute in table
	ModConfigMenu.ConfigDefault["General"].ChargeBars, --default value
	"Charge Bars", --display text
	{ --value display text
		[true] = "On",
		[false] = "Off"
	},
	{ --info
		"Enable or disable custom charge bar visuals",
		"for mod effects, like those from chargable items."
	}
)

--set up callback
local oldChargeBarsOnChange = chargeBarsSetting.OnChange
chargeBarsSetting.OnChange = function(currentValue)

	oldChargeBarsOnChange(currentValue)
	
	--MCM_POST_MODIFY_CHARGE_BARS
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.MCM_POST_MODIFY_CHARGE_BARS, --callback id
		nil, --function to handle it
		{currentValue} --args to send
	)
	
end


---------------------
--BIG BOOKS SETTING--
---------------------
local bigBooksSetting = ModConfigMenu.AddBooleanSetting(
	"General", --category
	"BigBooks", --attribute in table
	ModConfigMenu.ConfigDefault["General"].BigBooks, --default value
	"Bigbooks", --display text
	{ --value display text
		[true] = "On",
		[false] = "Off"
	},
	{ --info
		"Enable or disable custom bigbook overlays,",
		"like those which appear when an active item is used."
	}
)

--set up callback
local oldBigBooksOnChange = bigBooksSetting.OnChange
bigBooksSetting.OnChange = function(currentValue)

	oldBigBooksOnChange(currentValue)
	
	--MCM_POST_MODIFY_BIG_BOOKS
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.MCM_POST_MODIFY_BIG_BOOKS, --callback id
		nil, --function to handle it
		{currentValue} --args to send
	)
	
end


---------------------
--ANNOUNCER SETTING--
---------------------
local announcerSetting = ModConfigMenu.AddNumberSetting(
	"General", --category
	"Announcer", --attribute in table
	0, --minimum value
	2, --max value
	ModConfigMenu.ConfigDefault["General"].Announcer, --default value,
	"Announcer", --display text
	{ --value display text
		[0] = "Sometimes",
		[1] = "Never",
		[2] = "Always"
	},
	{ --info
		"Choose how often a voice-over will play,",
		"like when a pocket item (pill or card) is used."
	}
)

--set up callback
local oldAnnouncerOnChange = announcerSetting.OnChange
announcerSetting.OnChange = function(currentValue)

	oldAnnouncerOnChange(currentValue)
	
	--MCM_POST_MODIFY_ANNOUNCER
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.MCM_POST_MODIFY_ANNOUNCER, --callback id
		nil, --function to handle it
		{currentValue} --args to send
	)
	
end


--------------------------
--GENERAL SETTINGS CLOSE--
--------------------------

ModConfigMenu.AddSpace("General") --SPACE

ModConfigMenu.AddText("General", "These settings apply to")
ModConfigMenu.AddText("General", "all mods which support them")


----------------------------------
--MOD CONFIG MENU SETTINGS SETUP--
----------------------------------

ModConfigMenu.UpdateCategory("Mod Config Menu", {
	Info = {
		"Settings specific to Mod Config Menu",
		"Change keybindings for the menu here"
	}
})

ModConfigMenu.AddTitle("Mod Config Menu", "Version " .. tostring(ModConfigMenu.Version) .. " !") --VERSION INDICATOR

ModConfigMenu.AddSpace("Mod Config Menu") --SPACE


----------------------
--OPEN MENU KEYBOARD--
----------------------
local openMenuKeyboardSetting = ModConfigMenu.AddKeyboardSetting(
	"Mod Config Menu", --category
	"OpenMenuKeyboard", --attribute in table
	ModConfigMenu.ConfigDefault["Mod Config Menu"].OpenMenuKeyboard, --default value
	"Open Menu", --display text
	true, --if (keyboard) is displayed after the key text
	{ --info
		"Choose what button on your keyboard",
		"will open Mod Config Menu."
	}
)

openMenuKeyboardSetting.IsOpenMenuKeybind = true


------------------------
--OPEN MENU CONTROLLER--
------------------------
local openMenuControllerSetting = ModConfigMenu.AddControllerSetting(
	"Mod Config Menu", --category
	"OpenMenuController", --attribute in table
	ModConfigMenu.ConfigDefault["Mod Config Menu"].OpenMenuController, --default value
	"Open Menu", --display text
	true, --if (controller) is displayed after the key text
	{ --info
		"Choose what button on your controller",
		"will open Mod Config Menu."
	}
)

openMenuControllerSetting.IsOpenMenuKeybind = true

--f10 note
ModConfigMenu.AddText("Mod Config Menu", "F10 will always open this menu.")

ModConfigMenu.AddSpace("Mod Config Menu") --SPACE


------------
--HIDE HUD--
------------
local hideHudSetting = ModConfigMenu.AddBooleanSetting(
	"Mod Config Menu", --category
	"HideHudInMenu", --attribute in table
	ModConfigMenu.ConfigDefault["Mod Config Menu"].HideHudInMenu, --default value
	"Hide HUD", --display text
	{ --value display text
		[true] = "Yes",
		[false] = "No"
	},
	"Enable or disable the hud when this menu is open." --info
)

--actively modify the hud visibility as this setting changes
local oldHideHudOnChange = hideHudSetting.OnChange
hideHudSetting.OnChange = function(currentValue)

	oldHideHudOnChange(currentValue)
	
	local game = Game()
	local seeds = game:GetSeeds()
	
	if currentValue then
		if not seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
			seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
		end
	else
		if seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
			seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
		end
	end

end


----------------------------
--RESET TO DEFAULT KEYBIND--
----------------------------
local resetKeybindSetting = ModConfigMenu.AddKeyboardSetting(
	"Mod Config Menu", --category
	"ResetToDefault", --attribute in table
	ModConfigMenu.ConfigDefault["Mod Config Menu"].ResetToDefault, --default value
	"Reset To Default Keybind", --display text
	{ --info
		"Press this button on your keyboard",
		"to reset a setting to its default value."
	}
)

resetKeybindSetting.IsResetKeybind = true


-----------------
--SHOW CONTROLS--
-----------------
local hideHudSetting = ModConfigMenu.AddBooleanSetting(
	"Mod Config Menu", --category
	"ShowControls", --attribute in table
	ModConfigMenu.ConfigDefault["Mod Config Menu"].ShowControls, --default value
	"Show Controls", --display text
	{ --value display text
		[true] = "Yes",
		[false] = "No"
	},
	{ --info
		"Disable this to remove the back and select",
		"widgets at the lower corners of the screen",
		"and remove the bottom start-up message."
	}
)


ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)

ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 2", "Yep its a test", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 2", "Yep its a test", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 3", "test 1", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 3", "test 2", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 3", "test 3", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 3", "test 4", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 3", "test 5", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 3", "test 6", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)

ModConfigMenu.AddText("This is a test 4", "subcat", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 5", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 6", "whee what am i doing this is wacky")
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddBooleanSetting(
	"This is a test 7", --category
	"eeee", --attribute in table
	false, --default value
	"what is this" --display text
)
ModConfigMenu.AddText("This is a test 8", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 9", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 10", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 11", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 12", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 13", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 14", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 15", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 16", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 17", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 18", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 19", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 20", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 21", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 22", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 23", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 24", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 25", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 26", "whee what am i doing this is wacky")
ModConfigMenu.AddText("This is a test 27", "whee what am i doing this is wacky")

local configMenuInSubcategory = false
local configMenuInOptions = false
local configMenuInPopup = false

local holdingCounterDown = 0
local holdingCounterUp = 0
local holdingCounterRight = 0
local holdingCounterLeft = 0

local configMenuPositionCursorCategory = 1
local configMenuPositionCursorSubcategory = 1
local configMenuPositionCursorOption = 1

--valid action presses
local actionsDown = {ButtonAction.ACTION_DOWN, ButtonAction.ACTION_SHOOTDOWN, ButtonAction.ACTION_MENUDOWN}
local actionsUp = {ButtonAction.ACTION_UP, ButtonAction.ACTION_SHOOTUP, ButtonAction.ACTION_MENUUP}
local actionsRight = {ButtonAction.ACTION_RIGHT, ButtonAction.ACTION_SHOOTRIGHT, ButtonAction.ACTION_MENURIGHT}
local actionsLeft = {ButtonAction.ACTION_LEFT, ButtonAction.ACTION_SHOOTLEFT, ButtonAction.ACTION_MENULEFT}
local actionsBack = {ButtonAction.ACTION_PILLCARD, ButtonAction.ACTION_MAP, ButtonAction.ACTION_MENUBACK}
local actionsSelect = {ButtonAction.ACTION_ITEM, ButtonAction.ACTION_PAUSE, ButtonAction.ACTION_MENUCONFIRM, ButtonAction.ACTION_BOMB}

--ignore these buttons for the above actions
local ignoreActionButtons = {InputHelper.Controller.BUTTON_A, InputHelper.Controller.BUTTON_B, InputHelper.Controller.BUTTON_X, InputHelper.Controller.BUTTON_Y}

local currentMenuCategory = nil
local currentMenuSubcategory = nil
local currentMenuOption = nil
local function updateCurrentMenuVars()
	if ModConfigMenu.MenuData[configMenuPositionCursorCategory] then
		currentMenuCategory = ModConfigMenu.MenuData[configMenuPositionCursorCategory]
		if currentMenuCategory.Subcategories and currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory] then
			currentMenuSubcategory = currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory]
			if currentMenuSubcategory.Options and currentMenuSubcategory.Options[configMenuPositionCursorOption] then
				currentMenuOption = currentMenuSubcategory.Options[configMenuPositionCursorOption]
			end
		end
	end
end

--leaving/entering menu sections
function ModConfigMenu.EnterPopup()
	if configMenuInSubcategory and configMenuInOptions and not configMenuInPopup then
		local foundValidPopup = false
		if currentMenuOption
		and currentMenuOption.Type
		and currentMenuOption.Type ~= ModConfigMenu.OptionType.SPACE
		and currentMenuOption.Popup then
			foundValidPopup = true
		end
		if foundValidPopup then
			local popupSpritesheet = ModConfigMenu.PopupGfx.THIN_SMALL
			if currentMenuOption.PopupGfx and type(currentMenuOption.PopupGfx) == "string" then
				popupSpritesheet = currentMenuOption.PopupGfx
			end
			PopupSprite:ReplaceSpritesheet(5, popupSpritesheet)
			PopupSprite:LoadGraphics()
			configMenuInPopup = true
		end
	end
end

function ModConfigMenu.EnterOptions()
	if configMenuInSubcategory and not configMenuInOptions then
		if currentMenuSubcategory
		and currentMenuSubcategory.Options
		and #currentMenuSubcategory.Options > 0 then
		
			for optionIndex=1, #currentMenuSubcategory.Options do
				
				local thisOption = currentMenuSubcategory.Options[optionIndex]
				
				if thisOption.Type
				and thisOption.Type ~= ModConfigMenu.OptionType.SPACE
				and (not thisOption.NoCursorHere or (type(thisOption.NoCursorHere) == "function" and not thisOption.NoCursorHere()))
				and thisOption.Display then
				
					configMenuPositionCursorOption = optionIndex
					configMenuInOptions = true
					OptionsCursorSpriteUp.Color = colorDefault
					OptionsCursorSpriteDown.Color = colorDefault
					
					break
				end
			end
		end
	end
end

function ModConfigMenu.EnterSubcategory()
	if not configMenuInSubcategory then
		configMenuInSubcategory = true
		SubcategoryCursorSpriteLeft.Color = colorDefault
		SubcategoryCursorSpriteRight.Color = colorDefault
		SubcategoryDividerSprite.Color = colorDefault
		
		local hasUsableCategories = false
		if currentMenuCategory.Subcategories then
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
					hasUsableCategories = true
				end
			end
		end
		
		if not hasUsableCategories then
			ModConfigMenu.EnterOptions()
		end
	end
end

function ModConfigMenu.LeavePopup()
	if configMenuInSubcategory and configMenuInOptions and configMenuInPopup then
		configMenuInPopup = false
	end
end

function ModConfigMenu.LeaveOptions()
	if configMenuInSubcategory and configMenuInOptions then
		configMenuInOptions = false
		OptionsCursorSpriteUp.Color = colorHalf
		OptionsCursorSpriteDown.Color = colorHalf
		
		local hasUsableCategories = false
		if currentMenuCategory.Subcategories then
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
					hasUsableCategories = true
				end
			end
		end
		
		if not hasUsableCategories then
			ModConfigMenu.LeaveSubcategory()
		end
	end
end

function ModConfigMenu.LeaveSubcategory()
	if configMenuInSubcategory then
		configMenuInSubcategory = false
		SubcategoryCursorSpriteLeft.Color = colorHalf
		SubcategoryCursorSpriteRight.Color = colorHalf
		SubcategoryDividerSprite.Color = colorHalf
	end
end

local mainSpriteColor = colorDefault
local optionsSpriteColor = colorDefault
local optionsSpriteColorAlpha = colorHalf
local mainFontColor = KColor(34/255,32/255,30/255,1)
local leftFontColor = KColor(35/255,31/255,30/255,1)
local leftFontColorSelected = KColor(35/255,50/255,70/255,1)

local optionsFontColor = KColor(34/255,32/255,30/255,1)
local optionsFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
local optionsFontColorNoCursor = KColor(34/255,32/255,30/255,0.8)
local optionsFontColorNoCursorAlpha = KColor(34/255,32/255,30/255,0.4)
local optionsFontColorTitle = KColor(50/255,0,0,1)
local optionsFontColorTitleAlpha = KColor(50/255,0,0,0.5)

local subcategoryFontColor = KColor(34/255,32/255,30/255,1)
local subcategoryFontColorSelected = KColor(34/255,50/255,70/255,1)
local subcategoryFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
local subcategoryFontColorSelectedAlpha = KColor(34/255,50/255,70/255,0.5)

--render the menu
local optionsCurrentOffset = 0
ModConfigMenu.ControlsEnabled = true
ModConfigMenu.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()

	local game = Game()
	local isPaused = game:IsPaused()
	
	local sfx = SFXManager()

	local pressingButton = ""

	local pressingNonRebindableKey = false
	local pressedToggleMenu = false

	local openMenuGlobal = Keyboard.KEY_F10
	local openMenuKeyboard = ModConfigMenu.Config["Mod Config Menu"].OpenMenuKeyboard
	local openMenuController = ModConfigMenu.Config["Mod Config Menu"].OpenMenuController
	
	local takeScreenshot = Keyboard.KEY_F12

	if ModConfigMenu.ControlsEnabled and not isPaused then
	
		for i=0, 4 do
		
			if InputHelper.KeyboardTriggered(openMenuGlobal, i)
			or (openMenuKeyboard > -1 and InputHelper.KeyboardTriggered(openMenuKeyboard, i))
			or (openMenuController > -1 and Input.IsButtonTriggered(openMenuController, i)) then
				pressingNonRebindableKey = true
				pressedToggleMenu = true
				if not configMenuInPopup then
					ModConfigMenu.ToggleConfigMenu()
				end
			end
			
			if InputHelper.KeyboardTriggered(takeScreenshot, i) then
				pressingNonRebindableKey = true
			end
			
		end
		
	end
	
	--force close the menu in some situations
	if ModConfigMenu.IsVisible then
	
		if isPaused then
		
			ModConfigMenu.CloseConfigMenu()
			
		end
		
		if not ModConfigMenu.RoomIsSafe() then
		
			ModConfigMenu.CloseConfigMenu()
			
			sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
			
		end
		
	end

	if revel and revel.data and revel.data.controllerToggle then
		if openMenuController == InputHelper.Controller.STICK_RIGHT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 3 or revel.data.controllerToggle == 4) then
			revel.data.controllerToggle = 2 --force revelations' menu to only use the left stick
		elseif openMenuController == InputHelper.Controller.STICK_LEFT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 2 or revel.data.controllerToggle == 4) then
			revel.data.controllerToggle = 3 --force revelations' menu to only use the right stick
		end
	end
	
	if ModConfigMenu.IsVisible then
	
		if ModConfigMenu.ControlsEnabled and not isPaused then
		
			for i=0, game:GetNumPlayers()-1 do
		
				local player = Isaac.GetPlayer(i)
				local data = player:GetData()
				
				--freeze players and disable their controls
				player.Velocity = vecZero
				
				if not data.ConfigMenuPlayerPosition then
					data.ConfigMenuPlayerPosition = player.Position
				end
				player.Position = data.ConfigMenuPlayerPosition
				if not data.ConfigMenuPlayerControlsDisabled then
					player.ControlsEnabled = false
					data.ConfigMenuPlayerControlsDisabled = true
				end
				
				--disable toggling revelations menu
				if data.input and data.input.menu and data.input.menu.toggle then
					data.input.menu.toggle = false
				end
				
			end
			
			if not InputHelper.MultipleButtonTriggered(ignoreActionButtons) then
				--pressing buttons
				local downButtonPressed = InputHelper.MultipleActionTriggered(actionsDown)
				if downButtonPressed then
					pressingButton = "DOWN"
				end
				local upButtonPressed = InputHelper.MultipleActionTriggered(actionsUp)
				if upButtonPressed then
					pressingButton = "UP"
				end
				local rightButtonPressed = InputHelper.MultipleActionTriggered(actionsRight)
				if rightButtonPressed then
					pressingButton = "RIGHT"
				end
				local leftButtonPressed = InputHelper.MultipleActionTriggered(actionsLeft)
				if leftButtonPressed then
					pressingButton = "LEFT"
				end
				local backButtonPressed = InputHelper.MultipleActionTriggered(actionsBack) or InputHelper.MultipleKeyboardTriggered({Keyboard.KEY_BACKSPACE})
				if backButtonPressed then
					pressingButton = "BACK"
					local possiblyPressedButton = InputHelper.MultipleKeyboardTriggered(Keyboard)
					if possiblyPressedButton then
						ModConfigMenu.Config.LastBackPressed = possiblyPressedButton
					end
				end
				local selectButtonPressed = InputHelper.MultipleActionTriggered(actionsSelect)
				if selectButtonPressed then
					pressingButton = "SELECT"
					local possiblyPressedButton = InputHelper.MultipleKeyboardTriggered(Keyboard)
					if possiblyPressedButton then
						ModConfigMenu.Config.LastSelectPressed = possiblyPressedButton
					end
				end
				if ModConfigMenu.Config["Mod Config Menu"].ResetToDefault > -1 and InputHelper.MultipleKeyboardTriggered({ModConfigMenu.Config["Mod Config Menu"].ResetToDefault}) then
					pressingButton = "RESET"
				end
				
				--holding buttons
				if InputHelper.MultipleActionPressed(actionsDown) then
					holdingCounterDown = holdingCounterDown + 1
				else
					holdingCounterDown = 0
				end
				if holdingCounterDown > 20 and holdingCounterDown%5 == 0 then
					pressingButton = "DOWN"
				end
				if InputHelper.MultipleActionPressed(actionsUp) then
					holdingCounterUp = holdingCounterUp + 1
				else
					holdingCounterUp = 0
				end
				if holdingCounterUp > 20 and holdingCounterUp%5 == 0 then
					pressingButton = "UP"
				end
				if InputHelper.MultipleActionPressed(actionsRight) then
					holdingCounterRight = holdingCounterRight + 1
				else
					holdingCounterRight = 0
				end
				if holdingCounterRight > 20 and holdingCounterRight%5 == 0 then
					pressingButton = "RIGHT"
				end
				if InputHelper.MultipleActionPressed(actionsLeft) then
					holdingCounterLeft = holdingCounterLeft + 1
				else
					holdingCounterLeft = 0
				end
				if holdingCounterLeft > 20 and holdingCounterLeft%5 == 0 then
					pressingButton = "LEFT"
				end
			else
				if InputHelper.MultipleButtonTriggered({InputHelper.Controller.BUTTON_B}) then
					pressingButton = "BACK"
				end
				if InputHelper.MultipleButtonTriggered({InputHelper.Controller.BUTTON_A}) then
					pressingButton = "SELECT"
				end
				pressingNonRebindableKey = true
			end
			
			if pressingButton ~= "" then
				pressingNonRebindableKey = true
			end
			
		end
		
		updateCurrentMenuVars()
		
		local lastCursorCategoryPosition = configMenuPositionCursorCategory
		local lastCursorSubcategoryPosition = configMenuPositionCursorSubcategory
		local lastCursorOptionsPosition = configMenuPositionCursorOption
		
		local enterPopup = false
		local leavePopup = false
		
		local enterOptions = false
		local leaveOptions = false
		
		local enterSubcategory = false
		local leaveSubcategory = false
		
		if configMenuInPopup then
		
			if currentMenuOption then
				local optionType = currentMenuOption.Type
				local optionCurrent = currentMenuOption.CurrentSetting
				local optionOnChange = currentMenuOption.OnChange

				if optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER or currentMenuOption.OnSelect then

					if not isPaused then

						if pressingNonRebindableKey
						and not (pressingButton == "BACK"
						or pressingButton == "LEFT"
						or (currentMenuOption.OnSelect and (pressingButton == "SELECT" or pressingButton == "RIGHT"))
						or (currentMenuOption.IsResetKeybind and pressingButton == "RESET")
						or (currentMenuOption.IsOpenMenuKeybind and pressedToggleMenu)) then
							sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
						else
							local numberToChange = nil
							local recievedInput = false
							if optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
								numberToChange = optionCurrent
								
								if type(optionCurrent) == "function" then
									numberToChange = optionCurrent()
								end
								
								if pressingButton == "BACK" or pressingButton == "LEFT" then
									numberToChange = nil
									recievedInput = true
								else
									for i=0, 4 do
										if optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD then
											for j=32, 400 do
												if InputHelper.KeyboardTriggered(j, i) then
													numberToChange = j
													recievedInput = true
													break
												end
											end
										else
											for j=0, 31 do
												if Input.IsButtonTriggered(j, i) then
													numberToChange = j
													recievedInput = true
													break
												end
											end
										end
									end
								end
							elseif currentMenuOption.OnSelect then
								if pressingButton == "BACK" or pressingButton == "LEFT" then
									recievedInput = true
								end
								if pressingButton == "SELECT" or pressingButton == "RIGHT" then
									numberToChange = true
									recievedInput = true
								end
							end
							
							if recievedInput then
								if optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER then
									if type(optionCurrent) == "function" then
										if optionOnChange then
											optionOnChange(numberToChange)
										end
									elseif type(optionCurrent) == "number" then
										currentMenuOption.CurrentSetting = numberToChange
									end
								elseif currentMenuOption.OnSelect and numberToChange then
									currentMenuOption.OnSelect()
								end
								
								leavePopup = true
								
								local sound = currentMenuOption.Sound
								if not sound then
									sound = SoundEffect.SOUND_PLOP
								end
								if sound >= 0 then
									sfx:Play(sound, 1, 0, false, 1)
								end
							end
						end
					end
				end
			end
			
			--confirmed left press
			if pressingButton == "LEFT" then
				leavePopup = true
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				leavePopup = true
			end
		elseif configMenuInOptions then
			--confirmed down press
			if pressingButton == "DOWN" then
				configMenuPositionCursorOption = configMenuPositionCursorOption + 1 --move options cursor down
			end
			
			--confirmed up press
			if pressingButton == "UP" then
				configMenuPositionCursorOption = configMenuPositionCursorOption - 1 --move options cursor up
			end
			
			if pressingButton == "SELECT" or pressingButton == "RIGHT" or pressingButton == "LEFT" or (pressingButton == "RESET" and currentMenuOption and currentMenuOption.Default ~= nil) then
				if pressingButton == "LEFT" then
					leaveOptions = true
				end
				
				if currentMenuOption then
					local optionType = currentMenuOption.Type
					local optionCurrent = currentMenuOption.CurrentSetting
					local optionOnChange = currentMenuOption.OnChange
					
					if optionType == ModConfigMenu.OptionType.SCROLL or optionType == ModConfigMenu.OptionType.NUMBER then
						leaveOptions = false
						
						local numberToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							numberToChange = optionCurrent()
						end
						
						local modifyBy = currentMenuOption.ModifyBy or 1
						modifyBy = math.max(modifyBy,0.001)
						if math.floor(modifyBy) == modifyBy then --force modify by into being an integer instead of a float if it should be
							modifyBy = math.floor(modifyBy)
						end
						
						if pressingButton == "RIGHT" or pressingButton == "SELECT" then
							numberToChange = numberToChange + modifyBy
						elseif pressingButton == "LEFT" then
							numberToChange = numberToChange - modifyBy
						elseif pressingButton == "RESET" and currentMenuOption.Default ~= nil then
							numberToChange = currentMenuOption.Default
							if type(currentMenuOption.Default) == "function" then
								numberToChange = currentMenuOption.Default()
							end
						end
						
						if optionType == ModConfigMenu.OptionType.SCROLL then
							numberToChange = math.max(math.min(math.floor(numberToChange), 10), 0)
						else
							if currentMenuOption.Maximum and numberToChange > currentMenuOption.Maximum then
								if not currentMenuOption.NoLoopFromMaxMin and currentMenuOption.Minimum then
									numberToChange = currentMenuOption.Minimum
								else
									numberToChange = currentMenuOption.Maximum
								end
							end
							if currentMenuOption.Minimum and numberToChange < currentMenuOption.Minimum then
								if not currentMenuOption.NoLoopFromMaxMin and currentMenuOption.Maximum then
									numberToChange = currentMenuOption.Maximum
								else
									numberToChange = currentMenuOption.Minimum
								end
							end
						end
						
						if math.floor(modifyBy) ~= modifyBy then --check if modify by is a float
							numberToChange = math.floor((numberToChange*1000)+0.5)*0.001
						else
							numberToChange = math.floor(numberToChange)
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(numberToChange)
							end
						elseif type(optionCurrent) == "number" then
							currentMenuOption.CurrentSetting = numberToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif optionType == ModConfigMenu.OptionType.BOOLEAN then
						leaveOptions = false
						
						local boolToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							boolToChange = optionCurrent()
						end
						
						if pressingButton == "RESET" and currentMenuOption.Default ~= nil then
							boolToChange = currentMenuOption.Default
							if type(currentMenuOption.Default) == "function" then
								boolToChange = currentMenuOption.Default()
							end
						else
							boolToChange = (not boolToChange)
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(boolToChange)
							end
						elseif type(optionCurrent) == "boolean" then
							currentMenuOption.CurrentSetting = boolToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif (optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER) and pressingButton == "RESET" and currentMenuOption.Default ~= nil then
						local numberToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							numberToChange = optionCurrent()
						end
						
						numberToChange = currentMenuOption.Default
						if type(currentMenuOption.Default) == "function" then
							numberToChange = currentMenuOption.Default()
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(numberToChange)
							end
						elseif type(optionCurrent) == "number" then
							currentMenuOption.CurrentSetting = numberToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif optionType ~= ModConfigMenu.OptionType.SPACE and pressingButton == "RIGHT" then
						if currentMenuOption.Popup then
							enterPopup = true
						elseif currentMenuOption.OnSelect then
							currentMenuOption.OnSelect()
						end
					end
				end
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				leaveOptions = true
			end
			
			--confirmed select press
			if pressingButton == "SELECT" then
				if currentMenuOption then
					if currentMenuOption.Popup then
						enterPopup = true
					elseif currentMenuOption.OnSelect then
						currentMenuOption.OnSelect()
					end
				end
			end
		elseif configMenuInSubcategory then
			local hasUsableCategories = false
			if currentMenuCategory.Subcategories then
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasUsableCategories = true
					end
				end
			end
			if hasUsableCategories then
				--confirmed down press
				if pressingButton == "DOWN" then
					enterOptions = true
				end
				
				--confirmed up press
				if pressingButton == "UP" then
					leaveSubcategory = true
				end
				
				--confirmed right press
				if pressingButton == "RIGHT" then
					configMenuPositionCursorSubcategory = configMenuPositionCursorSubcategory + 1 --move right down
				end
				
				--confirmed left press
				if pressingButton == "LEFT" then
					configMenuPositionCursorSubcategory = configMenuPositionCursorSubcategory - 1 --move cursor left
				end
				
				--confirmed back press
				if pressingButton == "BACK" then
					leaveSubcategory = true
				end
				
				--confirmed select press
				if pressingButton == "SELECT" then
					enterOptions = true
				end
			end
		else
			--confirmed down press
			if pressingButton == "DOWN" then
				configMenuPositionCursorCategory = configMenuPositionCursorCategory + 1 --move left cursor down
			end
			
			--confirmed up press
			if pressingButton == "UP" then
				configMenuPositionCursorCategory = configMenuPositionCursorCategory - 1 --move left cursor up
			end
			
			--confirmed right press
			if pressingButton == "RIGHT" then
				enterSubcategory = true
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				ModConfigMenu.CloseConfigMenu()
			end
			
			--confirmed select press
			if pressingButton == "SELECT" then
				enterSubcategory = true
			end
		end
		
		--entering popup
		if enterPopup then
			ModConfigMenu.EnterPopup()
		end
		
		--leaving popup
		if leavePopup then
			ModConfigMenu.LeavePopup()
		end
		
		--entering subcategory
		if enterSubcategory then
			ModConfigMenu.EnterSubcategory()
		end
		
		--entering options
		if enterOptions then
			ModConfigMenu.EnterOptions()
		end
		
		--leaving options
		if leaveOptions then
			ModConfigMenu.LeaveOptions()
		end
		
		--leaving subcategory
		if leaveSubcategory then
			ModConfigMenu.LeaveSubcategory()
		end
		
		--category cursor position was changed
		if lastCursorCategoryPosition ~= configMenuPositionCursorCategory then
			if not configMenuInSubcategory then
			
				--cursor position
				if configMenuPositionCursorCategory < 1 then --move from the top of the list to the bottom
					configMenuPositionCursorCategory = #ModConfigMenu.MenuData
				end
				if configMenuPositionCursorCategory > #ModConfigMenu.MenuData then --move from the bottom of the list to the top
					configMenuPositionCursorCategory = 1
				end
				
				--make sure subcategory and option positions are 1
				configMenuPositionCursorSubcategory = 1
				configMenuPositionCursorOption = 1
				optionsCurrentOffset = 0
				
			end
		end
		
		--subcategory cursor position was changed
		if lastCursorSubcategoryPosition ~= configMenuPositionCursorSubcategory then
			if not configMenuInOptions then
			
				--cursor position
				if configMenuPositionCursorSubcategory < 1 then --move from the top of the list to the bottom
					configMenuPositionCursorSubcategory = #currentMenuCategory.Subcategories
				end
				if configMenuPositionCursorSubcategory > #currentMenuCategory.Subcategories then --move from the bottom of the list to the top
					configMenuPositionCursorSubcategory = 1
				end
				
				--make sure option positions are 1
				configMenuPositionCursorOption = 1
				optionsCurrentOffset = 0
				
			end
		end
		
		--options cursor position was changed
		if lastCursorOptionsPosition ~= configMenuPositionCursorOption then
			if configMenuInOptions
			and currentMenuSubcategory
			and currentMenuSubcategory.Options
			and #currentMenuSubcategory.Options > 0 then
				
				--find next valid option that isn't a space
				local nextValidOptionSelection = configMenuPositionCursorOption
				local optionIndex = configMenuPositionCursorOption
				for i=1, #currentMenuSubcategory.Options*2 do
				
					local thisOption = currentMenuSubcategory.Options[optionIndex]
					
					if thisOption
					and thisOption.Type
					and thisOption.Type ~= ModConfigMenu.OptionType.SPACE
					and (not thisOption.NoCursorHere or (type(thisOption.NoCursorHere) == "function" and not thisOption.NoCursorHere()))
					and thisOption.Display then
						
						nextValidOptionSelection = optionIndex
						
						break
					end
					
					if configMenuPositionCursorOption > lastCursorOptionsPosition then
						optionIndex = optionIndex + 1
					elseif configMenuPositionCursorOption < lastCursorOptionsPosition then
						optionIndex = optionIndex - 1
					end
					if optionIndex < 1 then
						optionIndex = #currentMenuSubcategory.Options
					end
					if optionIndex > #currentMenuSubcategory.Options then
						optionIndex = 1
					end
				end
				
				configMenuPositionCursorOption = nextValidOptionSelection
				
				updateCurrentMenuVars()
				
				--first options selection to render
				local hasSubcategories = false
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasSubcategories = true
					end
				end
				if hasSubcategories then
					--todo
				end
				
			end
		end
		
		local centerPos = ScreenHelper.GetScreenCenter()
		local leftPos = centerPos + Vector(-142,-102)
		local titlePos = centerPos + Vector(68,-118)
		local infoPos = centerPos + Vector(-4,106)
		
		local optionsDesiredOffset = 0
		local optionsCanScrollUp = false
		local optionsCanScrollDown = false
		local numOptions = 0
		local optionPos = centerPos + Vector(68,-18)
		if currentMenuSubcategory
		and currentMenuSubcategory.Options
		and #currentMenuSubcategory.Options > 0 then
			
			numOptions = #currentMenuSubcategory.Options
		
			if currentMenuCategory.Subcategories then
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						numOptions = numOptions + 2
						break
					end
				end
			end
			
			optionPos = optionPos + Vector(0, math.min(numOptions-1, 10) * -7)
			
			if numOptions > 10 then
			
				if configMenuPositionCursorOption > 6 then
				
					optionsCanScrollUp = true
					
					local cursorScroll = configMenuPositionCursorOption - 6
					local maxOptionsScroll = numOptions - 11
					optionsDesiredOffset = math.min(cursorScroll, maxOptionsScroll) * -14
					
					if cursorScroll < maxOptionsScroll then
						optionsCanScrollDown = true
					end
				
				else
			
					optionsCanScrollDown = true
				
				end
				
			end
			
		end
	
		if optionsDesiredOffset ~= optionsCurrentOffset then
		
			local modifyOffset = math.floor(optionsDesiredOffset - optionsCurrentOffset)/10
			if modifyOffset > -0.1 and modifyOffset < 0 then
				modifyOffset = -0.1
			end
			if modifyOffset < 0.1 and modifyOffset > 0 then
				modifyOffset = 0.1
			end
			
			optionsCurrentOffset = optionsCurrentOffset + modifyOffset
			if (optionsDesiredOffset - optionsCurrentOffset) < 0.25 and (optionsDesiredOffset - optionsCurrentOffset) > -0.25 then
				optionsCurrentOffset = optionsDesiredOffset
			end
			
		end
		
		if optionsCurrentOffset ~= 0 then
			optionPos = optionPos + Vector(0, optionsCurrentOffset)
		end
	
		MenuSprite:Render(centerPos, vecZero, vecZero)
		
		--category
		local lastLeftPos = leftPos
		local renderedLeft = 0
		for categoryIndex=1, #ModConfigMenu.MenuData do
		
			--text
			local textToDraw = tostring(ModConfigMenu.MenuData[categoryIndex].Name)
			
			local color = leftFontColor
			--[[
			if configMenuPositionCursorCategory == categoryIndex then
				color = leftFontColorSelected
			end
			]]
			
			local posOffset = Font12:GetStringWidthUTF8(textToDraw)/2
			Font12:DrawString(textToDraw, lastLeftPos.X - posOffset, lastLeftPos.Y - 8, color, 0, true)
			
			--cursor
			if configMenuPositionCursorCategory == categoryIndex then
				CursorSpriteRight:Render(lastLeftPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
			end
			
			--increase counter
			renderedLeft = renderedLeft + 1
			--[[
				--render scroll arrows
				CursorSpriteUp:Render(leftPos + Vector(45,-4), vecZero, vecZero) --up arrow
				CursorSpriteDown:Render(lastLeftPos + Vector(45,4), vecZero, vecZero) --down arrow
			]]
			
			--pos mod
			lastLeftPos = lastLeftPos + Vector(0,16)
			
		end
		
		--title
		local titleText = "Mod Config Menu"
		if configMenuInSubcategory then
			titleText = tostring(currentMenuCategory.Name)
		end
		local titleTextOffset = Font16Bold:GetStringWidthUTF8(titleText)/2
		Font16Bold:DrawString(titleText, titlePos.X - titleTextOffset, titlePos.Y - 9, mainFontColor, 0, true)
		
		------------------------
		--RENDER SUBCATEGORIES--
		------------------------
		
		local lastOptionPos = optionPos
		local renderedOptions = 0
		
		local lastSubcategoryPos = optionPos
		local renderedSubcategories = 0
		
		if currentMenuCategory then
		
			local hasUncategorizedCategory = false
			local hasSubcategories = false
			local numCategories = 0
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name == "Uncategorized" then
					hasUncategorizedCategory = true
				else
					hasSubcategories = true
					numCategories = numCategories + 1
				end
			end
			
			if hasSubcategories then
				
				if hasUncategorizedCategory then
					numCategories = numCategories + 1
				end
				
				if numCategories == 2 then
					lastSubcategoryPos = lastOptionPos + Vector(-38,0)
				elseif numCategories >= 3 then
					lastSubcategoryPos = lastOptionPos + Vector(-76,0)
				end
			
				for subcategoryIndex=1, #currentMenuCategory.Subcategories do
					
					local thisSubcategory = currentMenuCategory.Subcategories[subcategoryIndex]
					
					local posOffset = 0
					
					if thisSubcategory.Name then
						local textToDraw = thisSubcategory.Name
						
						textToDraw = tostring(textToDraw)
						
						local color = subcategoryFontColor
						if not configMenuInSubcategory then
							color = subcategoryFontColorAlpha
						--[[
						elseif configMenuPositionCursorSubcategory == subcategoryIndex and configMenuInSubcategory then
							color = subcategoryFontColorSelected
						]]
						end
						
						posOffset = Font12:GetStringWidthUTF8(textToDraw)/2
						Font12:DrawString(textToDraw, lastSubcategoryPos.X - posOffset, lastSubcategoryPos.Y - 8, color, 0, true)
					end
					
					--cursor
					if configMenuPositionCursorSubcategory == subcategoryIndex and configMenuInSubcategory then
						CursorSpriteRight:Render(lastSubcategoryPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
					end
					
					--increase counter
					renderedSubcategories = renderedSubcategories + 1
						--render scroll arrows
						--[[
							SubcategoryCursorSpriteLeft:Render(lastOptionPos + Vector(-125,0), vecZero, vecZero) --up arrow
							SubcategoryCursorSpriteRight:Render(lastOptionPos + Vector(125,0), vecZero, vecZero) --down arrow
						]]
					
					--pos mod
					lastSubcategoryPos = lastSubcategoryPos + Vector(76,0)
					
				end
				
				--subcategory selection counts as an option that gets rendered
				renderedOptions = renderedOptions + 1
				lastOptionPos = lastOptionPos + Vector(0,14)
				
				--subcategory to options divider
				SubcategoryDividerSprite:Render(lastOptionPos, vecZero, vecZero)
				
				--subcategory to options divider counts as an option that gets rendered
				renderedOptions = renderedOptions + 1
				lastOptionPos = lastOptionPos + Vector(0,14)

			end
		end
		
		------------------
		--RENDER OPTIONS--
		------------------
		
		local firstOptionPos = lastOptionPos
		
		if currentMenuSubcategory
		and currentMenuSubcategory.Options
		and #currentMenuSubcategory.Options > 0 then
		
			local useAltSlider = false
		
			for optionIndex=1, #currentMenuSubcategory.Options do
				
				local thisOption = currentMenuSubcategory.Options[optionIndex]
				
				local cursorIsAtThisOption = configMenuPositionCursorOption == optionIndex and configMenuInOptions
				local posOffset = 10
				
				if thisOption.Type
				and thisOption.Type ~= ModConfigMenu.OptionType.SPACE
				and thisOption.Display then
				
					local optionType = thisOption.Type
					local optionDisplay = thisOption.Display
					local optionColor = thisOption.Color
					
					--get what to draw
					if optionType == ModConfigMenu.OptionType.TEXT
					or optionType == ModConfigMenu.OptionType.BOOLEAN
					or optionType == ModConfigMenu.OptionType.NUMBER
					or optionType == ModConfigMenu.OptionType.KEYBIND_KEYBOARD
					or optionType == ModConfigMenu.OptionType.KEYBIND_CONTROLLER
					or optionType == ModConfigMenu.OptionType.TITLE then
						local textToDraw = optionDisplay
						
						if type(optionDisplay) == "function" then
							textToDraw = optionDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
						end
						
						textToDraw = tostring(textToDraw)
						
						local heightOffset = 6
						local font = Font10
						local color = optionsFontColor
						if not configMenuInOptions then
							if thisOption.NoCursorHere then
								color = optionsFontColorNoCursorAlpha
							else
								color = optionsFontColorAlpha
							end
						elseif thisOption.NoCursorHere then
							color = optionsFontColorNoCursor
						end
						if optionType == ModConfigMenu.OptionType.TITLE then
							heightOffset = 8
							font = Font12
							color = optionsFontColorTitle
							if not configMenuInOptions then
								color = optionsFontColorTitleAlpha
							end
						end
						
						if optionColor then
							color = KColor(optionColor[1], optionColor[2], optionColor[3], color.A)
						end
						
						posOffset = font:GetStringWidthUTF8(textToDraw)/2
						font:DrawString(textToDraw, lastOptionPos.X - posOffset, lastOptionPos.Y - heightOffset, color, 0, true)
					elseif optionType == ModConfigMenu.OptionType.SCROLL then
						local numberToShow = optionDisplay
						
						if type(optionDisplay) == "function" then
							numberToShow = optionDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
						end
						
						posOffset = 31
						local scrollOffset = 0
						
						if type(numberToShow) == "number" then
							numberToShow = math.max(math.min(math.floor(numberToShow), 10), 0)
						elseif type(numberToShow) == "string" then
							local numberToShowStart, numberToShowEnd = string.find(numberToShow, "$scroll")
							if numberToShowStart and numberToShowEnd then
								local numberStart = numberToShowEnd+1
								local numberEnd = numberToShowEnd+3
								local numberString = string.sub(numberToShow, numberStart, numberEnd)
								numberString = tonumber(numberString)
								if not numberString or (numberString and not type(numberString) == "number") or (numberString and type(numberString) == "number" and numberString < 10) then
									numberEnd = numberEnd-1
									numberString = string.sub(numberToShow, numberStart, numberEnd)
									numberString = tonumber(numberString)
								end
								if numberString and type(numberString) == "number" then
									local textToDrawPreScroll = string.sub(numberToShow, 0, numberToShowStart-1)
									local textToDrawPostScroll = string.sub(numberToShow, numberEnd, string.len(numberToShow))
									local textToDraw = textToDrawPreScroll .. "               " .. textToDrawPostScroll
									
									local color = optionsFontColor
									if not configMenuInOptions then
										color = optionsFontColorAlpha
									end
									if optionColor then
										color = KColor(optionColor[1], optionColor[2], optionColor[3], color.A)
									end
									
									scrollOffset = posOffset
									posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
									Font10:DrawString(textToDraw, lastOptionPos.X - posOffset, lastOptionPos.Y - 6, color, 0, true)
									
									scrollOffset = posOffset - (Font10:GetStringWidthUTF8(textToDrawPreScroll)+scrollOffset)
									numberToShow = numberString
								end
							end
						end
						
						local scrollColor = optionsSpriteColor
						if not configMenuInOptions then
							scrollColor = optionsSpriteColorAlpha
						end
						if optionColor then
							scrollColor = Color(optionColor[1], optionColor[2], optionColor[3], scrollColor.A, scrollColor.RO, scrollColor.GO, scrollColor.BO)
						end
						
						local sliderString = "Slider1"
						if useAltSlider then
							sliderString = "Slider2"
						end
						
						SliderSprite.Color = scrollColor
						SliderSprite:SetFrame(sliderString, numberToShow)
						SliderSprite:Render(lastOptionPos - Vector(scrollOffset, -2), vecZero, vecZero)
						
						useAltSlider = not useAltSlider
						
					end
					
					local showStrikeout = thisOption.ShowStrikeout
					if posOffset > 0 and (type(showStrikeout) == boolean and showStrikeout == true) or (type(showStrikeout) == "function" and showStrikeout() == true) then
						if configMenuInOptions then
							StrikeOutSprite.Color = colorDefault
						else
							StrikeOutSprite.Color = colorHalf
						end
						StrikeOutSprite:SetFrame("Strikeout", math.floor(posOffset))
						StrikeOutSprite:Render(lastOptionPos, vecZero, vecZero)
					end
				end
				
				--cursor
				if cursorIsAtThisOption then
					CursorSpriteRight:Render(lastOptionPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
				end
				
				--increase counter
				renderedOptions = renderedOptions + 1
				
				--pos mod
				lastOptionPos = lastOptionPos + Vector(0,14)
				
			end
			
			--render scroll arrows
			if optionsCanScrollUp then
				OptionsCursorSpriteUp:Render(centerPos + Vector(193,-86), vecZero, vecZero) --up arrow
			end
			if optionsCanScrollDown then
				OptionsCursorSpriteDown:Render(centerPos + Vector(193,50), vecZero, vecZero) --down arrow
			end
		
		end
		
		--info
		local infoTable = nil
		local isOldInfo = false
		
		if configMenuInOptions then
		
			if currentMenuOption and currentMenuOption.Info then
				infoTable = currentMenuOption.Info
			end
			
		elseif configMenuInSubcategory then
		
			if currentMenuSubcategory and currentMenuSubcategory.Info then
				infoTable = currentMenuSubcategory.Info
			end
			
		elseif currentMenuCategory and currentMenuCategory.Info then
			
			infoTable = currentMenuCategory.Info
			if currentMenuCategory.IsOld then
				isOldInfo = true
			end
			
		end
		
		if infoTable then
			
			if type(infoTable) == "function" then
				infoTable = infoTable()
			end
			if type(infoTable) ~= "table" then
				infoTable = {infoTable}
			end
			
			local lastInfoPos = infoPos - Vector(0,6*#infoTable)
			for line=1, #infoTable do
			
				--text
				local textToDraw = tostring(infoTable[line])
				local posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
				local color = mainFontColor
				if isOldInfo then
					color = optionsFontColorTitle
				end
				Font10:DrawString(textToDraw, lastInfoPos.X - posOffset, lastInfoPos.Y - 6, color, 0, true)
				
				--pos mod
				lastInfoPos = lastInfoPos + Vector(0,10)
				
			end
			
		end
		
		--popup
		if configMenuInPopup
		and currentMenuOption
		and currentMenuOption.Popup then
			PopupSprite:Render(centerPos, vecZero, vecZero)
			
			local popupTable = currentMenuOption.Popup
			if type(popupTable) == "function" then
				popupTable = popupTable()
			end
			if type(popupTable) ~= "table" then
				popupTable = {popupTable}
			end
			
			local lastPopupPos = (centerPos + Vector(0,2)) - Vector(0,6*#popupTable)
			for line=1, #popupTable do
				--text
				local textToDraw = tostring(popupTable[line])
				local posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
				Font10:DrawString(textToDraw, lastPopupPos.X - posOffset, lastPopupPos.Y - 6, mainFontColor, 0, true)
				
				--pos mod
				lastPopupPos = lastPopupPos + Vector(0,10)
			end
		end
		
		--controls
		local shouldShowControls = true
		if configMenuInOptions and currentMenuOption and currentMenuOption.HideControls then
			shouldShowControls = false
		end
		if not ModConfigMenu.Config["Mod Config Menu"].ShowControls then
			shouldShowControls = false
		end
		if shouldShowControls then

			--back
			local bottomLeft = ScreenHelper.GetScreenBottomLeft(0)
			if not configMenuInSubcategory then
				CornerExit:Render(bottomLeft, vecZero, vecZero)
			else
				CornerBack:Render(bottomLeft, vecZero, vecZero)
			end

			local goBackString = ""
			if ModConfigMenu.Config.LastBackPressed then
				if InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = InputHelper.KeyboardToString[ModConfigMenu.Config.LastBackPressed]
				elseif InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = InputHelper.ControllerToString[ModConfigMenu.Config.LastBackPressed]
				end
			end
			Font10:DrawString(goBackString, (bottomLeft.X - Font10:GetStringWidthUTF8(goBackString)/2) + 36, bottomLeft.Y - 24, mainFontColor, 0, true)

			--select
			local bottomRight = ScreenHelper.GetScreenBottomRight(0)
			if not configMenuInPopup then
			
				local foundValidPopup = false
				--[[
				if configMenuInSubcategory
				and configMenuInOptions
				and currentMenuOption
				and currentMenuOption.Type
				and currentMenuOption.Type ~= ModConfigMenu.OptionType.SPACE
				and currentMenuOption.Popup then
					foundValidPopup = true
				end
				]]
				
				if foundValidPopup then
					CornerOpen:Render(bottomRight, vecZero, vecZero)
				else
					CornerSelect:Render(bottomRight, vecZero, vecZero)
				end
				
				local selectString = ""
				if ModConfigMenu.Config.LastSelectPressed then
					if InputHelper.KeyboardToString[ModConfigMenu.Config.LastSelectPressed] then
						selectString = InputHelper.KeyboardToString[ModConfigMenu.Config.LastSelectPressed]
					elseif InputHelper.ControllerToString[ModConfigMenu.Config.LastSelectPressed] then
						selectString = InputHelper.ControllerToString[ModConfigMenu.Config.LastSelectPressed]
					end
				end
				Font10:DrawString(selectString, (bottomRight.X - Font10:GetStringWidthUTF8(selectString)/2) - 36, bottomRight.Y - 24, mainFontColor, 0, true)
				
			end
			
		end
		
	else
	
		for i=0, game:GetNumPlayers()-1 do
		
			local player = Isaac.GetPlayer(i)
			local data = player:GetData()
			
			--enable player controls
			if data.ConfigMenuPlayerPosition then
				data.ConfigMenuPlayerPosition = nil
			end
			if data.ConfigMenuPlayerControlsDisabled then
				player.ControlsEnabled = true
				data.ConfigMenuPlayerControlsDisabled = false
			end
			
		end
		
		configMenuInSubcategory = false
		configMenuInOptions = false
		configMenuInPopup = false
		
		holdingCounterDown = 0
		holdingCounterUp = 0
		holdingCounterLeft = 0
		holdingCounterRight = 0
		
		configMenuPositionCursorCategory = 1
		configMenuPositionCursorSubcategory = 1
		configMenuPositionCursorOption = 1
		optionsCurrentOffset = 0
		
	end
end)

CallbackHelper.AddCallback(ModConfigMenu.Mod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)
	ModConfigMenu.IsVisible = false
end)

function ModConfigMenu.OpenConfigMenu()

	if ModConfigMenu.RoomIsSafe() then
	
		if ModConfigMenu.Config["Mod Config Menu"].HideHudInMenu then
		
			local game = Game()
			local seeds = game:GetSeeds()
			seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
			
		end
		
		ModConfigMenu.IsVisible = true
		
	else
	
		local sfx = SFXManager()
		sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
		
	end
	
end

function ModConfigMenu.CloseConfigMenu()

	ModConfigMenu.LeavePopup()
	ModConfigMenu.LeaveOptions()
	ModConfigMenu.LeaveSubcategory()
	
	local game = Game()
	local seeds = game:GetSeeds()
	seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
	
	
	ModConfigMenu.IsVisible = false
	
end

function ModConfigMenu.ToggleConfigMenu()
	if ModConfigMenu.IsVisible then
		ModConfigMenu.CloseConfigMenu()
	else
		ModConfigMenu.OpenConfigMenu()
	end
end

--prevents the pause menu from opening when in the mod config menu
ModConfigMenu.Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, inputHook, buttonAction)
	if ModConfigMenu.IsVisible and buttonAction ~= ButtonAction.ACTION_FULLSCREEN and buttonAction ~= ButtonAction.ACTION_CONSOLE then
		if inputHook == InputHook.IS_ACTION_PRESSED or inputHook == InputHook.IS_ACTION_TRIGGERED then 
			return false
		else
			return 0
		end
	end
end)

--returns true if the room is clear and there are no active enemies and there are no projectiles
ModConfigMenu.IgnoreActiveEnemies = {}
function ModConfigMenu.RoomIsSafe()

	local roomHasDanger = false
	
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity:IsActiveEnemy() and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
		and (not ModConfigMenu.IgnoreActiveEnemies[entity.Type] or (ModConfigMenu.IgnoreActiveEnemies[entity.Type] and not ModConfigMenu.IgnoreActiveEnemies[entity.Type][-1] and not ModConfigMenu.IgnoreActiveEnemies[entity.Type][entity.Variant])) then
			roomHasDanger = true
		elseif entity.Type == EntityType.ENTITY_PROJECTILE and entity:ToProjectile().ProjectileFlags & ProjectileFlags.CANT_HIT_PLAYER ~= 1 then
			roomHasDanger = true
		elseif entity.Type == EntityType.ENTITY_BOMBDROP then
			roomHasDanger = true
		end
	end
	
	local game = Game()
	local room = game:GetRoom()
	
	if room:IsClear() and not roomHasDanger then
		return true
	end
	
	return false
	
end

local checkedForPotato = false
CallbackHelper.AddCallback(ModConfigMenu.Mod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)
	if not checkedForPotato then
	
		local potatoType = Isaac.GetEntityTypeByName("Potato Dummy")
		local potatoVariant = Isaac.GetEntityVariantByName("Potato Dummy")
		
		if potatoType and potatoType > 0 then
			ModConfigMenu.IgnoreActiveEnemies[potatoType] = {}
			ModConfigMenu.IgnoreActiveEnemies[potatoType][potatoVariant] = true
		end
		
		checkedForPotato = true
		
	end
end)

--console commands that toggle the menu
local toggleCommands = {
	["modconfigmenu"] = true,
	["modconfig"] = true,
	["mcm"] = true,
	["mc"] = true
}
ModConfigMenu.Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, command, args)
	command = command:lower()
	if toggleCommands[command] then
		ModConfigMenu.ToggleConfigMenu()
	end
end)


------------
--FINISHED--
------------
Isaac.DebugString("Mod Config Menu v" .. ModConfigMenu.Version .. " loaded!")
print("Mod Config Menu v" .. ModConfigMenu.Version .. " loaded!")


return ModConfigMenu
