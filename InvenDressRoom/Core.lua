local addOnName = ...

local IDR = CreateFrame("Frame", addOnName, UIParent)
IDR:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
IDR:RegisterEvent("PLAYER_LOGIN")
IDR:Hide()
IDR:SetFrameLevel(1)
IDR:SetToplevel(true)
tinsert(UISpecialFrames, addOnName)

local _G = getfenv(0)

BINDING_HEADER_INVENDRESSROOM = "인벤 드레스 룸"
BINDING_NAME_INVENDRESSROOM_TOGGLE = "창 열기/닫기"
BINDING_NAME_INVENDRESSROOM_OPTION = "욥션창 열기/닫기"
SLASH_INVENDRESSROOM1 = "/idr"
SLASH_INVENDRESSROOM2 = "/ㅑㅇㄱ"
--SLASH_INVENDRESSROOM3 = "/옷장"
--SLASH_INVENDRESSROOM4 = "/드레스룸"
--SLASH_INVENDRESSROOM5 = "/인벤옷장"
--SLASH_INVENDRESSROOM6 = "/인벤드레스룸"

SlashCmdList["INVENDRESSROOM"] = function()
	if IDR.itemSlots then
		if IDR:IsShown() then
			IDR:Hide()
		else
			IDR:Show()
		end
	else
		LoadAddOn(addOnName.."_Search")
		LoadAddOn(addOnName.."_UI")
		if IDR.itemSlots then
			IDR:Show()
			collectgarbage()
		end
	end
end

IDR.optionFrame = CreateFrame("Frame", addOnName.."OptionFrame")
IDR.optionFrame:Hide()
IDR.optionFrame.name = "인벤 드레스 룸"
IDR.optionFrame:SetScript("OnShow", function(self)
	self:SetScript("OnShow", nil)
	LoadAddOn(addOnName.."_Option")
end)
InterfaceOptions_AddCategory(IDR.optionFrame)

function IDR:PLAYER_LOGIN()
	self.PLAYER_LOGIN = nil
	self:UnregisterEvent("PLAYER_LOGIN")
	self.defaultModelRace = select(2, UnitRace("player"))..(UnitSex("player") == 2 and "Male" or "Female")
	InvenDressRoomDB = InvenDressRoomDB or {
		scale = 1, showHelm = true, showCloak = true, showWeapon = 1,
		currentItemSet = nil, currentItems = {}, itemSets = {}, favorites = {},
		minimapButton = {
			show = true,
			radius = 80,
			angle = 1.47,
			dragable = true,
			rounding = 10,
		},
	}
	self.db = InvenDressRoomDB
	if not self.db.itemSets[self.db.currentItemSet] then
		self.db.currentItemSet = nil
	end
	if not self.db.currentItems.modelRace then
		self.db.currentItems.modelRace = self.defaultModelRace
	end
	self.icon = "Interface\\Icons\\INV_Arcane_Orb"
	LibStub("LibMapButton-1.1"):CreateButton(self, addOnName.."MapButton", self.icon, 1.47, InvenDressRoomDB.minimapButton)
	LibStub("LibDataBroker-1.1"):NewDataObject(addOnName, {
		type = "launcher",
		text = "IDR",
		OnClick = self.OnClick,
		icon = self.icon,
		OnTooltipShow = function(tooltip)
			if tooltip and tooltip.AddLine then
				IDR:OnTooltip(tooltip)
			end
		end,
	})
end

function IDR:AddMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00[IDR]|r "..msg)
end

function IDR:OnClick(button)
	if button == "RightButton" then
		InterfaceOptionsFrame_OpenToCategory(IDR.optionFrame)
	else
		SlashCmdList["INVENDRESSROOM"]()
	end
end

function IDR:OnTooltip(tooltip)
	tooltip = tooltip or GameTooltip
	tooltip:AddLine("Inven Dress Room v"..GetAddOnMetadata(addOnName, "Version"))
	tooltip:AddLine(GetAddOnMetadata(addOnName, "X-Website"), 1, 1, 1)
	tooltip:AddLine("좌클릭: 창 열기/닫기", 1, 1, 0)
	tooltip:AddLine("우클릭: 창 열기/닫기", 1, 1, 0)
end

local staticPopups = {}

function IDR:AddStaticPopup(which, info)
	which = addOnName:upper().."_"..which
	StaticPopupDialogs[which] = info
	staticPopups[which] = true
	return which
end

function IDR:CloseAllStaticPopups()
	for which in pairs(staticPopups) do
		StaticPopup_Hide(which)
	end
end