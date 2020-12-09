local MAJOR_VERSION, MINOR_VERSION = "LibBlueItem-1.0", 2
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local _G = _G
local type = _G.type
local min = _G.math.min
local max = _G.math.max
local floor = _G.math.floor
local tonumber = _G.tonumber
local GetItemInfo = _G.GetItemInfo
local GetItemIcon = _G.GetItemIcon
local GetSpellInfo = _G.GetSpellInfo
local dummy, leftText, leftRed, leftGreen, leftBlue, rightText, rightRed, rightGreen, rightBlue = {}

lib.tooltip = lib.tooltip or CreateFrame("GameTooltip")
lib.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
lib.tooltip.left = lib.tooltip.left or {}
lib.tooltip.right = lib.tooltip.right or {}
for i = #lib.tooltip.left + 1, 50 do
	lib.tooltip.left[i] = lib.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	lib.tooltip.right[i] = lib.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	lib.tooltip:AddFontStrings(lib.tooltip.left[i], lib.tooltip.right[i])
end

lib.itemSubClassLocale = lib.itemSubClassLocale or {}
wipe(lib.itemSubClassLocale)
lib.itemSubClassLocale.AXES_1H,
lib.itemSubClassLocale.AXES_2H,
lib.itemSubClassLocale.BOWS,
lib.itemSubClassLocale.GUNS,
lib.itemSubClassLocale.MACES_1H,
lib.itemSubClassLocale.MACES_2H,
lib.itemSubClassLocale.POLEARMS,
lib.itemSubClassLocale.SWORD_1H,
lib.itemSubClassLocale.SWORD_2H,
lib.itemSubClassLocale.STAVES,
lib.itemSubClassLocale.FIST,
lib.itemSubClassLocale.OTHERS,
lib.itemSubClassLocale.DAGGERS,
lib.itemSubClassLocale.THROWN,
lib.itemSubClassLocale.CROSSBOWS,
lib.itemSubClassLocale.WANDS,
lib.itemSubClassLocale.FISHING_POLES = GetAuctionItemSubClasses(1)
lib.itemSubClassLocale.CLOTH,
lib.itemSubClassLocale.LEATHER,
lib.itemSubClassLocale.MAIL,
lib.itemSubClassLocale.PLATE,
lib.itemSubClassLocale.SHIELD,
lib.itemSubClassLocale.RELIC = select(2, GetAuctionItemSubClasses(2))

lib.enchantmentNames = lib.enchantmentNames or CopyTable(dummy)
wipe(lib.enchantmentNames)
lib.enchantmentNames[3290] = GetSpellInfo(52641)
lib.enchantmentNames[3599] = GetSpellInfo(54736)
lib.enchantmentNames[3601] = GetSpellInfo(54793)
lib.enchantmentNames[3603] = GetSpellInfo(54998)
lib.enchantmentNames[3604] = GetSpellInfo(54999)
lib.enchantmentNames[3605] = GetSpellInfo(55002)
lib.enchantmentNames[3859] = GetSpellInfo(63765)
lib.enchantmentNames[3860] = GetSpellInfo(63770)
lib.enchantmentNames[4179] = GetSpellInfo(82175)
lib.enchantmentNames[4180] = GetSpellInfo(82177)
lib.enchantmentNames[4181] = GetSpellInfo(82180)
lib.enchantmentNames[4182] = GetSpellInfo(82200)
lib.enchantmentNames[4183] = GetSpellInfo(82201)
lib.enchantmentNames[4187] = GetSpellInfo(84424)
lib.enchantmentNames[4188] = GetSpellInfo(84427)
lib.enchantmentNames[4214] = GetSpellInfo(84425)
lib.enchantmentNames[4222] = GetSpellInfo(67839)
lib.enchantmentNames[4223] = GetSpellInfo(55016)

local frostWeapon = GetSpellInfo(8033)
local defaultItem, defaultItemName, defaultItemEnchantPos, defaultItemEnchantText = 2570
defaultItemName = GetItemInfo(defaultItem)
if defaultItemName then
	if lib.frames then
		lib.frames:UnregisterAllEvents()
	end
else
	lib.frames = lib.frames or CreateFrame("Frame")
	lib.frames:UnregisterAllEvents()
	lib.frames:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	lib.frames:SetScript("OnEvent", function(self)
		defaultItemName = GetItemInfo(defaultItem)
		if defaultItemName then
			self:UnregisterAllEvents()
		end
	end)
end

local function makePattern(text)
	text = text:gsub("%.", "%%."):gsub("%(", "%%("):gsub("%)", "%%)"):gsub("%%d", "%([0%-9%%-]+%)"):gsub("%%s", "%(%.+%)")
	return text
end

local itemSetName = "^"..makePattern(ITEM_SET_NAME).."$"

local function clearTooltip()
	lib.tooltip:ClearLines()
	lib.tooltip:Hide()
end

local function setTooltip(method, ...)
	if type(lib.tooltip[method]) == "function" then
		lib.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		lib.tooltip[method](lib.tooltip, ...)
		lib.tooltip:Show()
		return true
	else
		clearTooltip()
		return nil
	end
end

local function getLine(line)
	if line and line:IsShown() and (line:GetText() or "") ~= "" then
		return line:GetText(), line:GetTextColor()
	end
	return nil
end

local function isNatural(num)
	num = tonumber(num)
	return num and num > 0 and num == floor(num) and num or nil
end

local function refreshDefaultItemName()
	defaultItemName = defaultItemName or GetItemInfo(defaultItem)
	return defaultItemName and true or nil
end

local function iterateTooltip(_, index)
	if lib.tooltip:IsShown() then
		index = index + 1
		while index <= min(#lib.tooltip.left, lib.tooltip:NumLines()) do
			leftText, leftRed, leftGreen, leftBlue = getLine(lib.tooltip.left[index])
			if leftText then
				rightText, rightRed, rightGreen, rightBlue = getLine(lib.tooltip.right[index])
				return index, leftText, rightText, leftRed, leftGreen, leftBlue, rightRed, rightGreen, rightBlue
			end
			index = index + 1
		end
	end
	leftText, leftRed, leftGreen, leftBlue, rightText, rightRed, rightGreen, rightBlue = nil
	clearTooltip()
end

function lib:UnpackTooltip(start, method, ...)
	if setTooltip(method, ...) then
		if lib.tooltip:NumLines() > 0 and lib.tooltip.left[1]:GetText() ~= RETRIEVING_ITEM_INFO then
			return iterateTooltip, nil, max(0, (start or 1) - 1)
		else
			clearTooltip()
		end
	end
	return pairs(dummy)
end

function lib:GetRandomSuffixFormat(code)
	if isNatural(code) and refreshDefaultItemName() then
		code = GetItemInfo("item:"..defaultItem..":0:0:0:0:0:-"..code..":1")
		if code and code:trim() ~= defaultItemName then
			code = code:match("^"..ITEM_SUFFIX_TEMPLATE:format(defaultItemName, "(.+)").."$")
			if code then
				return ITEM_SUFFIX_TEMPLATE:format("%s", code)
			end
		end
	end
	return nil
end

function lib:GetEnchantmentText(code)
	if lib.enchantmentNames[code] then
		return lib.enchantmentNames[code]
	elseif isNatural(code) and refreshDefaultItemName() then
		if not defaultItemEnchantPos then
			defaultItemEnchantPos = 4
			for i, text in lib:UnpackTooltip(2, "SetHyperlink", "item:"..defaultItem..":2") do
				if text and text == frostWeapon then
					defaultItemEnchantPos = i
					break
				end
			end
		end
		if defaultItemEnchantPos then
			defaultItemEnchantText = defaultItemEnchantText or (setTooltip("SetItemByID", defaultItem) and lib.tooltip:NumLines() >= defaultItemEnchantPos and lib.tooltip.left[defaultItemEnchantPos]:GetText())
			if defaultItemEnchantText then
				code = setTooltip("SetHyperlink", "item:"..defaultItem..":"..code) and lib.tooltip:NumLines() >= defaultItemEnchantPos and lib.tooltip.left[defaultItemEnchantPos]:GetText()
				if code ~= defaultItemEnchantText then
					return code
				end
			end
		end
	end
	return nil
end

function lib:GetItemSetName(code)
	code = tonumber(code)
	if code and GetItemIcon(code) then
		GetItemInfo(code)
		for i, text in lib:UnpackTooltip(4, "SetItemByID", code) do
			text = text:match(itemSetName)
			if text then
				return text, i
			end
		end
	end
	return nil
end

function lib:IsEnchantSpell(id)
	if id and GetSpellInfo(id) and setTooltip("SetHyperlink", "enchant:"..id) then
		leftText, leftRed, leftGreen, leftBlue = getLine(lib.tooltip.left[1])
		if leftText and leftBlue == 0 then
			leftRed, leftGreen, leftBlue = nil
			return leftText
		end
		leftText, leftRed, leftGreen, leftBlue = nil
	end
	return nil
end

function lib:GetItemSubClassLocales()
	return lib.itemSubClassLocale
end

local subClassValues = {
	[lib.itemSubClassLocale.SWORD_1H] = 2,
	[lib.itemSubClassLocale.SWORD_2H] = 2,
	[lib.itemSubClassLocale.MACES_1H] = 3,
	[lib.itemSubClassLocale.MACES_2H] = 3,
	[lib.itemSubClassLocale.AXES_1H] = 4,
	[lib.itemSubClassLocale.AXES_2H] = 4,
	[lib.itemSubClassLocale.DAGGERS] = 5,
	[lib.itemSubClassLocale.FIST] = 6,
	[lib.itemSubClassLocale.POLEARMS] = 7,
	[lib.itemSubClassLocale.STAVES] = 8,
	[lib.itemSubClassLocale.FISHING_POLES] = 9,
	[lib.itemSubClassLocale.SHIELD] = 10,
	[lib.itemSubClassLocale.GUNS] = 11,
	[lib.itemSubClassLocale.BOWS] = 12,
	[lib.itemSubClassLocale.CROSSBOWS] = 13,
	[lib.itemSubClassLocale.THROWN] = 14,
	[lib.itemSubClassLocale.WANDS] = 15,
	[lib.itemSubClassLocale.RELIC] = 16,
	[lib.itemSubClassLocale.CLOTH] = 17,
	[lib.itemSubClassLocale.LEATHER] = 18,
	[lib.itemSubClassLocale.MAIL] = 19,
	[lib.itemSubClassLocale.PLATE] = 20,
}

local equipLocValues = {
	INVTYPE_2HWEAPON = 100,
	INVTYPE_WEAPONMAINHAND = 200,
	INVTYPE_WEAPON = 300,
	INVTYPE_WEAPONOFFHAND = 400,
	INVTYPE_RANGED = 500,
	INVTYPE_RANGEDRIGHT = 500,
	INVTYPE_THROWN = 500,
	INVTYPE_SHIELD = 600,
	INVTYPE_HOLDABLE = 700,
	INVTYPE_RELIC = 800,
	INVTYPE_HEAD = 900,
	INVTYPE_SHOULDER = 1000,
	INVTYPE_CHEST = 1100,
	INVTYPE_ROBE = 1100,
	INVTYPE_LEGS = 1200,
	INVTYPE_HAND = 1300,
	INVTYPE_WRIST = 1400,
	INVTYPE_WAIST = 1500,
	INVTYPE_FEET = 1600,
	INVTYPE_CLOAK = 1700,
	INVTYPE_NECK = 1800,
	INVTYPE_FINGER = 1900,
	INVTYPE_TRINKET = 2000,
	INVTYPE_BODY = 2100,
	INVTYPE_TABARD = 2200,
}

local function lookup(tbl, value)
	for p, v in pairs(tbl) do
		if v == value then
			return p
		end
	end
	return nil
end

function lib:GetItemEquipCode(a1, a2)
	if isNatural(a1) then
		local itemSubClass, _, itemEquipLoc = select(7, GetItemInfo(tonumber(a1)))
		if itemSubClass then
			return (subClassValues[itemSubClass] or 99) + (equipLocValues[itemEquipLoc] or 9900)
		end
	elseif type(a1) == "string" and type(a2) == "string" and (subClassValues[a1] or equipLocValues[a2]) then
		return (subClassValues[a1] or 99) + (equipLocValues[a2] or 9900)
	end
	return nil
end

function lib:GetItemEquipInfo(code)
	code = isNatural(code)
	if code and code > 100 and code < 10000 then
		local itemEquipLoc = lookup(equipLocValues, code - (code % 100))
		if itemEquipLoc then
			local itemSubClass = lookup(subClassValues, code % 100) or lib.itemSubClassLocale.OTHERS
			if itemEquipLoc == "INVTYPE_2HWEAPON" then
				if itemSubClass == lib.itemSubClassLocale.AXES_1H then
					itemSubClass = lib.itemSubClassLocale.AXES_2H
				elseif itemSubbClass == lib.itemSubClassLocale.MACES_1H then
					itemSubClass = lib.itemSubClassLocale.MACES_2H
				elseif itemSubClass == lib.itemSubClassLocale.SWORD_1H then
					itemSubClass = lib.itemSubClassLocale.SWORD_2H
				end
			elseif itemEquipLoc:find("WEAPON") then
				if itemSubClass == lib.itemSubClassLocale.AXES_2H then
					itemSubClass = lib.itemSubClassLocale.AXES_1H
				elseif itemSubClass == lib.itemSubClassLocale.MACES_2H then
					itemSubClass = lib.itemSubClassLocale.MACES_1H
				elseif itemSubClass == lib.itemSubClassLocale.SWORD_2H then
					itemSubClass = lib.itemSubClassLocale.SWORD_1H
				end
			elseif itemSubClass == lib.itemSubClassLocale.THROWN then
				itemEquipLoc = "INVTYPE_THROWN"
			end
			return itemSubClass, itemEquipLoc
		end
	end
	return nil
end