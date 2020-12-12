local modName = ...
local addOnName = GetAddOnDependencies(modName)
local _G = _G
local IDR = _G[addOnName]
local pairs = _G.pairs
local ipairs = _G.ipairs
local wipe = _G.wipe
local tinsert = _G.table.insert
local ceil = _G.math.ceil
local GetAddOnMetadata = _G.GetAddOnMetadata

ButtonFrameTemplate_HideButtonBar(IDR)
IDR:SetPoint("CENTER", 0, 0)
IDR:SetSize(852, 433)
IDR:SetScale(IDR.db.scale)
IDR:EnableMouse(true)
IDR:SetMovable(true)
IDR:SetClampedToScreen(true)
IDR:RegisterForDrag("LeftButton", "RightButton")
IDR:SetScript("OnDragStart", IDR.StartMoving)
IDR:SetScript("OnDragStop", IDR.StopMovingOrSizing)
IDR.portrait:SetPoint("TOPLEFT", -5, 8)
SetPortraitToTexture(IDR.portrait, IDR.icon)
IDR.TitleText:SetFormattedText("Inven Dress Room v%s", GetAddOnMetadata(addOnName, "Version"))

local function setCustomRace(self)
	self:SetUnit("player")
end

local function enableCustomRace(self)
	setCustomRace(self)
	if not self.SetCustomRace then
		self.SetCustomRace = setCustomRace
	end	
end

local function loadingAnimationOnShow(self)
	self.animation:Play()
end

local function loadingAnimationOnHide(self)
	self.animation:Pause()
end

local function createLoadingAnimation(parent)
	local loading = CreateFrame("Frame", nil, parent)
	loading:SetFrameLevel(parent:GetFrameLevel() + 1)
	loading:Hide()
	loading:SetSize(120, 120)
	local region = loading:CreateTexture(nil, "BACKGROUND")
	region:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Common\\StreamBackground")
	region:SetVertexColor(0, 1, 0)
	region:SetAllPoints()
	region = loading:CreateTexture(nil, "ARTWORK")
	region:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Common\\StreamFrame")
	region:SetAllPoints()
	parent = CreateFrame("Frame", nil, loading)
	parent:SetAllPoints()
	parent:SetAlpha(0.5)
	parent:SetFrameLevel(loading:GetFrameLevel())
	region = parent:CreateTexture(nil, "BORDER")
	region:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Common\\StreamCircle")
	region:SetVertexColor(0, 1, 0)
	region:SetAllPoints()
	region = parent:CreateTexture(nil, "OVERLAY", 1)
	region:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Common\\StreamSpark")
	region:SetAllPoints()
	parent = parent:CreateAnimationGroup()
	parent:SetLooping("REPEAT")
	region = parent:CreateAnimation("Rotation")
	region:SetDuration(4)
	region:SetDegrees(-360)
	region = loading:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	region:SetPoint("TOP", loading, "BOTTOM", 2, 23)
	region:SetText("Loading...")
	loading.animation = parent
	loading:SetScript("OnShow", loadingAnimationOnShow)
	loading:SetScript("OnHide", loadingAnimationOnHide)
	return loading
end

local pi2 = 2 * PI

IDR.modelTooltip = CreateFrame("Frame", addOnName.."ModelTooltip", UIParent)
IDR.modelTooltip:Hide()
IDR.modelTooltip:SetFrameStrata("TOOLTIP")
IDR.modelTooltip:SetToplevel(true)
IDR.modelTooltip:SetSize(170, 180)
IDR.modelTooltip:SetClampedToScreen(true)
IDR.modelTooltip:SetBackdrop({
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
IDR.modelTooltip:SetBackdropBorderColor(1, 1, 1)
IDR.modelTooltip.bg = IDR.modelTooltip:CreateTexture(nil, "BACKGROUND")
IDR.modelTooltip.bg:SetTexture(0, 0, 0, 0.9)
IDR.modelTooltip.bg:SetPoint("TOPLEFT", 4, -4)
IDR.modelTooltip.bg:SetPoint("BOTTOMRIGHT", -4, 4)
IDR.modelTooltip.model = CreateFrame("DressUpModel", nil, IDR.modelTooltip)
enableCustomRace(IDR.modelTooltip.model)
IDR.modelTooltip.model:SetFrameLevel(IDR.modelTooltip:GetFrameLevel() + 1)
IDR.modelTooltip.model:SetPoint("TOPLEFT", 5, -5)
IDR.modelTooltip.model:SetPoint("BOTTOMRIGHT", -5, 5)
IDR.modelTooltip.model.rotation = 0
IDR.modelTooltip.model.onUpdate = function(self, timer)
	self.rotation = self.rotation + timer * pi2 * 0.25
	if self.rotation > pi2 then
		self.rotation = self.rotation - pi2
	end
	self:SetRotation(self.rotation, false)
end

IDR.modelTooltip.loading = createLoadingAnimation(IDR.modelTooltip)
IDR.modelTooltip.loading:SetPoint("CENTER", 0, 10)

local frameLevel = IDR:GetFrameLevel()

local function onReceiveDragItem(self)
	local item, link, equip, stype = IDR:GetCursorItem()
	if item then
		ClearCursor()
		self.noClick = self:GetID() > 0 and true or nil
		if equip == "WEAPON" then
			if self.slot ~= "MainHandSlot" and self.slot ~= "SecondaryHandSlot" then
				if IDR.itemSlots.MainHandSlot.item and not IDR.itemSlots.SecondaryHandSlot.item then
					self = IDR.itemSlots.SecondaryHandSlot
				elseif IDR.itemSlots.SecondaryHandSlot.item and (IDR.itemSlots.SecondaryHandSlot.equipLoc == "HOLDABLE" or IDR.itemSlots.SecondaryHandSlot.equipLoc == "SHIELD") then
					self = IDR.itemSlots.MainHandSlot
				elseif IDR.itemSlots.MainHandSlot.item == itemID then
					self = IDR.itemSlots.SecondaryHandSlot
				else
					self = IDR.itemSlots.MainHandSlot
				end
			end
		elseif equip == "2HWEAPON" then
			self = IDR.itemSlots.MainHandSlot
		elseif not(self:GetID() > 0 and IDR.equipSlots[equip] == self.slot) then
			self = IDR.itemSlots[IDR.equipSlots[equip]]
		end
		if link and equip:find("WEAPON") then
			local enchant = tonumber(link:match("item:%d+:(%d+)") or "")
			enchant = enchant and enchant > 0 and enchant or IDR.db.currentItems[self.slot.."Enchant"]
			if IDR.db.currentItems[self.slot] ~= item or IDR.db.currentItems[self.slot.."Enchant"] ~= enchant then
				IDR.db.currentItems[self.slot] = item
				IDR.db.currentItems[self.slot.."Enchant"] = enchant
				IDR:SetPlayerModel()
			end
		elseif IDR.db.currentItems[self.slot] ~= item then
			IDR.db.currentItems[self.slot] = item
			IDR:SetPlayerModel()
		end
	else
		self.noClick = nil
	end
end

local createDressUpModel
if Model_StartPanning then
	createDressUpModel = function(model, parent)
		model = CreateFrame("DressUpModel", model, parent, "ModelWithControlsTemplate")
		enableCustomRace(model)
		return model
	end
else
	createDressUpModel = function(model, parent)
		model = CreateFrame("DressUpModel", model, parent)
		Model_OnLoad(model)
		model:SetScript("OnEvent", Model_OnEvent)
		model:SetScript("OnUpdate", Model_OnUpdate)
		model:SetScript("OnMouseUp", Model_OnMouseUp)
		model:SetScript("OnMouseDown", Model_OnMouseDown)
		model:SetScript("OnMouseWheel", Model_OnMouseWheel)
		enableCustomRace(model)
		return model
	end
end

local modelFrame = createDressUpModel(addOnName.."ModelFrame", IDR)
IDR.modelFrame = modelFrame
modelFrame:SetID(0)
modelFrame:SetFrameLevel(frameLevel + 1)
modelFrame:SetSize(231, 320)
modelFrame:SetPoint("TOPLEFT", 52, -66)
modelFrame:SetScript("OnReceiveDrag", onReceiveDragItem)
if Model_StartPanning then
	modelFrame.onMouseUpFunc = function(self, button)
		if CursorHasItem() then
			onReceiveDragItem(self)
		end
		Model_OnMouseUp(self, button)
	end
else
	Model_OnLoad(modelFrame)
	modelFrame:SetScript("OnMouseUp", function(self, button)
		if CursorHasItem() then
			if self:GetScript("OnUpdate") then
				self:SetScript("OnUpdate", nil)
			end
			onReceiveDragItem(self)
		else
			Model_OnMouseUp(self, button)
		end
	end)
end

modelFrame.BackgroundTopLeft = modelFrame:CreateTexture(nil, "BACKGROUND")
modelFrame.BackgroundTopLeft:SetPoint("TOPLEFT", 0, 0)
modelFrame.BackgroundTopLeft:SetSize(212, 245)
modelFrame.BackgroundTopLeft:SetTexCoord(0.171875, 1, 0.0392156862745098, 1)
modelFrame.BackgroundTopRight = modelFrame:CreateTexture(nil, "BACKGROUND")
modelFrame.BackgroundTopRight:SetPoint("TOPLEFT", modelFrame.BackgroundTopLeft, "TOPRIGHT", 0, 0)
modelFrame.BackgroundTopRight:SetSize(19, 245)
modelFrame.BackgroundTopRight:SetTexCoord(0, 0.296875, 0.0392156862745098, 1)
modelFrame.BackgroundBotLeft = modelFrame:CreateTexture(nil, "BACKGROUND")
modelFrame.BackgroundBotLeft:SetPoint("TOPLEFT", modelFrame.BackgroundTopLeft, "BOTTOMLEFT", 0, 0)
modelFrame.BackgroundBotLeft:SetSize(212, 128)
modelFrame.BackgroundBotLeft:SetTexCoord(0.171875, 1, 0, 1)
modelFrame.BackgroundBotRight = modelFrame:CreateTexture(nil, "BACKGROUND")
modelFrame.BackgroundBotRight:SetPoint("TOPLEFT", modelFrame.BackgroundTopLeft, "BOTTOMRIGHT", 0, 0)
modelFrame.BackgroundBotRight:SetSize(19, 128)
modelFrame.BackgroundBotRight:SetTexCoord(0, 0.296875, 0, 1)
modelFrame.BackgroundOverlay = modelFrame:CreateTexture(nil, "BORDER")
modelFrame.BackgroundOverlay:SetPoint("TOPLEFT", modelFrame.BackgroundTopLeft, 0, 0)
modelFrame.BackgroundOverlay:SetPoint("BOTTOMRIGHT", modelFrame.BackgroundBotRight, 0, 52)
modelFrame.BackgroundOverlay:SetTexture(0, 0, 0)
local borderTopLeft = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Corner-UpperLeft")
borderTopLeft:ClearAllPoints()
borderTopLeft:SetPoint("TOPLEFT", modelFrame.BackgroundOverlay, -2, 2)
local borderTopRight = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Corner-UpperRight")
borderTopRight:ClearAllPoints()
borderTopRight:SetPoint("TOPRIGHT", modelFrame.BackgroundOverlay, 2, 2)
local borderBotLeft = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Corner-LowerLeft")
borderBotLeft:ClearAllPoints()
borderBotLeft:SetPoint("BOTTOMLEFT", modelFrame.BackgroundOverlay, -2, -2)
local borderBotRight = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Corner-LowerRight")
borderBotRight:ClearAllPoints()
borderBotRight:SetPoint("BOTTOMRIGHT", modelFrame.BackgroundOverlay, 2, -2)
local borderMiddle = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Inner-Left")
borderMiddle:ClearAllPoints()
borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "BOTTOMLEFT", -1, 0)
borderMiddle:SetPoint("BOTTOMLEFT", borderBotLeft, "TOPLEFT", -1, 0)
borderMiddle = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Inner-Right")
borderMiddle:ClearAllPoints()
borderMiddle:SetPoint("TOPRIGHT", borderTopRight, "BOTTOMRIGHT", 1, 0)
borderMiddle:SetPoint("BOTTOMRIGHT", borderBotRight, "TOPRIGHT", 1, 0)
borderMiddle = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Inner-Top")
borderMiddle:ClearAllPoints()
borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "TOPRIGHT", 0, 1)
borderMiddle:SetPoint("TOPRIGHT", borderTopRight, "TOPLEFT", 0, 1)
borderMiddle = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Inner-Bottom")
borderMiddle:ClearAllPoints()
borderMiddle:SetPoint("BOTTOMLEFT", borderBotLeft, "BOTTOMRIGHT", 0, -1)
borderMiddle:SetPoint("BOTTOMRIGHT", borderBotRight, "BOTTOMLEFT", 0, -1)
borderMiddle = modelFrame:CreateTexture(nil, "OVERLAY", "Char-Inner-Bottom")
borderMiddle:ClearAllPoints()
borderMiddle:SetPoint("BOTTOMLEFT", borderBotLeft, "BOTTOMLEFT", -4, -4)
borderMiddle:SetPoint("BOTTOMRIGHT", borderBotRight, "BOTTOMRIGHT", 4, -4)

IDR.itemSlots = {}
IDR.equipSlots = {}
IDR.itemSlotPattern = "^"..addOnName.."Item[BCFHLMRSW][Hacdeghiklnorstuy]+Slot$"

do
	local function itemSlotOnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.itemLink then
			GameTooltip:SetHyperlink(self.itemLink)
		elseif self.item then
			GameTooltip:SetHyperlink("item:"..self.item)
		elseif self.tooltipText then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltipText)
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
	end

	local function createItemSlot(slot, bg, visible)
		IDR.itemSlots[slot] = CreateFrame("Button", addOnName.."Item"..slot, IDR, "ItemButtonTemplate")
		IDR.itemSlots[slot]:SetFrameLevel(frameLevel + 2)
		if visible then
			IDR.itemSlots[slot].slot = slot
			IDR.itemSlots[slot]:Enable()
			if type(visible) == "string" then
				IDR.itemSlots[slot].tooltipText = _G["INVTYPE_"..visible]
				IDR.equipSlots[visible] = slot
				IDR.itemSlots[slot].mainCategory = visible
			end
			visible, IDR.itemSlots[slot].backgroundTextureName = GetInventorySlotInfo(slot)
			IDR.itemSlots[slot]:SetID(visible)
			IDR.itemSlots[slot].icon = _G[IDR.itemSlots[slot]:GetName().."IconTexture"]
			IDR.itemSlots[slot].icon:SetTexture(IDR.itemSlots[slot].backgroundTextureName)
			IDR.itemSlots[slot]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			IDR.itemSlots[slot]:SetScript("OnEnter", itemSlotOnEnter)
			IDR.itemSlots[slot]:SetScript("OnLeave", GameTooltip_Hide)
			IDR.itemSlots[slot]:SetScript("OnReceiveDrag", onReceiveDragItem)
			IDR.itemSlots[slot]:SetScript("PreClick", onReceiveDragItem)
		else
			IDR.itemSlots[slot]:Disable()
			IDR.itemSlots[slot]:SetID(0)
			_G[IDR.itemSlots[slot]:GetName().."IconTexture"]:SetTexture((select(2, GetInventorySlotInfo(slot))))
			visible = CreateFrame("Button", nil, IDR.itemSlots[slot])
			visible:SetID(0)
			visible:SetFrameLevel(frameLevel + 3)
			visible:SetAllPoints()
			visible:SetNormalTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\PaperDollInfoFrame\\UI-GearManager-LeaveItem-Transparent")
			visible:SetAlpha(0.75)
			visible:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			visible:SetScript("OnReceiveDrag", onReceiveDragItem)
			visible:SetScript("OnClick", onReceiveDragItem)
		end
		visible = IDR.itemSlots[slot]:CreateTexture(nil, "BACKGROUND", (bg == "Char-Slot-Bottom-Left" or bg == "Char-Slot-Bottom-Right") and "Char-BottomSlot" or bg, -1)
		visible:ClearAllPoints()
		if bg == "Char-LeftSlot" then
			visible:SetPoint("TOPLEFT", -4, 0)
		elseif bg == "Char-RightSlot" then
			visible:SetPoint("TOPRIGHT", 4, 0)
		elseif bg == "Char-BottomSlot" then
			visible:SetPoint("TOPLEFT", -4, 8)
		elseif bg == "Char-Slot-Bottom-Left" then
			visible:SetPoint("TOPLEFT", -4, 8)
			bg = IDR.itemSlots[slot]:CreateTexture(nil, "BACKGROUND", bg)
			bg:ClearAllPoints()
			bg:SetPoint("TOPRIGHT", visible, "TOPLEFT", 0, 0)
		elseif bg == "Char-Slot-Bottom-Right" then
			visible:SetPoint("TOPLEFT", -4, 8)
			bg = IDR.itemSlots[slot]:CreateTexture(nil, "BACKGROUND", bg)
			bg:ClearAllPoints()
			bg:SetPoint("TOPLEFT", visible, "TOPRIGHT", 0, 0)
		end
		return IDR.itemSlots[slot]
	end

	createItemSlot("HeadSlot", "Char-LeftSlot", "HEAD"):SetPoint("TOPRIGHT", modelFrame.BackgroundOverlay, "TOPLEFT", -7, 3)
	createItemSlot("NeckSlot", "Char-LeftSlot", nil):SetPoint("TOP", IDR.itemSlots.HeadSlot, "BOTTOM", 0, -4)
	createItemSlot("ShoulderSlot", "Char-LeftSlot", "SHOULDER"):SetPoint("TOP", IDR.itemSlots.NeckSlot, "BOTTOM", 0, -4)
	createItemSlot("BackSlot", "Char-LeftSlot", "CLOAK"):SetPoint("TOP", IDR.itemSlots.ShoulderSlot, "BOTTOM", 0, -4)
	createItemSlot("ChestSlot", "Char-LeftSlot", "CHEST"):SetPoint("TOP", IDR.itemSlots.BackSlot, "BOTTOM", 0, -4)
	createItemSlot("ShirtSlot", "Char-LeftSlot", nil):SetPoint("TOP", IDR.itemSlots.ChestSlot, "BOTTOM", 0, -4)
	createItemSlot("TabardSlot", "Char-LeftSlot", nil):SetPoint("TOP", IDR.itemSlots.ShirtSlot, "BOTTOM", 0, -4)
	createItemSlot("WristSlot", "Char-LeftSlot", "WRIST"):SetPoint("TOP", IDR.itemSlots.TabardSlot, "BOTTOM", 0, -4)

	createItemSlot("HandsSlot", "Char-RightSlot", "HAND"):SetPoint("TOPLEFT", modelFrame.BackgroundOverlay, "TOPRIGHT", 8, 3)
	createItemSlot("WaistSlot", "Char-RightSlot", "WAIST"):SetPoint("TOP", IDR.itemSlots.HandsSlot, "BOTTOM", 0, -4)
	createItemSlot("LegsSlot", "Char-RightSlot", "LEGS"):SetPoint("TOP", IDR.itemSlots.WaistSlot, "BOTTOM", 0, -4)
	createItemSlot("FeetSlot", "Char-RightSlot", "FEET"):SetPoint("TOP", IDR.itemSlots.LegsSlot, "BOTTOM", 0, -4)
	createItemSlot("Finger0Slot", "Char-RightSlot", nil):SetPoint("TOP", IDR.itemSlots.FeetSlot, "BOTTOM", 0, -4)
	createItemSlot("Finger1Slot", "Char-RightSlot", nil):SetPoint("TOP", IDR.itemSlots.Finger0Slot, "BOTTOM", 0, -4)
	createItemSlot("Trinket0Slot", "Char-RightSlot", nil):SetPoint("TOP", IDR.itemSlots.Finger1Slot, "BOTTOM", 0, -4)
	createItemSlot("Trinket1Slot", "Char-RightSlot", nil):SetPoint("TOP", IDR.itemSlots.Trinket0Slot, "BOTTOM", 0, -4)

	createItemSlot("SecondaryHandSlot", "Char-BottomSlot", "WEAPONOFFHAND"):SetPoint("CENTER", modelFrame.BackgroundOverlay, "BOTTOM", 0, -2)
	createItemSlot("MainHandSlot", "Char-Slot-Bottom-Left", "WEAPONMAINHAND"):SetPoint("RIGHT", IDR.itemSlots.SecondaryHandSlot, "LEFT", -5, 0)
	createItemSlot("RangedSlot", "Char-Slot-Bottom-Right", "RANGED"):SetPoint("LEFT", IDR.itemSlots.SecondaryHandSlot, "RIGHT", 5, 0)

	IDR.equipSlots.ROBE = "ChestSlot"
	IDR.equipSlots["2HWEAPON"] = "MainHandSlot"
	IDR.equipSlots.WEAPON = "MainHandSlot"
	IDR.equipSlots.SHIELD = "SecondaryHandSlot"
	IDR.equipSlots.HOLDABLE = "SecondaryHandSlot"
	IDR.equipSlots.RANGEDRIGHT = "RangedSlot"
	IDR.equipSlots.THROWN = "RangedSlot"

	for slot, btn in pairs(IDR.itemSlots) do
		if not btn.icon then
			IDR.itemSlots[slot] = nil
		end
	end
end

local function createDropdown(dropdown, parent, width, level)
	dropdown = CreateFrame("Frame", addOnName..dropdown, parent, "UIDropDownMenuTemplate")
	level = level or (parent:GetFrameLevel() + 1)
	dropdown:SetFrameLevel(level)
	UIDropDownMenu_SetWidth(dropdown, width)
	UIDropDownMenu_JustifyText(dropdown, "LEFT")
	dropdown.button = _G[dropdown:GetName().."Button"]
	dropdown.button:SetFrameLevel(level + 1)
	_G[dropdown:GetName().."Text"]:SetPoint("RIGHT", dropdown.button, "LEFT", 0, 0)
	return dropdown
end

IDR.profileSelector = createDropdown("ProfileSelector", IDR, 110, frameLevel + 1)
IDR.profileSelector:SetPoint("TOPLEFT", 40, -29)

local dummyFontString = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dummyFontString:SetPoint("CENTER", 0, 0)

local function createMainButton(btn, text, ...)
	btn = CreateFrame("Button", addOnName..btn, IDR, "UIPanelButtonTemplate2")
	btn:SetFrameLevel(frameLevel + 1)
	btn:SetText(text)
	btn:SetPoint(...)
	dummyFontString:Show()
	dummyFontString:SetText(text)
	btn:SetSize(dummyFontString:GetWidth() + 16, 26)
	dummyFontString:Hide()
	return btn
end

IDR.profileSave = createMainButton("ProfileSaveButton", SAVE, "LEFT", IDR.profileSelector.button, "RIGHT", 0, -1)
IDR.profileSaveAs = createMainButton("ProfileSaveAsButton", "다른 이름으로 저장", "LEFT", IDR.profileSave, "RIGHT", -2, 0)
IDR.undressAllItems = createMainButton("UndressAllItemsButton", NEWBIE_TOOLTIP_STOPWATCH_RESETBUTTON, "LEFT", IDR.profileSaveAs, "RIGHT", -2, 0)

IDR.profileDelete = createDropdown("ProfileDelete", IDR, 110, frameLevel + 1)
IDR.profileDelete:SetPoint("LEFT", IDR.undressAllItems, "RIGHT", -18, -2)
UIDropDownMenu_SetText(IDR.profileDelete, "프로필 삭제하기")

IDR.raceList = createDropdown("RaceSelector", IDR, 110, frameLevel + 1)
IDR.raceList:SetPoint("LEFT", IDR.profileDelete, "RIGHT", -33, 0)
if modelFrame.SetCustomRace == setCustomRace then
	UIDropDownMenu_DisableDropDown(IDR.raceList)
	IDR.raceList.button:EnableMouse(nil)
	IDR.raceList.safe = IDR.raceList.safe or CreateFrame("Frame", nil, IDR.raceList)
	IDR.raceList.safe:SetFrameLevel(IDR.raceList.button:GetFrameLevel())
	IDR.raceList.safe:EnableMouse(true)
	IDR.raceList.safe:SetPoint("TOPLEFT", 18, -1)
	IDR.raceList.safe:SetPoint("BOTTOMRIGHT", -16, 5)
	IDR.raceList.safe:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("이 기능은 4.3 패치 이후에 작동합니다.", 1, 0.2, 0.2, 1)
		GameTooltip:Show()
	end)
	IDR.raceList.safe:SetScript("OnLeave", GameTooltip_Hide)
end

borderTopLeft = IDR:CreateTexture(nil, "BORDER")
borderTopLeft:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderTopLeft:SetPoint("TOP", 0, -57)
borderTopLeft:SetPoint("LEFT", IDR.itemSlots.HandsSlot, "RIGHT", 0, 0)
borderTopLeft:SetSize(16, 75)
borderTopLeft:SetTexCoord(0, 0.25, 0, 0.29296875)
borderBotLeft = IDR:CreateTexture(nil, "BORDER")
borderBotLeft:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderBotLeft:SetPoint("BOTTOM", 0, 2)
borderBotLeft:SetPoint("LEFT", IDR.itemSlots.HandsSlot, "RIGHT", 0, 0)
borderBotLeft:SetSize(16, 75)
borderBotLeft:SetTexCoord(0.25, 0.5, 0, 0.29296875)
borderMiddle = IDR:CreateTexture(nil, "BORDER")
borderMiddle:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "BOTTOMLEFT", 0, 0)
borderMiddle:SetPoint("BOTTOMRIGHT", borderBotLeft, "TOPRIGHT", 0, 0)
borderMiddle:SetWidth(16)
borderMiddle:SetTexCoord(0, 0.25, 0.29296875, 1)

local categoryScroll = CreateFrame("ScrollFrame", addOnName.."CategoryScrollFrame", IDR, "ListScrollFrameTemplate")
categoryScroll:SetFrameLevel(frameLevel + 3)
categoryScroll:SetPoint("TOPLEFT", borderTopLeft, "TOPRIGHT", -3, -8)
categoryScroll:SetPoint("BOTTOMLEFT", borderBotLeft, "BOTTOMRIGHT", -3, 4)
categoryScroll:SetWidth(143)
categoryScroll:SetHitRectInsets(0, -28, 0, 0)
_G[categoryScroll:GetName().."ScrollChildFrame"]:SetSize(1, 1)

borderTopLeft = IDR:CreateTexture(nil, "BORDER")
borderTopLeft:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderTopLeft:SetPoint("TOP", 0, -57)
borderTopLeft:SetPoint("LEFT", categoryScroll, "RIGHT", 19, 0)
borderTopLeft:SetSize(16, 75)
borderTopLeft:SetTexCoord(0, 0.25, 0, 0.29296875)
borderBotLeft = IDR:CreateTexture(nil, "BORDER")
borderBotLeft:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderBotLeft:SetPoint("BOTTOM", 0, 2)
borderBotLeft:SetPoint("LEFT", categoryScroll, "RIGHT", 19, 0)
borderBotLeft:SetSize(16, 75)
borderBotLeft:SetTexCoord(0.25, 0.5, 0, 0.29296875)
borderMiddle = IDR:CreateTexture(nil, "BORDER")
borderMiddle:SetTexture("Interface\\AddOns\\InvenCraftInfo2_UI\\Texture\\VerticalLine")
borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "BOTTOMLEFT", 0, 0)
borderMiddle:SetPoint("BOTTOMRIGHT", borderBotLeft, "TOPRIGHT", 0, 0)
borderMiddle:SetTexCoord(0, 0.25, 0.29296875, 1)

local function fixScrollBarBorder(scroll)
	scroll:DisableDrawLayer("BACKGROUND")
	scroll = _G[scroll:GetName().."ScrollBar"]
	if not scroll then return end
	borderTopLeft = scroll:CreateTexture(nil, "BACKGROUND")
	borderTopLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar")
	borderTopLeft:SetTexCoord(0, 0.40625, 0, 0.25)
	borderTopLeft:SetPoint("TOPRIGHT", _G[scroll:GetName().."ScrollUpButton"], "TOPRIGHT", 0, 5)
	borderTopLeft:SetSize(26, 32)
	borderBotLeft = scroll:CreateTexture(nil, "BACKGROUND")
	borderBotLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar")
	borderBotLeft:SetTexCoord(0.53125, 0.9375, 0.75, 1)
	borderBotLeft:SetPoint("BOTTOMRIGHT", _G[scroll:GetName().."ScrollDownButton"], "BOTTOMRIGHT", 0, -2)
	borderBotLeft:SetSize(26, 32)
	borderMiddle = scroll:CreateTexture(nil, "BACKGROUND")
	borderMiddle:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar")
	borderMiddle:SetTexCoord(0, 0.40625, 0.25, 0.9375)
	borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "BOTTOMLEFT", 0, 0)
	borderMiddle:SetPoint("BOTTOMRIGHT", borderBotLeft, "TOPRIGHT", 0, 0)
end

fixScrollBarBorder(categoryScroll)

local mainCategory = {
	"2HWEAPON",
	"WEAPON",
	"WEAPONMAINHAND",
	"WEAPONOFFHAND",
	"HOLDABLE",
	"SHIELD",
	"RANGED",
	"HEAD",
	"SHOULDER",
	"CLOAK",
	"CHEST",
	"WRIST",
	"HAND",
	"WAIST",
	"LEGS",
	"FEET",
}
local subCategory = {
	["2HWEAPON"] = { "SWORD_2H", "AXES_2H", "MACES_2H", "POLEARMS", "STAVES" },
	WEAPON = { "SWORD_1H", "AXES_1H", "MACES_1H", "DAGGERS", "FIST" },
	RANGED = { "BOWS", "CROSSBOWS", "GUNS", "THROWN", "WANDS" },
	HEAD = { "CLOTH", "LEATHER", "MAIL", "PLATE" },
}
subCategory.WEAPONMAINHAND = subCategory.WEAPON
subCategory.WEAPONOFFHAND = subCategory.WEAPON
subCategory.SHOULDER = subCategory.HEAD
subCategory.CHEST = subCategory.HEAD
subCategory.WRIST = subCategory.HEAD
subCategory.HAND = subCategory.HEAD
subCategory.WAIST = subCategory.HEAD
subCategory.LEGS = subCategory.HEAD
subCategory.FEET = subCategory.HEAD

IDR.mainCategory, IDR.subCategory = mainCategory, subCategory

local categoryList, categoryExpand, categoryLast, categoryButtons, categoryListUpdate, detailUpdate = {}, {}, {}, {}
local selectedCategoryModels, selectedCategoryPages = {}, {}
local selectedCategory, selectedModelIndex
local subClassLocale = LibStub("LibBlueItem-1.0").itemSubClassLocale
local newInvType = {
	SHIELD = subClassLocale.SHIELD,
	WEAPONOFFHAND = SECONDARY.." "..ENCHSLOT_WEAPON,
}
local classes = { "WARRIOR", "ROGUE", "PRIEST", "MAGE", "WARLOCK", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "DEATHKNIGHT" }
local classesName = {}
FillLocalizedClassList(classesName)
for class, name in pairs(classesName) do
	if RAID_CLASS_COLORS[class] then
		classesName[class] = ("|cff%02x%02x%02x%s|r"):format(RAID_CLASS_COLORS[class].r * 255, RAID_CLASS_COLORS[class].g * 255, RAID_CLASS_COLORS[class].b * 255, name)
	else
		classesName[class] = "|cff585858"..name.."|r"
	end
end

local function getCategoryInfo(cate)
	if cate:find("^Pv[EP]$") then
		return cate.." 세트 아이템", 1
	elseif cate:find("^Pv[EP]_[^_]+$") then
		cate = cate:match("^Pv[EP]_([^_]+)$")
		return classesName[cate], 2
	elseif cate:find("^Pv[EP]_[^_]+_%d+$") then
		return GetAddOnMetadata(modName, "X-DB-"..cate:match("^(Pv[EP])_").."-"..cate:match("_(%d+)$")), 3
	elseif cate:find("_") then
		return subClassLocale[cate:match("^[^_]+_(.+)$")], 2
	else
		return newInvType[cate] or _G["INVTYPE_"..cate], 1
	end
end

function IDR:GetCategoryName(cate)
	return (getCategoryInfo(cate))
end

local function addSetItemCategory(prefix)
	local num = tonumber(GetAddOnMetadata(modName, "X-DB-"..prefix) or 0)
	if num > 0 then
		tinsert(categoryList, prefix)
		if categoryExpand[prefix] then
			for _, class in ipairs(classes) do
				class = prefix.."_"..class
				tinsert(categoryList, class)
				if categoryExpand[class] then
					for i = 1, num do
						if GetAddOnMetadata(modName, "X-DB-"..class.."_"..i) then
							tinsert(categoryList, class.."_"..i)
							categoryLast[class.."_"..i] = true
						end
					end
				end
			end
		end
	end
end

local function createCategoryList()
	wipe(categoryList)
	wipe(categoryLast)
	addSetItemCategory("PvE")
	addSetItemCategory("PvP")
	for _, loc in ipairs(mainCategory) do
		tinsert(categoryList, loc)
		if subCategory[loc] then
			if categoryExpand[loc] then
				for _, sub in ipairs(subCategory[loc]) do
					sub = loc.."_"..sub
					tinsert(categoryList, sub)
					categoryLast[sub] = true
				end
			end
		else
			categoryLast[loc] = true
		end
	end
	categoryListUpdate()
end

local function categoryButtonOnClick(self)
	IDR:HideAllDropdown()
	if categoryLast[categoryList[self:GetID()]] then
		if selectedCategory ~= categoryList[self:GetID()] then
			selectedCategory = categoryList[self:GetID()]
			categoryListUpdate()
			detailUpdate()
		end
	elseif categoryExpand[categoryList[self:GetID()]] then
		categoryExpand[categoryList[self:GetID()]] = nil
		createCategoryList()
	else
		categoryExpand[categoryList[self:GetID()]] = true
		createCategoryList()
	end
end

for i = 1, 18 do
	categoryButtons[i] = CreateFrame("Button", addOnName.."CategoryButton"..i, IDR)
	categoryButtons[i]:SetFrameLevel(frameLevel + 4)
	categoryButtons[i]:SetHeight(20)
	categoryButtons[i].left = categoryButtons[i]:CreateTexture(nil, "ARTWORK")
	categoryButtons[i].left:SetSize(6, 20)
	categoryButtons[i].left:SetPoint("LEFT", 0, 0)
	categoryButtons[i].left:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBg")
	categoryButtons[i].left:SetTexCoord(0, 0.0234375, 0, 0.625)
	categoryButtons[i].right = categoryButtons[i]:CreateTexture(nil, "ARTWORK")
	categoryButtons[i].right:SetSize(6, 20)
	categoryButtons[i].right:SetPoint("RIGHT", 0, 0)
	categoryButtons[i].right:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBg")
	categoryButtons[i].right:SetTexCoord(0.5078125, 0.53125, 0, 0.625)
	categoryButtons[i]:SetNormalTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBg")
	categoryButtons[i].middle = categoryButtons[i]:GetNormalTexture()
	categoryButtons[i].middle:SetTexCoord(0.0234375, 0.5078125, 0, 0.625)
	categoryButtons[i].middle:ClearAllPoints()
	categoryButtons[i].middle:SetPoint("TOPLEFT", categoryButtons[i].left, "TOPRIGHT", 0, 0)
	categoryButtons[i].middle:SetPoint("BOTTOMRIGHT", categoryButtons[i].right, "BOTTOMLEFT", 0, 0)
	categoryButtons[i]:SetNormalFontObject("GameFontNormalSmallLeft")
	categoryButtons[i]:SetHighlightFontObject("GameFontHighlightSmallLeft")
	categoryButtons[i]:SetText(" ")
	categoryButtons[i].text = categoryButtons[i]:GetFontString()
	categoryButtons[i].text:ClearAllPoints()
	categoryButtons[i].text:SetPoint("TOPLEFT", categoryButtons[i].middle, "TOPLEFT", -1, 0)
	categoryButtons[i].text:SetPoint("BOTTOMRIGHT", categoryButtons[i].middle, "BOTTOMRIGHT", 1, 0)
	categoryButtons[i].line = categoryButtons[i]:CreateTexture(nil, "BACKGROUND")
	categoryButtons[i].line:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterLines")
	categoryButtons[i].line:SetSize(7, 20)
	categoryButtons[i].line:SetPoint("RIGHT", categoryButtons[i].text, "LEFT", -1, 0)
	categoryButtons[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
	categoryButtons[i]:GetHighlightTexture():SetVertexColor(0.196, 0.388, 0.8)
	categoryButtons[i]:GetHighlightTexture():ClearAllPoints()
	categoryButtons[i]:GetHighlightTexture():SetPoint("TOPLEFT", categoryButtons[i].text, "TOPLEFT", -7, -1)
	categoryButtons[i]:GetHighlightTexture():SetPoint("BOTTOMRIGHT", categoryButtons[i].text, "BOTTOMRIGHT", 7, 1)
	categoryButtons[i]:SetScript("OnClick", categoryButtonOnClick)
	if i == 1 then
		categoryButtons[i]:SetPoint("TOPLEFT", categoryScroll, "TOPLEFT", 0, 0)
		categoryButtons[i]:SetPoint("TOPRIGHT", categoryScroll, "TOPRIGHT", 21, 0)
	else
		categoryButtons[i]:SetPoint("TOPLEFT", categoryButtons[i - 1], "BOTTOMLEFT", 0, 0)
		categoryButtons[i]:SetPoint("TOPRIGHT", categoryButtons[i - 1], "BOTTOMRIGHT", 0, 0)
	end
end

categoryScroll:SetScript("OnShow", function(self)
	categoryButtons[1]:SetPoint("TOPRIGHT", self, "TOPRIGHT", -2, 0)
end)

categoryScroll:SetScript("OnHide", function(self)
	categoryButtons[1]:SetPoint("TOPRIGHT", self, "TOPRIGHT", 21, 0)
end)

categoryScroll:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 20, categoryListUpdate)
end)

function categoryListUpdate()
	local offset = FauxScrollFrame_GetOffset(categoryScroll) or 0
	local name, level
	for index, btn in ipairs(categoryButtons) do
		btn:Hide()
		index = index + offset
		if categoryList[index] then
			btn:SetID(index)
			index = categoryList[index]
			name, level = getCategoryInfo(index)
			btn:SetText(name)
			if selectedCategory == index then
				btn:LockHighlight()
			else
				btn:UnlockHighlight()
			end
			btn.text:SetPoint("TOPLEFT", btn.middle, "TOPLEFT", (level - 1) * 8 - 1, 0)
			if categoryLast[index] and level ~= 1 then
				btn.left:SetAlpha(0)
				btn.middle:SetAlpha(0)
				btn.right:SetAlpha(0)
				btn.line:Show()
				if categoryLast[categoryList[btn:GetID() + 1]] then
					btn.line:SetTexCoord(0, 0.4375, 0, 0.625)
				else
					btn.line:SetTexCoord(0.4375, 0.875, 0, 0.625)
				end
			else
				btn.line:Hide()
				if level == 1 then
					btn.left:SetAlpha(1)
					btn.middle:SetAlpha(1)
					btn.right:SetAlpha(1)
				else
					btn.left:SetAlpha(0.5)
					btn.middle:SetAlpha(0.5)
					btn.right:SetAlpha(0.5)
				end
			end
			btn:Show()
		end
	end
	FauxScrollFrame_Update(categoryScroll, #categoryList, #categoryButtons, 20)
	IDR:HideAllDropdown()
end

local modelSlots = {}

local function modelSlotOnClick(self)
	IDR:HideAllDropdown()
	if selectedModelIndex == self:GetID() then
		self:SetChecked(true)
	else
		selectedModelIndex = self:GetID()
		selectedCategoryModels[selectedCategory] = selectedModelIndex
		IDR.selectedModel = selectedCategory.."-"..selectedModelIndex
		IDR:UpdateDetail()
		for _, btn in ipairs(modelSlots) do
			btn:SetChecked(btn == self)
		end
	end
end

local function modelSlotOnEnter(self)
	IDR:ModelPreviewShow(self, selectedCategory.."-"..self:GetID(), nil, -4, -2)
end

local function modelSlotOnLeave(self)
	IDR:ModelPreviewHide()
end

for i = 1, 32 do
	modelSlots[i] = CreateFrame("CheckButton", addOnName.."ItemModelButton"..i, IDR)
	modelSlots[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	modelSlots[i]:Disable()
	modelSlots[i]:SetFrameLevel(frameLevel + 1)
	modelSlots[i]:SetSize(37, 37)
	modelSlots[i]:SetScale(0.9)
	modelSlots[i]:SetNormalTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
	modelSlots[i]:GetNormalTexture():SetTexCoord(0.07, 0.93, 0.07, 0.93)
	modelSlots[i]:SetDisabledTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
	modelSlots[i]:GetDisabledTexture():SetTexCoord(0.07, 0.93, 0.07, 0.93)
	modelSlots[i]:SetCheckedTexture("Interface\\Buttons\\UI-Button-Outline", "ADD")
	modelSlots[i]:GetCheckedTexture():ClearAllPoints()
	modelSlots[i]:GetCheckedTexture():SetSize(64, 64)
	modelSlots[i]:GetCheckedTexture():SetPoint("CENTER", 1, 0)
	modelSlots[i]:SetScript("PostClick", modelSlotOnClick)
	modelSlots[i]:SetScript("OnEnter", modelSlotOnEnter)
	modelSlots[i]:SetScript("OnLeave", modelSlotOnLeave)
	modelSlots[i].favorite = modelSlots[i]:CreateTexture(nil, "OVERLAY")
	modelSlots[i].favorite:SetSize(16, 16)
	modelSlots[i].favorite:SetPoint("TOPLEFT", 2, -1)
	modelSlots[i].favorite:SetTexture("Interface\\GLUES\\CharacterSelect\\Glues-AddOn-Icons")
	modelSlots[i].favorite:SetTexCoord(0.75, 1, 0, 1)
	modelSlots[i].favorite:Hide()
	borderMiddle = modelSlots[i]:CreateTexture(nil, "BACKGROUND")
	borderMiddle:SetSize(43, 43)
	borderMiddle:SetPoint("CENTER", 0, 0)
	borderMiddle:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Spellbook\\Spellbook-Mounts")
	borderMiddle:SetTexCoord(0.71093750, 0.79492188, 0.00390625, 0.17187500)
	borderMiddle:SetAlpha(0.5)
	borderMiddle:SetDesaturated(true)
	if i == 1 then
		modelSlots[i]:SetPoint("TOPLEFT", categoryScroll, "BOTTOMRIGHT", 40, 200)
	elseif i % 8 == 1 then
		modelSlots[i]:SetPoint("TOPLEFT", modelSlots[i - 8], "BOTTOMLEFT", 0, -8)
	else
		modelSlots[i]:SetPoint("TOPLEFT", modelSlots[i - 1], "TOPRIGHT", 8, 0)
	end
end

local nextModelSlotButton = CreateFrame("Button", addOnName.."NextItemModelPage", IDR)
nextModelSlotButton:SetFrameLevel(frameLevel + 1)
nextModelSlotButton:SetScale(0.8)
nextModelSlotButton:SetSize(32, 32)
nextModelSlotButton:SetPoint("TOPRIGHT", modelSlots[#modelSlots], "BOTTOMRIGHT", 8, -1)
nextModelSlotButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
nextModelSlotButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
nextModelSlotButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
nextModelSlotButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
nextModelSlotButton:Disable()

local prevModelSlotButton = CreateFrame("Button", addOnName.."PrevItemModelPage", IDR)
prevModelSlotButton:SetFrameLevel(frameLevel + 1)
prevModelSlotButton:SetScale(0.8)
prevModelSlotButton:SetSize(32, 32)
prevModelSlotButton:SetPoint("RIGHT", nextModelSlotButton, "LEFT", 0, 0)
prevModelSlotButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
prevModelSlotButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
prevModelSlotButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
prevModelSlotButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
prevModelSlotButton:Disable()

local modelSlotPageText = IDR:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
modelSlotPageText:SetPoint("RIGHT", prevModelSlotButton, "LEFT", -5, 1)

local modelNumSlotText = IDR:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
modelNumSlotText:SetPoint("TOP", modelSlotPageText, "TOP", 0, 0)
modelNumSlotText:SetPoint("LEFT", modelSlots[1], "LEFT", -2, 0)

borderMiddle = IDR:CreateTexture(nil, "OVERLAY", nil, 0)
borderMiddle:SetPoint("TOP", categoryScroll, "TOP", 0, 0)
borderMiddle:SetPoint("BOTTOMLEFT", modelSlots[1], "TOPLEFT", -2, 6)
borderMiddle:SetPoint("RIGHT", modelSlots[4], "RIGHT", 2, 0)
borderMiddle:SetTexture(0.2, 0.2, 0.2, 0.7)
borderTopLeft = CreateFrame("Frame", addOnName.."ShadowOverlay", IDR, "ShadowOverlayTemplate")
borderTopLeft:SetFrameLevel(frameLevel + 1)
borderTopLeft:SetPoint("TOPLEFT", borderMiddle, "TOPLEFT", 2, -2)
borderTopLeft:SetPoint("BOTTOMRIGHT", borderMiddle, "BOTTOMRIGHT", -2, 2)
borderMiddle = borderTopLeft:CreateTexture(nil, "BACKGROUND")
borderMiddle:SetAllPoints()
borderMiddle:SetTexture("Interface\\AddOns\\WOW_V6UI\\Texture\\Spellbook\\Spellbook-Mounts")
borderMiddle:SetTexCoord(0.03515625, 0.5859375, 0.0703125, 0.83203125)

IDR.detailModelFrame = createDressUpModel(addOnName.."DetailModelFrame", borderTopLeft)
IDR.detailModelFrame:SetFrameLevel(frameLevel + 2)
IDR.detailModelFrame:Hide()
IDR.detailModelFrame:SetAllPoints()

IDR.detailModelFrame.loading = createLoadingAnimation(borderTopLeft)
IDR.detailModelFrame.loading:SetPoint("CENTER", 0, 10)

IDR.detailItems = {}

local function detailItemOnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 17)
	GameTooltip:SetHyperlink("item:"..self:GetID())
	GameTooltip:Show()
	IDR:ModelPreviewShow(self, self:GetID())
end

local function detailItemOnLeave(self)
	GameTooltip:Hide()
	IDR:ModelPreviewHide()
end

for i = 1, 10 do
	IDR.detailItems[i] = CreateFrame("Button", addOnName.."DetailItemButton"..i, IDR)
	IDR.detailItems[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	IDR.detailItems[i]:SetFrameLevel(frameLevel + 1)
	IDR.detailItems[i]:SetHeight(17)
	IDR.detailItems[i]:SetNormalTexture("")
	IDR.detailItems[i]:GetNormalTexture():SetTexCoord(0.07, 0.93, 0.07, 0.93)
	IDR.detailItems[i]:GetNormalTexture():ClearAllPoints()
	IDR.detailItems[i]:GetNormalTexture():SetSize(17, 17)
	IDR.detailItems[i]:GetNormalTexture():SetPoint("LEFT", 0, 0)
	IDR.detailItems[i]:SetNormalFontObject("GameFontHighlightSmallLeft")
	IDR.detailItems[i]:SetText(" ")
	IDR.detailItems[i]:GetFontString():ClearAllPoints()
	IDR.detailItems[i]:GetFontString():SetPoint("LEFT", 19, 1)
	IDR.detailItems[i]:GetFontString():SetPoint("RIGHT", 0, 1)
	IDR.detailItems[i]:SetScript("OnEnter", detailItemOnEnter)
	IDR.detailItems[i]:SetScript("OnLeave", detailItemOnLeave)
	IDR.detailItems[i]:Hide()
	if i == 1 then
		IDR.detailItems[i]:SetPoint("TOPLEFT", borderTopLeft, "TOPRIGHT", 6, -2)
		IDR.detailItems[i]:SetPoint("RIGHT", -11, 0)
	else
		IDR.detailItems[i]:SetPoint("TOPLEFT", IDR.detailItems[i - 1], "BOTTOMLEFT", 0, 0)
		IDR.detailItems[i]:SetPoint("TOPRIGHT", IDR.detailItems[i - 1], "BOTTOMRIGHT", 0, 0)
	end
end

IDR.detailItemScroll = CreateFrame("ScrollFrame", addOnName.."ItemScrollFrame", IDR, "ListScrollFrameTemplate")
IDR.detailItemScroll:SetFrameLevel(frameLevel + 2)
IDR.detailItemScroll:SetPoint("TOPLEFT", borderTopLeft, "TOPRIGHT", 6, 2)
IDR.detailItemScroll:SetPoint("BOTTOM", modelSlots[1], "TOP", 0, 6)
IDR.detailItemScroll:SetPoint("RIGHT", -33, 0)
IDR.detailItemScroll:SetHitRectInsets(0, -28, 0, 0)
IDR.detailItemScroll:SetScript("OnShow", function(self)
	IDR.detailItems[1]:SetPoint("RIGHT", self, "RIGHT", 0, 0)
end)
IDR.detailItemScroll:SetScript("OnHide", function(self)
	IDR.detailItems[1]:SetPoint("RIGHT", -11, 0)
end)
IDR.detailItemScroll:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 17, IDR.UpdateDetailItems)
end)

fixScrollBarBorder(IDR.detailItemScroll)
_G[IDR.detailItemScroll:GetName().."ScrollChildFrame"]:SetSize(1, 1)

local equipLocBackgrounds = {
	INVTYPE_2HWEAPON = select(2, GetInventorySlotInfo("MainHandSlot")),
	INVTYPE_WEAPON = select(2, GetInventorySlotInfo("MainHandSlot")),
	INVTYPE_WEAPONMAINHAND = select(2, GetInventorySlotInfo("MainHandSlot")),
	INVTYPE_WEAPONOFFHAND = select(2, GetInventorySlotInfo("MainHandSlot")),
	INVTYPE_HOLDABLE = select(2, GetInventorySlotInfo("SecondaryHandSlot")),
	INVTYPE_SHIELD = select(2, GetInventorySlotInfo("SecondaryHandSlot")),
	INVTYPE_RANGED = select(2, GetInventorySlotInfo("RangedSlot")),
	INVTYPE_HEAD = select(2, GetInventorySlotInfo("HeadSlot")),
	INVTYPE_SHOULDER = select(2, GetInventorySlotInfo("ShoulderSlot")),
	INVTYPE_CLOAK = select(2, GetInventorySlotInfo("BackSlot")),
	INVTYPE_CHEST = select(2, GetInventorySlotInfo("ChestSlot")),
	INVTYPE_WRIST = select(2, GetInventorySlotInfo("WristSlot")),
	INVTYPE_HAND = select(2, GetInventorySlotInfo("HandsSlot")),
	INVTYPE_WAIST = select(2, GetInventorySlotInfo("WaistSlot")),
	INVTYPE_LEGS = select(2, GetInventorySlotInfo("LegsSlot")),
	INVTYPE_FEET = select(2, GetInventorySlotInfo("FeetSlot")),
}
local detailPage, detailNumPage, detailNumModels

local function detailModelPageUpdate()
	selectedCategoryPages[selectedCategory] = detailPage > 1 and detailPage or nil
	local start = (detailPage - 1) * #modelSlots
	local favorites = IDR:GetFavoriteDB(selectedCategory)
	for index, btn in ipairs(modelSlots) do
		index = start + index
		btn:SetID(index)
		btn.favorite:Hide()
		if index > detailNumModels then
			btn:Disable()
			btn:SetChecked(nil)
		else
			btn:Enable()
			btn:SetChecked(selectedModelIndex == index)
			index = GetAddOnMetadata(modName, "X-DB-"..selectedCategory.."-"..index)
			btn:SetNormalTexture(index and GetItemIcon(index:match("(%d+)$")) or nil)
			if favorites then
				for item in index:gmatch("(%d+)") do
					if favorites[tonumber(item)] then
						btn.favorite:Show()
						break
					end
				end
			end
		end
	end
	modelSlotPageText:SetFormattedText("%d / %d", detailPage, detailNumPage)
	if detailPage == 1 then
		prevModelSlotButton:Disable()
	else
		prevModelSlotButton:Enable()
	end
	if detailPage == detailNumPage then
		nextModelSlotButton:Disable()
	else
		nextModelSlotButton:Enable()
	end
end

IDR.UpdateDetailModelPage = detailModelPageUpdate

nextModelSlotButton:SetScript("OnClick", function()
	IDR:HideAllDropdown()
	detailPage = detailPage + 1
	detailModelPageUpdate()
end)
prevModelSlotButton:SetScript("OnClick", function()
	IDR:HideAllDropdown()
	detailPage = detailPage - 1
	detailModelPageUpdate()
end)

function detailUpdate()
	if selectedCategory:find("^[2A-Z]+_") then
		IDR.selectedEquipLoc = "INVTYPE_"..selectedCategory:match("^([2A-Z]+)_")
	elseif selectedCategory:find("^[2A-Z]+$") then
		IDR.selectedEquipLoc = "INVTYPE_"..selectedCategory
	else
		IDR.selectedEquipLoc = "SET"
	end
	if IDR.selectedEquipLoc == "SET" then
		IDR.selectedModel = selectedCategory
		detailNumModels, detailNumPage, detailPage, selectedModelIndex = nil
		prevModelSlotButton:Disable()
		nextModelSlotButton:Disable()
		modelSlotPageText:SetText(nil)
		modelNumSlotText:SetText(nil)
		for _, btn in ipairs(modelSlots) do
			btn:SetDisabledTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
			btn:Disable()
			btn:SetChecked(nil)
			btn.favorite:Hide()
		end
	else
		detailNumModels = tonumber(GetAddOnMetadata(modName, "X-DB-"..selectedCategory) or 0)
		if detailNumModels > 0 then
			modelNumSlotText:SetFormattedText("%d개의 아이템 모델", detailNumModels)
			detailNumPage = ceil(detailNumModels / #modelSlots)
		else
			modelNumSlotText:SetText(nil)
			detailNumPage = 1
		end
		detailPage = selectedCategoryPages[selectedCategory] or 1
		if selectedCategoryModels[selectedCategory] then
			selectedModelIndex = selectedCategoryModels[selectedCategory]
			IDR.selectedModel = selectedCategory.."-"..selectedModelIndex
		else
			selectedModelIndex = nil
			IDR.selectedModel = nil
		end
		for _, btn in ipairs(modelSlots) do
			btn:SetDisabledTexture(equipLocBackgrounds[IDR.selectedEquipLoc])
		end
		detailModelPageUpdate()
	end
	IDR:UpdateDetail()
end

do
	local backdrop = {
		bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		insets = {left = 11, right = 11, top = 12, bottom = 11},
		tile = true, tileSize = 256, edgeSize = 32,
	}

	local function scrollOnShow(self)
		self:GetParent().items[1]:SetPoint("RIGHT", self, "RIGHT", 0, 0)
	end

	local function scrollOnHide(self)
		self:GetParent().items[1]:SetPoint("RIGHT", -11, 0)
	end

	local function createScroll(itemListMenu, level, onScroll)
		itemListMenu.scroll = CreateFrame("ScrollFrame", itemListMenu:GetName().."ItemScrollFrame", itemListMenu, "ListScrollFrameTemplate")
		itemListMenu.scroll:SetFrameLevel(level)
		itemListMenu.scroll:SetPoint("TOPLEFT", 12, -12)
		itemListMenu.scroll:SetPoint("BOTTOMRIGHT", -33, 11)
		itemListMenu.scroll:SetHitRectInsets(0, -28, 0, 0)
		itemListMenu.scroll:SetScript("OnShow", scrollOnShow)
		itemListMenu.scroll:SetScript("OnHide", scrollOnHide)
		itemListMenu.scroll:SetScript("OnVerticalScroll", onScroll)
		fixScrollBarBorder(itemListMenu.scroll)
	end

	local function createItems(itemListMenu, num, level, offset)
		itemListMenu.items = {}
		for i = 1, num do
			itemListMenu.items[i] = CreateFrame("Button", itemListMenu:GetName().."ItemButton"..i, itemListMenu)
			itemListMenu.items[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			itemListMenu.items[i]:SetFrameLevel(level)
			itemListMenu.items[i]:SetHeight(17)
			itemListMenu.items[i]:SetNormalTexture("")
			itemListMenu.items[i]:GetNormalTexture():SetTexCoord(0.07, 0.93, 0.07, 0.93)
			itemListMenu.items[i]:GetNormalTexture():ClearAllPoints()
			itemListMenu.items[i]:GetNormalTexture():SetSize(17, 17)
			itemListMenu.items[i]:GetNormalTexture():SetPoint("LEFT", 0, 0)
			itemListMenu.items[i]:SetNormalFontObject("GameFontHighlightLeft")
			itemListMenu.items[i]:SetText(" ")
			itemListMenu.items[i]:GetFontString():ClearAllPoints()
			itemListMenu.items[i]:GetFontString():SetPoint("LEFT", 19, 0)
			itemListMenu.items[i]:GetFontString():SetPoint("RIGHT", 0, 0)
			itemListMenu.items[i]:SetScript("OnEnter", detailItemOnEnter)
			itemListMenu.items[i]:SetScript("OnLeave", detailItemOnLeave)
			itemListMenu.items[i]:Hide()
			if i == 1 then
				itemListMenu.items[i]:SetPoint("TOPLEFT", 14, offset)
				itemListMenu.items[i]:SetPoint("RIGHT", -11, 0)
			else
				itemListMenu.items[i]:SetPoint("TOPLEFT", itemListMenu.items[i - 1], "BOTTOMLEFT", 0, 0)
				itemListMenu.items[i]:SetPoint("TOPRIGHT", itemListMenu.items[i - 1], "BOTTOMRIGHT", 0, 0)
			end
		end
	end

	local function createListMenu(name, level, title, onScroll)
		local itemListMenu = CreateFrame("Frame", addOnName..name, IDR)
		itemListMenu:Hide()
		itemListMenu:SetScale(0.9)
		itemListMenu:SetSize(230, title and 207 or 193)
		level = frameLevel + level
		itemListMenu:SetFrameLevel(level)
		--itemListMenu:SetToplevel(true)
		itemListMenu:EnableMouse(true)
		itemListMenu:SetClampedToScreen(true)
		itemListMenu:SetScript("OnHide", itemListMenu.Hide)
		itemListMenu:SetBackdrop(backdrop)

		if title then
			borderTopLeft = itemListMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			borderTopLeft:SetPoint("TOP", -4, -2)
			borderTopLeft:SetText(title)

			borderTopRight = CreateFrame("Button", itemListMenu:GetName().."CloseButton", itemListMenu, "UIPanelCloseButton")
			level = level + 1
			borderTopRight:SetFrameLevel(level)
			borderTopRight:SetPoint("LEFT", borderTopLeft, "RIGHT", -2, 0)

			borderMiddle = itemListMenu:CreateTexture(nil, "ARTWORK")
			borderMiddle:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
			borderMiddle:SetTexCoord(0.3046875, 0.6953125, 0, 1)
			borderMiddle:SetHeight(64)
			borderMiddle:SetPoint("TOPLEFT", borderTopLeft, "TOPLEFT", -5, 14)
			borderMiddle:SetPoint("TOPRIGHT", borderTopRight, "TOPRIGHT", -14, 14)
			borderBotLeft = itemListMenu:CreateTexture(nil, "ARTWORK")
			borderBotLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
			borderBotLeft:SetTexCoord(0, 0.3046875, 0, 1)
			borderBotLeft:SetSize(78, 64)
			borderBotLeft:SetPoint("TOPRIGHT", borderMiddle, "TOPLEFT", 0, 0)
			borderBotRight = itemListMenu:CreateTexture(nil, "ARTWORK")
			borderBotRight:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
			borderBotRight:SetTexCoord(0.6953125, 1, 0, 1)
			borderBotRight:SetSize(78, 64)
			borderBotRight:SetPoint("TOPLEFT", borderMiddle, "TOPRIGHT", 0, 0)
		end

		level = level + 1
		createScroll(itemListMenu, level, onScroll)
		createItems(itemListMenu, 10, level, title and -26 or -12)

		return itemListMenu
	end

	IDR.itemListMenu = createListMenu("ItemListMenu", 10, "아이템 목록", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 17, IDR.UpdateItemListMenuItems)
	end)
	IDR.itemListMenu:HookScript("OnHide", function(self)
		IDR:ClearItemListMenu()
	end)

	IDR.weaponEnchantMenu = createListMenu("WeaponEnchantListMenu", 7, "마법부여 목록", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 17, IDR.UpdateWeaponEnchantListMenu)
	end)

	IDR.favoriteList = CreateFrame("Frame", addOnName.."FavoriteItemList", IDR.modelFrame)
	IDR.favoriteList:Hide()
	IDR.favoriteList:SetFrameLevel(IDR.modelFrame:GetFrameLevel() + 1)
	IDR.favoriteList:EnableMouse(true)
	IDR.favoriteList:SetBackdrop(backdrop)
	IDR.favoriteList:SetBackdropColor(1, 1, 1, 0.75)
	IDR.favoriteList:SetPoint("TOPLEFT", 0, -26)
	IDR.favoriteList:SetPoint("RIGHT", 0, 0)
	IDR.favoriteList:SetPoint("BOTTOM", IDR.itemSlots.MainHandSlot, "TOP", 0, 2)
	createScroll(IDR.favoriteList, IDR.favoriteList:GetFrameLevel() + 1, function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 17, IDR.UpdateFavoriteList)
	end)
	createItems(IDR.favoriteList, 15, IDR.favoriteList:GetFrameLevel() + 1, -13)

	IDR.favoriteList.mainCategory = createDropdown("FavoriteItemListMainCategory", IDR.favoriteList, 98, IDR.favoriteList:GetFrameLevel() + 1)
	IDR.favoriteList.mainCategory:SetPoint("BOTTOMLEFT", IDR.favoriteList, "TOPLEFT", -15, -9)

	IDR.favoriteList.subCategory = createDropdown("FavoriteItemListSubCategory", IDR.favoriteList, 98, IDR.favoriteList:GetFrameLevel() + 1)
	IDR.favoriteList.subCategory:SetPoint("BOTTOMRIGHT", IDR.favoriteList, "TOPRIGHT", 15, -9)

	IDR.searchItemList = createListMenu("SearchItemList", 10, nil, function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, 17, IDR.UpdateSearchItems)
	end)

end

do
	local function createCheckBox(box, text, check, inset)
		box = CreateFrame("CheckButton", addOnName..box, IDR)
		box:SetSize(24, 24)
		box:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		box:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
		box:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		box:SetNormalFontObject("GameFontNormalSmall")
		box:SetHighlightFontObject("GameFontHighlightSmall")
		box:SetText(text)
		box:GetFontString():ClearAllPoints()
		box:GetFontString():SetPoint("LEFT", box, "RIGHT", -1, 1)
		box:SetChecked(check)
		box:SetHitRectInsets(3, -inset, 3, 3)
		return box
	end

	borderTopLeft = createCheckBox("ShowHelmButton", SHOW_HELM, IDR.db.showHelm, 54)
	borderTopLeft:SetPoint("TOPLEFT", IDR.itemSlots.WristSlot, "BOTTOMLEFT", -1, -2)
	borderTopLeft:SetScript("OnClick", function(self)
		IDR.db.showHelm = self:GetChecked() and true or nil
		IDR:SetPlayerModel()
	end)
	borderBotLeft = createCheckBox("ShowCloakButton", SHOW_CLOAK, IDR.db.showCloak, 54)
	borderBotLeft:SetPoint("TOPLEFT", borderTopLeft, "BOTTOMLEFT", 0, 8)
	borderBotLeft:SetScript("OnClick", function(self)
		IDR.db.showCloak = self:GetChecked() and true or nil
		IDR:SetPlayerModel()
	end)
end


borderTopLeft, borderBotLeft, borderTopRight, borderBotRight, borderMiddle = nil

IDR:SetScript("OnShow", function(self)
	createCategoryList()
	self.modelTooltip:Show()
	self:ModelPreviewHide()
	self:Refresh()
	self:RegisterEvent("CURSOR_UPDATE")
	self:CURSOR_UPDATE()
	LibStub("LibBlueItemDrag-1.0"):RegisterItemDrag(self)
end)

IDR:SetScript("OnHide", function(self)
	wipe(categoryList)
	wipe(categoryLast)
	self:ModelPreviewHide()
	self.modelTooltip:Hide()
	self:UnregisterEvent("CURSOR_UPDATE")
	LibStub("LibBlueItemDrag-1.0"):UnregisterItemDrag(self)
	self:CloseAllStaticPopups()
	collectgarbage()
end)

--[[ 디버그 ]]--
--[[
local LBICR = LibStub("LibBlueItemCacheReceiver-1.0")
local handler = function() end

function IDR_CheckItemCache()
	local count, items = 0
	for _, loc in ipairs(mainCategory) do
		if subCategory[loc] then
			for _, sub in ipairs(subCategory[loc]) do
				items = GetAddOnMetadata(modName, "X-DB-"..loc.."_"..sub)
				if items then
					for i = 1, tonumber(items) do
						for item in GetAddOnMetadata(modName, "X-DB-"..loc.."_"..sub.."-"..i):gmatch("(%d+)") do
							LBICR:RegisterItemCache(tonumber(item), handler)
							count = count + 1
						end
					end
				end
			end
		else
			items = GetAddOnMetadata(modName, "X-DB-"..loc)
			if items then
				for i = 1, tonumber(items) do
					for item in GetAddOnMetadata(modName, "X-DB-"..loc.."-"..i):gmatch("(%d+)") do
						item = tonumber(item)
						LBICR:RegisterItemCache(tonumber(item), handler)
						count = count + 1
					end
				end
			end
		end
	end
	print(count)
end]]