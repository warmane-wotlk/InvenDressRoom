local IDR = _G[GetAddOnDependencies(...)]
local Option = IDR.optionFrame
local LBO = LibStub("LibBlueOption-1.0")

Option.title = Option:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
Option.title:SetPoint("TOPLEFT", 16, -16)
Option.title:SetText(Option.name)
Option.version = Option:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
Option.version:SetPoint("LEFT", Option.title, "RIGHT", 2, 0)
Option.version:SetText("v"..GetAddOnMetadata(IDR:GetName(), "Version"))
Option.subText = Option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
Option.subText:SetPoint("TOPLEFT", Option.title, "TOPLEFT", 15, -40)
Option.subText:SetHeight(32)
Option.subText:SetJustifyH("LEFT")
Option.subText:SetJustifyV("TOP")
Option.subText:SetNonSpaceWrap(true)
Option.subText:SetPoint("TOPLEFT", Option.title, "BOTTOMLEFT", 0, -8)
Option.subText:SetPoint("RIGHT", -32, 0)
Option.subText:SetText("형상 변환이 가능한 아이템의 외형을 찾아보고 미리 입어보며, 그 세팅을 저장할 수 있는 애드온입니다.")

Option.scale = LBO:CreateWidget("Slider", Option, "창 크기", "UI 창의 전체적인 크기를 설정합니다.", nil, nil, nil,
	function()
		return IDR.db.scale * 100, 50, 150, 1, "%"
	end,
	function(v)
		IDR.db.scale = v / 100
		IDR:SetScale(IDR.db.scale)
		IDR.modelFrame:RefreshCamera()
		IDR.detailModelFrame:RefreshCamera()
	end
)
Option.scale:SetPoint("TOP", Option.subText, "BOTTOM", 0, 0)
Option.scale:SetPoint("LEFT", 10, 0)

Option.showButton = LBO:CreateWidget("CheckBox", Option, "미니맵 버튼 표시하기", "미니맵 버튼을 표시합니다.", nil, nil, nil,
	function()
		return IDR.db.minimapButton.show
	end,
	function(v)
		IDR.db.minimapButton.show = v
		_G[IDR:GetName().."MapButton"]:Toggle()
	end
)
Option.showButton:SetPoint("TOPLEFT", Option.scale, "BOTTOMLEFT", 0, 0)

Option.lockButton = LBO:CreateWidget("CheckBox", Option, "미니맵 버튼 잠그기", "미니맵 버튼을 잠가 이동하지 못하게 합니다.", nil,
	function()
		return not IDR.db.minimapButton.show
	end, nil,
	function()
		return IDR.db.minimapButton.dragable
	end,
	function(v)
		IDR.db.minimapButton.dragable = v
	end
)
Option.lockButton:SetPoint("TOPLEFT", Option.showButton, "BOTTOMLEFT", 0, 10)