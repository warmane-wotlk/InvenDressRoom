local modName = ...
local addOnName = GetAddOnDependencies(modName)
local _G = _G
local IDR = _G[addOnName]

local ipairs =  _G.ipairs
local GetAddOnMetadata = _G.GetAddOnMetadata
local GetSpellInfo = _G.GetSpellInfo

local enchantList = {}

do
	local index, meta = 1, GetAddOnMetadata(modName, "X-DB-Enchants-1")
	while meta do
		for spell in meta:gmatch("(%d+)") do
			spell = tonumber(spell)
			if GetSpellInfo(spell) then
				tinsert(enchantList, spell)
			end
		end
		index = index + 1
		meta = GetAddOnMetadata(modName, "X-DB-Enchants-"..index)
	end
	sort(enchantList, function(a, b) return GetSpellInfo(a) < GetSpellInfo(b) end)
	tinsert(enchantList, 1, 0)

	local function createItemSlotSubButton(slot, text)
		local btn = CreateFrame("Button", IDR.itemSlots[slot]:GetName().."SubButton", IDR.itemSlots[slot], "UIPanelButtonTemplate2")
		btn:SetFrameLevel(IDR:GetFrameLevel() + 1)
		btn:SetPoint("TOP", IDR.itemSlots[slot], "BOTTOM", 0, -2)
		btn:SetWidth(54)
		btn:SetScale(0.82)
		btn:SetText(text)
		return btn
	end

	local function menuOnClick(self)
		IDR:ShowWeaponEnchantListMenu(self, self:GetParent().slot)
	end

	IDR.itemSlots.MainHandSlot.menuButton = createItemSlotSubButton("MainHandSlot", "마부")
	IDR.itemSlots.MainHandSlot.menuButton:SetScript("OnClick", menuOnClick)

	IDR.itemSlots.SecondaryHandSlot.menuButton = createItemSlotSubButton("SecondaryHandSlot", "마부")
	IDR.itemSlots.SecondaryHandSlot.menuButton:SetScript("OnClick", menuOnClick)

	IDR.itemSlots.RangedSlot.menuButton = createItemSlotSubButton("RangedSlot", "전환")
	IDR.itemSlots.RangedSlot.menuButton:SetScript("OnClick", function()
		if IDR.db.showWeapon == 1 then
			if IDR.db.currentItems.RangedSlot then
				IDR.db.showWeapon = 2
			else
				IDR.db.showWeapon = 3
			end
		elseif IDR.db.showWeapon == 2 then
			IDR.db.showWeapon = 3
		elseif IDR.db.showWeapon == 3 then
			if IDR.db.currentItems.MainHandSlot or IDR.db.currentItems.SecondaryHandSlot then
				IDR.db.showWeapon = 1
			elseif IDR.db.currentItems.RangedSlot then
				IDR.db.showWeapon = 2
			else
				return
			end
		end
		IDR:SetPlayerModel()
	end)

	local function enchantOnEnter(self)
		if self:GetID() > 0 then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 17)
			GameTooltip:SetSpellByID(self:GetID())
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
		IDR:ModelPreviewShow(self, IDR.weaponEnchantMenu.item, self.enchant)
	end

	local function enchantOnClick(self)
		if IDR.weaponEnchantMenu.value ~= self:GetID() then
			IDR.db.currentItems[self:GetParent().slot.."Enchant"] = self.enchant
			IDR:SetPlayerModel()
		end
		IDR.weaponEnchantMenu:Hide()
	end

	for i, btn in ipairs(IDR.weaponEnchantMenu.items) do
		btn:SetScript("OnEnter", enchantOnEnter)
		btn:SetScript("OnClick", enchantOnClick)
	end
end

function IDR:ShowWeaponEnchantListMenu(anchor, slot)
	if self.weaponEnchantMenu:IsShown() and self.weaponEnchantMenu.slot == slot then
		self.weaponEnchantMenu:Hide()
	else
		self.weaponEnchantMenu.slot = slot
		self.weaponEnchantMenu.item = self.db.currentItems[slot]
		self.weaponEnchantMenu.value = self.db.currentItems[slot.."Enchant"]
		self.weaponEnchantMenu:ClearAllPoints()
		self.weaponEnchantMenu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", -3, -3)
		self.weaponEnchantMenu:Show()
		self:UpdateWeaponEnchantListMenu()
	end
end

function IDR:UpdateWeaponEnchantListMenu()
	local offset, spell, spellName, spellIcon = FauxScrollFrame_GetOffset(IDR.weaponEnchantMenu.scroll)
	for i, btn in ipairs(IDR.weaponEnchantMenu.items) do
		spell = enchantList[offset + i]
		if spell then
			if spell == 0 then
				btn.enchant = nil
				spellIcon = IDR.itemSlots.MainHandSlot.backgroundTextureName
				spellName = "마법부여 없음"
				if not IDR.weaponEnchantMenu.value or IDR.weaponEnchantMenu.value == 0 then
					spellName = "|TInterface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons:0:0:0:0:64:16:48:64:0:16|t"..spellName
				end
			else
				btn.enchant = tonumber(GetAddOnMetadata(modName, "X-DB-Enchant-"..spell) or "")
				spellName, _, spellIcon = GetSpellInfo(spell)
				spellName = spellName:gsub("마법부여", ""):gsub("Enchant", ""):gsub("  ", " "):gsub(" %- ", ": ")
				if IDR.weaponEnchantMenu.value == btn.enchant then
					spellName = "|TInterface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons:0:0:0:0:64:16:48:64:0:16|t"..spellName
				end
			end
			btn:SetID(spell)
			btn:SetNormalTexture(spellIcon)
			btn:SetText(spellName)
			btn:Show()
			if btn:IsMouseOver() and GetMouseFocus() == btn then
				btn:GetScript("OnEnter")(btn)
			end
		else
			btn.enchant = nil
			btn:Hide()
		end
	end
	FauxScrollFrame_Update(IDR.weaponEnchantMenu.scroll, #enchantList, #IDR.weaponEnchantMenu.items, 17)
	IDR:HideAllDropdown()
end