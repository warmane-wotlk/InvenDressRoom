local addOnName, dummy = ...
local _G = _G
local IDR = _G[GetAddOnDependencies(addOnName)]
local type = _G.type
local pairs = _G.pairs
local ipairs = _G.ipairs
local select = _G.select
local tonumber = _G.tonumber
local wipe = _G.wipe
local tinsert = _G.table.insert
local GetItemIcon = _G.GetItemIcon
local GetItemInfo = _G.GetItemInfo
local GetMouseFocus = _G.GetMouseFocus
local GetCursorInfo = _G.GetCursorInfo
local GetAddOnMetadata = _G.GetAddOnMetadata
local LBICR = LibStub("LibBlueItemCacheReceiver-1.0")
local LBID = LibStub("LibBlueItemDrag-1.0")

local basicDress = { 7051, 10035 }
local races = { "Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen", "Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin" }
local raceLocales = {
	Draenei = GetAchievementCriteriaInfo(1005, 1),
	Dwarf = GetAchievementCriteriaInfo(1005, 2),
	Gnome = GetAchievementCriteriaInfo(1005, 3),
	Human = GetAchievementCriteriaInfo(1005, 4),
	NightElf = GetAchievementCriteriaInfo(1005, 5),
	Worgen = GetAchievementCriteriaInfo(1005, 6),
	BloodElf = GetAchievementCriteriaInfo(246, 1),
	Goblin = GetAchievementCriteriaInfo(246, 2),
	Orc = GetAchievementCriteriaInfo(246, 3),
	Tauren = GetAchievementCriteriaInfo(246, 4),
	Troll = GetAchievementCriteriaInfo(246, 5),
	Scourge = GetAchievementCriteriaInfo(246, 6),
}
local playerModelFileIndex = {}

do
	for i, race in ipairs(races) do
		raceLocales[race.."Male"] = tostring(raceLocales[race]).." ("..MALE..")"
		raceLocales[race.."Female"] = tostring(raceLocales[race]).." ("..FEMALE..")"
		raceLocales[race] = nil
		race = race:lower()
		playerModelFileIndex["character\\"..race.."\\male\\"..race.."male.m2"] = (i - 1) * 2 + 1
		playerModelFileIndex["character\\"..race.."\\female\\"..race.."female.m2"] = i * 2
	end
end

local itemModelSettings = {
	INVTYPE_HEAD = {
		{ 0.77, 0, -0.19 },		{ 0.75, 0, -0.25 },		-- Human
		{ 0.55, 0, -0.25 },		{ 0.67, 0, -0.21 },		-- Dwarf
		{ 0.8, 0, -0.25 },		{ 0.8, 0, -0.22 },		-- NightElf
		{ 0.45, 0, -0.22 },		{ 0.45, 0, -0.2 },		-- Gnome
		{ 0.74, 0, -0.32 },		{ 0.77, 0, -0.25 },		-- Draenei
		{ 0.65, 0, -0.35 },		{ 0.8, 0, -0.25 },		-- Worgen
		{ 0.6, 0, -0.32 },		{ 0.74, 0, -0.26 },		-- Orc
		{ 0.7, -0.12, -0.2 },	{ 0.75, 0.035, -0.18 },	-- Scourge
		{ 0.55, 0.04, -0.36 },	{ 0.67, 0, -0.36 },		-- Tauren
		{ 0.7, 0.05, -0.2 },	{ 0.75, -0.05, -0.25 },	-- Troll
		{ 0.72, -0.12, -0.22 },	{ 0.77, -0.05, -0.22 },	-- BloodElf
		{ 0.6, 0, -0.15 },		{ 0.55, 0, -0.24 },		-- Goblin
    },
    INVTYPE_SHOULDER = {
		{ 0.45, 0, -0.15 },		{ 0.55, 0, -0.2 },		-- Human
		{ 0.35, 0, -0.15 },		{ 0.5, 0, -0.08 },		-- Dwarf
		{ 0.55, 0, -0.2 },		{ 0.65, -0.02, -0.08 },	-- NightElf
		{ 0.45, 0, 0 },		{ 0.45, 0, 0 },		-- Gnome
		{ 0.4, -0.02, -0.2 },	{ 0.67, -0.02, -0.1 },	-- Draenei
		{ 0.4, 0, -0.4 },		{ 0.6, 0.04, -0.12 },	-- Worgen
		{ 0.35, 0, -0.35 },		{ 0.55, -0.02, -0.15 },	-- Orc
		{ 0.55, -0.12, -0.15 },	{ 0.65, -0.02, -0.04 },	-- Scourge
		{ 0.2, 0, -0.45 },		{ 0.45, 0, -0.2 },		-- Tauren
		{ 0.5, 0, -0.2 },		{ 0.6, -0.05, -0.08 },	-- Troll
		{ 0.5, -0.08, -0.15 },	{ 0.65, -0.05, -0.05 },	-- BloodElf
		{ 0.45, 0, 0.05 },		{ 0.45, 0, -0.05 },		-- Goblin
	},
	INVTYPE_CLOAK = {
		{ 0.3, 0, 0.22 },		{ 0.28, 0, 0.16 },		-- Human
		{ 0.3, 0, 0.18 },		{ 0.3, 0, 0.18 },		-- Dwarf
		{ 0.28, 0, 0.18 },		{ 0.3, 0, 0, 0.18 },	-- NightElf
		{ 0.4, 0, 0.2 },		{ 0.4, 0, 0.2 },		-- Gnome
		{ 0.3, 0, 0.2 },		{ 0.3, 0, 0.2 },		-- Draenei
		{ 0.3, 0, 0.1 },		{ 0.45, 0, 0.3 },		-- Worgen
		{ 0.3, 0, 0.24 },		{ 0.28, 0, 0.24 },		-- Orc
		{ 0.22, -0.12, 0.16 },	{ 0.3, 0, 0.28 },		-- Scourge
		{ 0.25, 0, 0.12 },		{ 0.28, 0, 0.18 },		-- Tauren
		{ 0.3, 0, 0.18 },		{ 0.3, -0.05, 0.22 },	-- Troll
		{ 0.3, -0.1, 0.22 },	{ 0.28, 0, 0.2 },		-- BloodElf
		{ 0.28, 0, 0.2 },		{ 0.28, 0, 0.2 },		-- Goblin
	},
	INVTYPE_HAND = {
		{ 0.58, 0, 0.3 },		{ 0.62, 0, 0.26 },		-- Human
		{ 0.32, 0, 0.16 },		{ 0.48, 0, 0.2 },		-- Dwarf
		{ 0.6, 0, 0.34 },		{ 0.7, 0, 0.4 },		-- NightElf
		{ 0.5, 0, 0.18 },		{ 0.48, 0, 0.22 },		-- Gnome
		{ 0.48, -0.05, 0.25 },	{ 0.7, 0, 0.5 },		-- Draenei
		{ 0.4, 0, 0.18 },		{ 0.7, 0.05, 0.62 },	-- Worgen
		{ 0.45, 0.05, 0.3 },	{ 0.55, 0, 0.3 },		-- Orc
		{ 0.5, -0.05, 0.35 },	{ 0.65, 0, 0.4 },		-- Scourge
		{ 0.38, 0, 0.25 },		{ 0.5, 0, 0.35 },		-- Tauren
		{ 0.6, 0, 0.5 },		{ 0.7, -0.05, 0.6 },	-- Troll
		{ 0.65, -0.1, 0.5 },	{ 0.8, -0.08, 0.5 },	-- BloodElf
		{ 0.5, 0, 0.5 },		{ 0.5, 0, 0.5 },		-- Goblin
	},
	INVTYPE_LEGS = {
		{ 0.45, 0, 0.85 },		{ 0.4, 0, 0.7 },		-- Human
		{ 0.5, 0, 0.7 },		{ 0.5, 0, 0.7 },		-- Dwarf
		{ 0.5, 0, 1.1 },		{ 0.48, 0, 0.95 },		-- NightElf
		{ 0.7, 0, 0.5 },		{ 0.7, 0, 0.5 },		-- Gnome
		{ 0.52, 0, 0.14 },		{ 0.5, 0, 1 },			-- Draenei
		{ 0.6, 0, 0.97 },		{ 0.58, 0, 1.1 },		-- Worgen
		{ 0.48, 0, 0.9 },		{ 0.42, 0, 0.8 },		-- Orc
		{ 0.42, -0.1, 0.7 },	{ 0.52, 0, 0.85 },		-- Scourge
		{ 0.55, 0, 0.85 },		{ 0.55, 0, 1.05 },		-- Tauren
		{ 0.5, 0, 0.95 },		{ 0.45, 0, 1 },		-- Troll
		{ 0.48, 0, 0.85 },		{ 0.45, 0, 0.8 },		-- BloodElf
		{ 0.58, 0, 0.7 },		{ 0.7, 0, 0.72 },		-- Goblin
	},
}
itemModelSettings.INVTYPE_CHEST = itemModelSettings.INVTYPE_SHOULDER
itemModelSettings.INVTYPE_ROBE = itemModelSettings.INVTYPE_CLOAK
itemModelSettings.INVTYPE_WAIST = itemModelSettings.INVTYPE_HAND
itemModelSettings.INVTYPE_WRIST = itemModelSettings.INVTYPE_HAND
itemModelSettings.INVTYPE_FEET = itemModelSettings.INVTYPE_LEGS

IDR.raceList.button:SetScript("OnClick", IDR.DropDownButtonOnMenu)

local function addRaceButton(info, level, race)
	info.text = raceLocales[race]
	info.arg1 = race
	info.checked = IDR.db.currentItems.modelRace == race
	UIDropDownMenu_AddButton(info, level)
end

local function setRaceButton(_, race)
	if IDR.db.currentItems.modelRace ~= race then
		IDR:SetDressUpRace(race)
	end
end

UIDropDownMenu_Initialize(IDR.raceList, function(self, level)
	if level then
		local info = UIDropDownMenu_CreateInfo()
		info.func = setRaceButton
		for _, race in ipairs(races) do
			addRaceButton(info, level, race.."Male")
			addRaceButton(info, level, race.."Female")
		end
	end
end)

local raceModelIndex = {
	HumanMale = 1,
	HumanFemale = 1,
	OrcMale = 2,
	OrcFemale = 2,
	DwarfMale = 3,
	DwarfFemale = 3,
	NightElfMale = 4,
	NightElfFemale = 4,
	ScourgeMale = 5,
	ScourgeFemale = 5,
	TaurenMale = 6,
	TaurenFemale = 6,
	GnomeMale = 7,
	GnomeFemale = 7,
	TrollMale = 8,
	TrollFemale = 8,
	GoblinMale = 9,
	GoblinFemale = 9,
	BloodElfMale = 10,
	BloodElfFemale = 10,
	DraeneiMale = 11,
	DraeneiFemale = 11,
	WorgenMale = 22,
	WorgenFemale = 22,
}
local raceModelOverlayAlpha = {
	BloodElf = 0.8,
	NightElf = 0.6,
	Scourge = 0.3,
	Troll = 0.6,
	Orc = 0.6,
	Worgen = 0.5,
	Goblin = 0.6,
}
local itemSubClasses, itemSubClass, itemEquipLoc, numList = {}

for p, v in pairs(LibStub("LibBlueItem-1.0").itemSubClassLocale) do
	itemSubClasses[v] = p
end

local function hideItemSlotMenu(btn)
	if UIDROPDOWNMENU_OPEN_MENU and (UIDROPDOWNMENU_OPEN_MENU:GetParent() == btn or UIDROPDOWNMENU_OPEN_MENU:GetParent() == btn.menuButton) then
		CloseDropDownMenus(1)
	end
end

local function isOneHandWeapon(equip, stype)
	if equip == "2HWEAPON" then
		return stype and stype:find("_2H$")
	else
		return equip:find("WEAPON")
	end
end

local function tryOnItem(item)
	for slot, btn in pairs(IDR.itemSlots) do
		if btn.item == item then
			hideItemSlotMenu(btn)
			btn.noItem = nil
			btn.equipLoc = IDR:GetItemEquipLoc(item)
			if btn.equipLoc then
				btn.icon:SetVertexColor(1, 1, 1)
				if btn.equipLoc:find("_") then
					btn.equipLoc, btn.subType = btn.equipLoc:match("([^_]+)_(.+)")
				end
				if slot == "MainHandSlot" or slot == "SecondaryHandSlot" then
					btn.tryOn = nil
					if btn.equipLoc:find("WEAPON") then
						if type(btn.enchant) == "number" and btn.enchant > 0 then
							btn.itemLink = select(2, GetItemInfo("item:"..item..":"..btn.enchant))
						else
							btn.itemLink = select(2, GetItemInfo(item))
						end
						btn.menuButton:Enable()
					elseif IDR.equipSlots[btn.equipLoc] == slot then
						btn.itemLink = select(2, GetItemInfo(item))
					else
						btn.icon:SetVertexColor(1, 0.02, 0.02)
					end
					if IDR.db.showWeapon == 1 and ((IDR.itemSlots.MainHandSlot.item and IDR.itemSlots.MainHandSlot.itemLink) or not IDR.itemSlots.MainHandSlot.item) and ((IDR.itemSlots.SecondaryHandSlot.item and IDR.itemSlots.SecondaryHandSlot.itemLink) or not IDR.itemSlots.SecondaryHandSlot.item) then
						if IDR.itemSlots.MainHandSlot.itemLink and IDR.itemSlots.SecondaryHandSlot.itemLink then
							if isOneHandWeapon(IDR.itemSlots.MainHandSlot.equipLoc, IDR.itemSlots.MainHandSlot.subType) then
								if IDR.itemSlots.SecondaryHandSlot.equipLoc == "HOLDABLE" or IDR.itemSlots.SecondaryHandSlot.equipLoc == "SHIELD" then
									IDR.modelFrame:TryOn(IDR.itemSlots.SecondaryHandSlot.itemLink)
									IDR.modelFrame:TryOn(IDR.itemSlots.MainHandSlot.itemLink)
								elseif isOneHandWeapon(IDR.itemSlots.SecondaryHandSlot.equipLoc, IDR.itemSlots.SecondaryHandSlot.subType) then
									IDR.modelFrame:TryOn(IDR.itemSlots.SecondaryHandSlot.itemLink)
									IDR.modelFrame:TryOn(IDR.itemSlots.SecondaryHandSlot.itemLink)
									IDR.modelFrame:TryOn(IDR.itemSlots.SecondaryHandSlot.itemLink)
									IDR.modelFrame:TryOn(IDR.itemSlots.MainHandSlot.itemLink)
								else
									IDR.modelFrame:TryOn(IDR.itemSlots.MainHandSlot.itemLink)
									IDR.itemSlots.SecondaryHandSlot.icon:SetVertexColor(1, 0.02, 0.02)
								end
							else
								IDR.modelFrame:TryOn(IDR.itemSlots.MainHandSlot.itemLink)
								IDR.itemSlots.SecondaryHandSlot.icon:SetVertexColor(1, 0.02, 0.02)
							end
						elseif IDR.itemSlots.MainHandSlot.itemLink then
							IDR.modelFrame:TryOn(IDR.itemSlots.MainHandSlot.itemLink)
						elseif IDR.itemSlots.SecondaryHandSlot.itemLink then
							IDR.modelFrame:TryOn(IDR.itemSlots.SecondaryHandSlot.itemLink)
						end
					end
					if IDR.itemSlots.MainHandSlot.item ~= item or IDR.itemSlots.SecondaryHandSlot.item ~= item then
						return
					end
				elseif IDR.equipSlots[btn.equipLoc] == slot then
					btn.itemLink = select(2, GetItemInfo(item))
					if btn.tryOn then
						btn.tryOn = nil
						IDR.modelFrame:TryOn(item)
					end
					return
				else
					btn.icon:SetVertexColor(1, 0.02, 0.02)
				end
			else
				btn.icon:SetVertexColor(1, 0.02, 0.02)
			end
			if btn:IsMouseOver() and GetMouseFocus() == btn then
				btn:GetScript("OnEnter")(btn)
			end
		end
	end
end

function IDR:Refresh()
	CloseDropDownMenus(1)
	self:CloseAllStaticPopups()
	self:SetDressUpRace(self.db.currentItems.modelRace)
	UIDropDownMenu_SetText(self.profileSelector, self.db.currentItemSet or "저장된 프로필 없음")
	if next(self.db.itemSets) then
		UIDropDownMenu_EnableDropDown(self.profileSelector)
		UIDropDownMenu_EnableDropDown(self.profileDelete)
	else
		UIDropDownMenu_DisableDropDown(self.profileSelector)
		UIDropDownMenu_DisableDropDown(self.profileDelete)
	end
end

function IDR:SetDressUpRace(race)
	if self.raceList.safe then
		race = self.defaultModelRace
	else
		if not raceModelIndex[race] then
			race = self.defaultModelRace
		end
		self.db.currentItems.modelRace = race
	end
	UIDropDownMenu_SetText(self.raceList, raceLocales[race])
	self.modelRaceIndex = raceModelIndex[race]
	self.modelRaceSex = race:find("Male$") and 0 or 1
	race = race:match(self.modelRaceSex == 0 and "(.+)Male$" or "(.+)Female$")
	self.modelFrame.BackgroundOverlay:SetAlpha(raceModelOverlayAlpha[race] or 0.7)
	race = DressUpTexturePath(race)
	self.modelFrame.BackgroundTopLeft:SetTexture(race..1)
	self.modelFrame.BackgroundTopLeft:SetDesaturated(true)
	self.modelFrame.BackgroundTopRight:SetTexture(race..2)
	self.modelFrame.BackgroundTopRight:SetDesaturated(true)
	self.modelFrame.BackgroundBotLeft:SetTexture(race..3)
	self.modelFrame.BackgroundBotLeft:SetDesaturated(true)
	self.modelFrame.BackgroundBotRight:SetTexture(race..4)
	self.modelFrame.BackgroundBotRight:SetDesaturated(true)
	self.modelFrame:SetCustomRace(self.modelRaceIndex, self.modelRaceSex)
	self:SetPlayerModel()
	self:UpdateDetail()
	self.modelTooltip.model:SetCustomRace(self.modelRaceIndex, self.modelRaceSex)
	self:ModelPreviewRefresh()
end

function IDR:SetPlayerModel()
	LBICR:UnregisterAllItemCache(tryOnItem)
	self.modelFrame:Undress()
	self.weaponEnchantMenu:Hide()
	for slot, btn in pairs(self.itemSlots) do
		btn.itemLink, btn.equipLoc, btn.subType = nil
		if self.db.currentItems[slot] and GetItemIcon(self.db.currentItems[slot]) and not GetAddOnMetadata(addOnName, "X-NoTransmogrifyItem-"..self.db.currentItems[slot]) then
			btn.item = self.db.currentItems[slot]
			btn.enchant = self.db.currentItems[slot.."Enchant"]
			local itemIcon = GetItemIcon(btn.item)
   			if itemIcon then
				btn.icon:SetTexture(itemIcon)
				btn.icon:SetVertexColor(0.02, 0.02, 1)
				btn.noItem = true
				if slot == "HeadSlot" then
					btn.tryOn = self.db.showHelm
				elseif slot == "BackSlot" then
					btn.tryOn = self.db.showCloak
				elseif slot == "RangedSlot" then
					btn.tryOn = self.db.showWeapon == 2
				elseif slot ~= "MainHandSlot" and slot ~= "SecondaryHandSlot" then
					btn.tryOn = true
				end
			end
		else
			btn.item, btn.enchant, btn.noItem, btn.tryOn = nil
			btn.icon:SetTexture(btn.backgroundTextureName)
			btn.icon:SetVertexColor(1, 1, 1)
		end
		hideItemSlotMenu(btn)
	end
	self.itemSlots.MainHandSlot.menuButton:Disable()
	self.itemSlots.SecondaryHandSlot.menuButton:Disable()
	if self.itemSlots.MainHandSlot.item or self.itemSlots.SecondaryHandSlot.item or self.itemSlots.RangedSlot.item then
		self.itemSlots.RangedSlot.menuButton:Enable()
	else
		self.itemSlots.RangedSlot.menuButton:Disable()
	end
	for _, btn in pairs(self.itemSlots) do
		if btn.item then
			LBICR:RegisterItemCache(btn.item, tryOnItem)
		end
	end
	if self:IsCurrentItemSetResetable() then
		self.undressAllItems:Enable()
	else
		self.undressAllItems:Disable()
	end
	if self:IsCurrentItemSetChanged() then
		self.profileSave:Enable()
	else
		self.profileSave:Disable()
	end
end

function IDR:CheckDualWeapon(main, off)
	main = main or self.itemSlots.MainHandSlot.item
	off = off or self.itemSlots.SecondaryHandSlot.item
end

function IDR:GetCursorItem()
	local itemID, itemLink = LBID:GetCursorItem()
	if itemID then
		local equipLoc = self:GetItemEquipLoc(itemID)
		if equipLoc then
			local subType
			if equipLoc:find("_") then
				equipLoc, subType = equipLoc:match("([^_]+)_(.+)")
			end
			if self.itemSlots[self.equipSlots[equipLoc]] then
				local itemRarity = select(3, GetItemInfo(itemID))
				if itemRarity and (itemRarity == 2 or itemRarity == 3 or itemRarity == 4 or itemRarity == 7) and not GetAddOnMetadata(addOnName, "X-NoTransmogrifyItem-"..itemID) then
					return itemID, itemLink, equipLoc, subType
				end
			end
		end
	end
	return nil
end

function IDR:CURSOR_UPDATE()
	for _, btn in pairs(self.itemSlots) do
		btn:UnlockHighlight()
	end
	local equipLoc, subType = select(3, self:GetCursorItem())
	if equipLoc then
		self.itemSlots[self.equipSlots[equipLoc]]:LockHighlight()
		if equipLoc == "WEAPON" or (equipLoc == "2HWEAPON" and subType and subType:find("_2H$")) then
			self.itemSlots.SecondaryHandSlot:LockHighlight()
		end
	end
end

function IDR:GetItemEquipLoc(item)
	itemSubClass, _, itemEquipLoc = select(7, GetItemInfo(item))
	if itemEquipLoc and itemEquipLoc ~= "" then
		itemEquipLoc = itemEquipLoc:gsub("INVTYPE_", ""):gsub("ROBE", "CHEST"):gsub("THROWN", "RANGED"):gsub("RANGEDRIGHT", "RANGED")
		if GetAddOnMetadata(addOnName, "X-DB-"..itemEquipLoc) then
			return itemEquipLoc
		elseif itemSubClasses[itemSubClass] then
			itemEquipLoc = itemEquipLoc.."_"..itemSubClasses[itemSubClass]
			if GetAddOnMetadata(addOnName, "X-DB-"..itemEquipLoc) then
				return itemEquipLoc
			end
		end
	end
	return nil
end

local function findItem(item, db)
	itemSubClass, _, itemEquipLoc = select(7, GetItemInfo(item))
	if itemEquipLoc then
		if db == "DB2" then
			itemEquipLoc = itemEquipLoc:gsub("MAINHAND", ""):gsub("OFFHAND", "")
		end
		db = "X-"..db.."-"
		itemEquipLoc = db..itemEquipLoc:gsub("INVTYPE_", ""):gsub("ROBE", "CHEST"):gsub("THROWN", "RANGED"):gsub("RANGEDRIGHT", "RANGED")
		numList = GetAddOnMetadata(addOnName, itemEquipLoc)
		if not numList and itemSubClasses[itemSubClass] then
			itemEquipLoc = itemEquipLoc.."_"..itemSubClasses[itemSubClass]
			numList = GetAddOnMetadata(addOnName, itemEquipLoc)
		end
		if numList then
			item = item..""
			itemEquipLoc = itemEquipLoc.."-"
			for i = 1, tonumber(numList) do
				itemSubClass = IDR:GetItemList(itemEquipLoc..i)
				if item == itemSubClass or (itemSubClass:find(item) and (itemSubClass:find("^"..item..",") or itemSubClass:find(","..item..",") or itemSubClass:find(","..item.."$"))) then
					return itemSubClass
				end
			end
		end
	end
	return nil
end

function IDR:GetSameItemList(item)
	return findItem(item, "DB") or (item.."")
end

function IDR:GetSimilarItemList(item)
	return findItem(item, "DB2") or findItem(item, "DB") or (item.."")
end

function IDR:GetItemList(meta)
	local data = GetAddOnMetadata(addOnName, meta)
	if data then
		local index, new = 1, GetAddOnMetadata(addOnName, meta.."-1")
		while new do
			data = data..","..new
			index = index + 1
			new = GetAddOnMetadata(addOnName, meta.."-"..index)
		end
		return data
	else
		return ""
	end
end

local function dressUpBasicCloth(model)
	model:Undress()
	for _, item in ipairs(basicDress) do
		model:TryOn(item)
	end
end

local function modelPreview(item)
	LBICR:UnregisterAllItemCache(modelPreview)
	IDR.modelTooltip.model.item = item
	IDR.modelTooltip.loading:Hide()
	dressUpBasicCloth(IDR.modelTooltip.model)

	if type(IDR.modelTooltip.model.enchant) == "number" and IDR.modelTooltip.model.enchant > 0 then
		IDR.modelTooltip.model:TryOn("item:"..item..":"..IDR.modelTooltip.model.enchant)
	else
		IDR.modelTooltip.model:TryOn(item)
	end
	--IDR.modelTooltip.model:RefreshCamera()
	--IDR.modelTooltip.model:SetPortraitZoom(0)
	IDR.modelTooltip.model:SetPosition(0, 0, 0)
	item = select(9, GetItemInfo(item))
	if item == "INVTYPE_CLOAK" then
		IDR.modelTooltip.model:SetScript("OnUpdate", nil)
		IDR.modelTooltip.model:SetRotation(PI, true)
	else
		IDR.modelTooltip.model:SetScript("OnUpdate", IDR.modelTooltip.model.onUpdate)
	end
	item = itemModelSettings[item] and itemModelSettings[item][playerModelFileIndex[(IDR.modelTooltip.model:GetModel() or ""):lower()]]
	if item then
		local scale = IDR.modelTooltip.model:GetModelScale() * UIParent:GetEffectiveScale()
		--IDR.modelTooltip.model:SetPortraitZoom(item[1])
		IDR.modelTooltip.model:SetPosition(0, item[2] * scale, item[3] * scale)
	end
	IDR.modelTooltip.model:SetAlpha(1)
end

function IDR:ModelPreviewShow(btn, model, enchant, xoffset, yoffset)
	LBICR:UnregisterAllItemCache(modelPreview)
	self.enterCategoryModel, self.modelTooltip.model.item = model
	self.modelTooltip:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", xoffset or 0, yoffset or 0)
	self.modelTooltip:SetAlpha(1)
	self.modelTooltip:SetBackdropColor(0, 0, 0, 1)
	self.modelTooltip.loading:Show()
	self.modelTooltip.model:SetAlpha(0)
	self.modelTooltip.model:SetScript("OnUpdate", nil)
	self.modelTooltip.model.enchant = enchant
	if type(model) == "number" then
		LBICR:RegisterItemCache(model, modelPreview)
	else
		for item in self:GetItemList("X-DB-"..model):gmatch("(%d+)") do
			if LBICR:RegisterItemCache(tonumber(item), modelPreview) then
				break
			end
		end
	end

end

function IDR:ModelPreviewHide()
	LBICR:UnregisterAllItemCache(modelPreview)
	self.enterCategoryModel, self.modelTooltip.model.item = nil
	self.modelTooltip:SetAlpha(0)
	self.modelTooltip.model:SetScript("OnUpdate", nil)
	self.modelTooltip.model:SetAlpha(1)
	self.modelTooltip.model:SetAlpha(0)
	self.modelTooltip.loading:Hide()
end

function IDR:ModelPreviewRefresh()
	if self.modelTooltip.model.item and not self.modelTooltip.loading:IsShown() then
		modelPreview(self.modelTooltip.model.item)
	end
end

local detailItems, hasItemCache, visibleItem = {}, {}, {}

local function updateDetailItem(btn)
	btn:SetText((IDR:IsFavoriteItem(btn:GetID()) and "|TInterface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons:0:0:0:0:64:16:48:64:0:16|t" or "")..(select(2, GetItemInfo(btn:GetID())):gsub("%[", ""):gsub("%]", "")))
	btn.noItem = nil
end

local function setDetailItem(item)
	if IDR.selectedEquipLoc == "SET" then
		if not IDR.detailModelFrame:IsShown() then
			IDR.detailModelFrame:Show()
			IDR.detailModelFrame:SetCustomRace(IDR.modelRaceIndex, IDR.modelRaceSex)
			dressUpBasicCloth(IDR.detailModelFrame)
			IDR.detailModelFrame.loading:Hide()
		end
		IDR.detailModelFrame:TryOn(item)
	elseif not IDR.detailModelFrame:IsShown() then
		IDR.detailModelFrame:Show()
		IDR.detailModelFrame:SetCustomRace(IDR.modelRaceIndex, IDR.modelRaceSex)
		dressUpBasicCloth(IDR.detailModelFrame)
		IDR.detailModelFrame:TryOn(item)
		IDR.detailModelFrame.loading:Hide()
	end
	hasItemCache[item] = true
	if visibleItem[item] then
		updateDetailItem(IDR.detailItems[visibleItem[item]])
	end
end

function IDR:UpdateDetail()
	self.itemListMenu:Hide()
	wipe(detailItems)
	wipe(hasItemCache)
	wipe(visibleItem)
	LBICR:UnregisterAllItemCache(setDetailItem)
	self.detailModelFrame:Hide()
	if self.selectedModel then
		for item in self:GetItemList("X-DB-"..self.selectedModel):gmatch("(%d+)") do
			item = tonumber(item)
			tinsert(detailItems, item)
		end
	end
	if detailItems[1] then
		self.detailModelFrame.loading:Show()
	else
		self.detailModelFrame.loading:Hide()
	end
	FauxScrollFrame_SetOffset(self.detailItemScroll, 0)
	self:UpdateDetailItems()
end

function IDR:UpdateDetailItems()
	wipe(visibleItem)
	local offset = FauxScrollFrame_GetOffset(IDR.detailItemScroll) or 0
	for i, btn in ipairs(IDR.detailItems) do
		item = detailItems[offset + i]
		if item then
			visibleItem[item] = i
			btn:SetID(item)
			local itemIcon = GetItemIcon(item)
			if itemIcon then
				btn:SetNormalTexture(itemIcon)
				if hasItemCache[item] then
					updateDetailItem(btn)
				else
					btn:SetText("#"..item)
					btn.noItem = true
					LBICR:RegisterItemCache(item, setDetailItem)
				end
				btn:Show()
				if btn:IsMouseOver() and GetMouseFocus() == btn then
					btn:GetScript("OnEnter")(btn)
				end
			end
		else
			btn:Hide()
			btn.noItem = nil
		end
	end
	FauxScrollFrame_Update(IDR.detailItemScroll, #detailItems, #IDR.detailItems, 17)
	IDR:HideAllDropdown()
end

local detailItems2, hasItemCache2, visibleItem2 = {}, {}, {}

local function setMenuItem(item)
	hasItemCache2[item] = true
	if visibleItem2[item] then
		updateDetailItem(IDR.itemListMenu.items[visibleItem2[item]])
	end
end

function IDR:ClearItemListMenu()
	wipe(detailItems2)
	wipe(hasItemCache2)
	wipe(visibleItem2)
	LBICR:UnregisterAllItemCache(setMenuItem)
end

function IDR:ShowItemListMenu(anchor, right, base, items)
	self.itemListMenu:ClearAllPoints()
	if right then
		self.itemListMenu.right = true
		self.itemListMenu:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 8)
	else
		self.itemListMenu.right = nil
		self.itemListMenu:SetPoint("TOPRIGHT", anchor, "TOPLEFT", 0, 8)
	end
	self.itemListMenu:Show()
	self:ClearItemListMenu()
	for item in items:gmatch("(%d+)") do
		tinsert(detailItems2, tonumber(item))
	end
	FauxScrollFrame_SetOffset(self.itemListMenu.scroll, 0)
	_G[self.itemListMenu.scroll:GetName().."ScrollBar"]:SetValue(0)
	self:UpdateItemListMenuItems()
end

function IDR:UpdateItemListMenuItems()
	wipe(visibleItem2)
	local offset = FauxScrollFrame_GetOffset(IDR.itemListMenu.scroll) or 0
	for i, btn in ipairs(IDR.itemListMenu.items) do
		item = detailItems2[offset + i]
		if item then
			visibleItem2[item] = i
			btn:SetID(item)
			local itemIcon = GetItemIcon(item)
   			if itemIcon then
				btn:SetNormalTexture(itemIcon)
				if hasItemCache2[item] then
					updateDetailItem(btn)
				else
					btn:SetText("#"..item)
					btn.noItem = true
					LBICR:RegisterItemCache(item, setMenuItem)
				end
				btn:Show()
				if btn:IsMouseOver() and GetMouseFocus() == btn then
					btn:GetScript("OnEnter")(btn)
				end
			end
		else
			btn:Hide()
			btn.noItem = nil
		end
	end
	FauxScrollFrame_Update(IDR.itemListMenu.scroll, #detailItems2, #IDR.itemListMenu.items, 17)
	IDR:HideAllDropdown()
end