local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Pre-cache game remotes and containers
local remotes = ReplicatedStorage:WaitForChild("Paper"):WaitForChild("Remotes")
local remoteEvent = remotes:WaitForChild("__remoteevent")
local remoteFunction = remotes:WaitForChild("__remotefunction")
local eggsFolder = Workspace:WaitForChild("Eggs")

local fireServer = remoteEvent.FireServer
local invokeServer = remoteFunction.InvokeServer

---------------------------------------------------------------------
-- SYRU UI LIBRARY CORE
---------------------------------------------------------------------
local SyruLib = {
	Theme = {
		Background = Color3.fromRGB(20, 20, 24),
		Sidebar = Color3.fromRGB(25, 25, 30),
		Card = Color3.fromRGB(30, 30, 36),
		CardStroke = Color3.fromRGB(45, 45, 55),
		Accent = Color3.fromRGB(255, 105, 180), -- Syru Pink
		Text = Color3.fromRGB(240, 240, 240),
		TextDark = Color3.fromRGB(160, 160, 170)
	},
	Sizes = {
		["Tiny"]   = Vector2.new(360, 220),
		["Small"]  = Vector2.new(440, 270),
		["Medium"] = Vector2.new(520, 320),
		["Big"]    = Vector2.new(590, 360),
		["Large"]  = Vector2.new(660, 410)
	}
}

local function getSafeGuiParent()
	if gethui then return gethui() end
	local success, _ = pcall(function() return CoreGui:GetChildren() end)
	if success then return CoreGui end
	return LocalPlayer:WaitForChild("PlayerGui")
end

function SyruLib:CreateWindow(config)
	local titleText = config.Title or "SYRU HUB"
	local subTitleText = config.SubTitle or "Chicken Farm"
	local accentColor = config.Accent or SyruLib.Theme.Accent

	local parentTarget = getSafeGuiParent()
	local oldUI = parentTarget:FindFirstChild("SyruHubUI")
	if oldUI then oldUI:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "SyruHubUI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = parentTarget

	local defaultSize = SyruLib.Sizes["Medium"]
	local Main = Instance.new("Frame")
	Main.Name = "Main"
	Main.Size = UDim2.new(0, defaultSize.X, 0, defaultSize.Y)
	Main.Position = UDim2.new(0.5, -defaultSize.X / 2, 0.5, -defaultSize.Y / 2)
	Main.BackgroundColor3 = SyruLib.Theme.Background
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = true
	Main.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = UDim.new(0, 10)
	MainCorner.Parent = Main

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = SyruLib.Theme.CardStroke
	MainStroke.Thickness = 1
	MainStroke.Parent = Main

	---------------------------------------------------------------------
	-- FLOATING "SYRU" BUTTON
	---------------------------------------------------------------------
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "SyruToggle"
	ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
	ToggleBtn.Position = UDim2.new(0, 20, 0.5, -24)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBtn.BorderSizePixel = 0
	ToggleBtn.Text = "syru"
	ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ToggleBtn.TextSize = 14
	ToggleBtn.Font = Enum.Font.GothamBold
	ToggleBtn.AutoButtonColor = false
	ToggleBtn.ZIndex = 100
	ToggleBtn.Parent = ScreenGui

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(1, 0)
	ToggleCorner.Parent = ToggleBtn

	local isDragging = false
	local hasMoved = false
	local dragStartPos = nil
	local startFramePos = nil

	ToggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			hasMoved = false
			dragStartPos = input.Position
			startFramePos = ToggleBtn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if isDragging and not hasMoved then
						Main.Visible = not Main.Visible
					end
					isDragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStartPos
			if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
				hasMoved = true
			end
			ToggleBtn.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
			)
		end
	end)

	---------------------------------------------------------------------
	-- SIDEBAR & DRAGGING
	---------------------------------------------------------------------
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 130, 1, 0)
	Sidebar.BackgroundColor3 = SyruLib.Theme.Sidebar
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = Main

	local SidebarCorner = Instance.new("UICorner")
	SidebarCorner.CornerRadius = UDim.new(0, 10)
	SidebarCorner.Parent = Sidebar

	local SidebarFix = Instance.new("Frame")
	SidebarFix.Size = UDim2.new(0, 10, 1, 0)
	SidebarFix.Position = UDim2.new(1, -10, 0, 0)
	SidebarFix.BackgroundColor3 = SyruLib.Theme.Sidebar
	SidebarFix.BorderSizePixel = 0
	SidebarFix.Parent = Sidebar

	local DragBar = Instance.new("Frame")
	DragBar.Name = "DragBar"
	DragBar.Size = UDim2.new(1, 0, 0, 46)
	DragBar.BackgroundTransparency = 1
	DragBar.ZIndex = 5
	DragBar.Parent = Main

	local LogoTitle = Instance.new("TextLabel")
	LogoTitle.Size = UDim2.new(1, -16, 0, 18)
	LogoTitle.Position = UDim2.new(0, 12, 0, 8)
	LogoTitle.BackgroundTransparency = 1
	LogoTitle.Text = titleText
	LogoTitle.TextColor3 = accentColor
	LogoTitle.TextSize = 14
	LogoTitle.Font = Enum.Font.GothamBold
	LogoTitle.TextXAlignment = Enum.TextXAlignment.Left
	LogoTitle.Parent = Sidebar

	local LogoSub = Instance.new("TextLabel")
	LogoSub.Size = UDim2.new(1, -16, 0, 12)
	LogoSub.Position = UDim2.new(0, 12, 0, 24)
	LogoSub.BackgroundTransparency = 1
	LogoSub.Text = subTitleText
	LogoSub.TextColor3 = SyruLib.Theme.TextDark
	LogoSub.TextSize = 10
	LogoSub.Font = Enum.Font.GothamMedium
	LogoSub.TextXAlignment = Enum.TextXAlignment.Left
	LogoSub.Parent = Sidebar

	local TabList = Instance.new("ScrollingFrame")
	TabList.Size = UDim2.new(1, -8, 1, -44)
	TabList.Position = UDim2.new(0, 4, 0, 40)
	TabList.BackgroundTransparency = 1
	TabList.ScrollBarThickness = 0
	TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabList.Parent = Sidebar

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.Padding = UDim.new(0, 4)
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Parent = TabList

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Size = UDim2.new(1, -140, 1, -12)
	ContentContainer.Position = UDim2.new(0, 135, 0, 6)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.Parent = Main

	local winDragging = false
	local winDragInput, winDragStart, winStartPos
	local function updateWin(input)
		local delta = input.Position - winDragStart
		Main.Position = UDim2.new(
			winStartPos.X.Scale, winStartPos.X.Offset + delta.X,
			winStartPos.Y.Scale, winStartPos.Y.Offset + delta.Y
		)
	end

	DragBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			winDragging = true
			winDragStart = input.Position
			winStartPos = Main.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					winDragging = false
				end
			end)
		end
	end)

	DragBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			winDragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == winDragInput and winDragging then
			updateWin(input)
		end
	end)

	---------------------------------------------------------------------
	-- WINDOW INTERFACE & TABS
	---------------------------------------------------------------------
	local Window = {
		Tabs = {},
		ActiveTab = nil,
		CurrentSize = "Medium"
	}

	function Window:SetSize(sizeName)
		local targetDimensions = SyruLib.Sizes[sizeName]
		if not targetDimensions then return end

		Window.CurrentSize = sizeName
		local currentCenterX = Main.Position.X.Offset + (Main.AbsoluteSize.X / 2)
		local currentCenterY = Main.Position.Y.Offset + (Main.AbsoluteSize.Y / 2)
		local newPosX = currentCenterX - (targetDimensions.X / 2)
		local newPosY = currentCenterY - (targetDimensions.Y / 2)

		TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, targetDimensions.X, 0, targetDimensions.Y),
			Position = UDim2.new(Main.Position.X.Scale, newPosX, Main.Position.Y.Scale, newPosY)
		}):Play()
	end

	function Window:CreateTab(name)
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, 0, 0, 30)
		TabButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
		TabButton.AutoButtonColor = false
		TabButton.Text = name
		TabButton.TextColor3 = SyruLib.Theme.TextDark
		TabButton.TextSize = 12
		TabButton.Font = Enum.Font.GothamMedium
		TabButton.TextXAlignment = Enum.TextXAlignment.Left
		TabButton.Parent = TabList

		local TabPadding = Instance.new("UIPadding")
		TabPadding.PaddingLeft = UDim.new(0, 8)
		TabPadding.Parent = TabButton

		local TabCorner = Instance.new("UICorner")
		TabCorner.CornerRadius = UDim.new(0, 6)
		TabCorner.Parent = TabButton

		local Page = Instance.new("ScrollingFrame")
		Page.Name = name .. "Page"
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.ScrollBarThickness = 3
		Page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
		Page.CanvasSize = UDim2.new(0, 0, 0, 0)
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Page.Visible = false
		Page.Parent = ContentContainer

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Padding = UDim.new(0, 6)
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Parent = Page

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingTop = UDim.new(0, 4)
		PagePadding.PaddingBottom = UDim.new(0, 6)
		PagePadding.PaddingRight = UDim.new(0, 6)
		PagePadding.Parent = Page

		local function activateTab()
			for _, tab in pairs(Window.Tabs) do
				tab.Page.Visible = false
				TweenService:Create(tab.Button, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(25, 25, 30),
					TextColor3 = SyruLib.Theme.TextDark
				}):Play()
			end
			Page.Visible = true
			TweenService:Create(TabButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(35, 35, 42),
				TextColor3 = accentColor
			}):Play()
			Window.ActiveTab = Page
		end

		TabButton.MouseButton1Click:Connect(activateTab)
		table.insert(Window.Tabs, { Button = TabButton, Page = Page })

		if #Window.Tabs == 1 then activateTab() end

		---------------------------------------------------------------------
		-- ELEMENTS BUILDER
		---------------------------------------------------------------------
		local Elements = {}

		function Elements:AddSection(text)
			local Section = Instance.new("Frame")
			Section.Size = UDim2.new(1, 0, 0, 18)
			Section.BackgroundTransparency = 1
			Section.Parent = Page

			local SecLabel = Instance.new("TextLabel")
			SecLabel.Size = UDim2.new(1, 0, 1, 0)
			SecLabel.BackgroundTransparency = 1
			SecLabel.Text = string.upper(text)
			SecLabel.TextColor3 = accentColor
			SecLabel.TextSize = 10
			SecLabel.Font = Enum.Font.GothamBold
			SecLabel.TextXAlignment = Enum.TextXAlignment.Left
			SecLabel.Parent = Section
		end

		function Elements:AddToggle(text, default, callback)
			local state = default or false

			local Toggle = Instance.new("TextButton")
			Toggle.Size = UDim2.new(1, 0, 0, 34)
			Toggle.BackgroundColor3 = SyruLib.Theme.Card
			Toggle.AutoButtonColor = false
			Toggle.Text = ""
			Toggle.Parent = Page

			local ToggleCorner = Instance.new("UICorner")
			ToggleCorner.CornerRadius = UDim.new(0, 6)
			ToggleCorner.Parent = Toggle

			local ToggleStroke = Instance.new("UIStroke")
			ToggleStroke.Color = SyruLib.Theme.CardStroke
			ToggleStroke.Thickness = 1
			ToggleStroke.Parent = Toggle

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -48, 1, 0)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = SyruLib.Theme.Text
			Label.TextSize = 12
			Label.Font = Enum.Font.GothamSemibold
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Toggle

			local Switch = Instance.new("Frame")
			Switch.Size = UDim2.new(0, 32, 0, 18)
			Switch.Position = UDim2.new(1, -40, 0.5, -9)
			Switch.BackgroundColor3 = state and accentColor or Color3.fromRGB(45, 45, 52)
			Switch.BorderSizePixel = 0
			Switch.Parent = Toggle

			local SwitchCorner = Instance.new("UICorner")
			SwitchCorner.CornerRadius = UDim.new(1, 0)
			SwitchCorner.Parent = Switch

			local Circle = Instance.new("Frame")
			Circle.Size = UDim2.new(0, 12, 0, 12)
			Circle.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
			Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Circle.BorderSizePixel = 0
			Circle.Parent = Switch

			local CircleCorner = Instance.new("UICorner")
			CircleCorner.CornerRadius = UDim.new(1, 0)
			CircleCorner.Parent = Circle

			local function setToggle(val)
				state = val
				local switchColor = state and accentColor or Color3.fromRGB(45, 45, 52)
				local circlePos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)

				TweenService:Create(Switch, TweenInfo.new(0.15), {BackgroundColor3 = switchColor}):Play()
				TweenService:Create(Circle, TweenInfo.new(0.15), {Position = circlePos}):Play()

				if callback then task.spawn(callback, state) end
			end

			Toggle.MouseButton1Click:Connect(function()
				setToggle(not state)
			end)

			if default and callback then
				task.spawn(callback, true)
			end
		end

		function Elements:AddSlider(text, min, max, default, callback)
			local value = default or min

			local Slider = Instance.new("Frame")
			Slider.Size = UDim2.new(1, 0, 0, 42)
			Slider.BackgroundColor3 = SyruLib.Theme.Card
			Slider.Parent = Page

			local SliderCorner = Instance.new("UICorner")
			SliderCorner.CornerRadius = UDim.new(0, 6)
			SliderCorner.Parent = Slider

			local SliderStroke = Instance.new("UIStroke")
			SliderStroke.Color = SyruLib.Theme.CardStroke
			SliderStroke.Thickness = 1
			SliderStroke.Parent = Slider

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -60, 0, 18)
			Label.Position = UDim2.new(0, 10, 0, 4)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = SyruLib.Theme.Text
			Label.TextSize = 12
			Label.Font = Enum.Font.GothamSemibold
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = Slider

			local ValLabel = Instance.new("TextLabel")
			ValLabel.Size = UDim2.new(0, 45, 0, 18)
			ValLabel.Position = UDim2.new(1, -55, 0, 4)
			ValLabel.BackgroundTransparency = 1
			ValLabel.Text = tostring(value)
			ValLabel.TextColor3 = SyruLib.Theme.TextDark
			ValLabel.TextSize = 12
			ValLabel.Font = Enum.Font.GothamBold
			ValLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValLabel.Parent = Slider

			local Bar = Instance.new("Frame")
			Bar.Size = UDim2.new(1, -20, 0, 5)
			Bar.Position = UDim2.new(0, 10, 1, -12)
			Bar.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			Bar.BorderSizePixel = 0
			Bar.Parent = Bar

			local BarCorner = Instance.new("UICorner")
			BarCorner.CornerRadius = UDim.new(1, 0)
			BarCorner.Parent = Bar

			local Fill = Instance.new("Frame")
			local defaultPct = math.clamp((value - min) / (max - min), 0, 1)
			Fill.Size = UDim2.new(defaultPct, 0, 1, 0)
			Fill.BackgroundColor3 = accentColor
			Fill.BorderSizePixel = 0
			Fill.Parent = Bar

			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = Fill

			local sliding = false
			local function updateSlider(input)
				local percent = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
				local exactVal = math.floor(min + (max - min) * percent)
				Fill.Size = UDim2.new(percent, 0, 1, 0)
				ValLabel.Text = tostring(exactVal)
				if callback then task.spawn(callback, exactVal) end
			end

			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					updateSlider(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateSlider(input)
				end
			end)
		end

		function Elements:AddDropdown(text, options, default, callback)
			local selected = default or options[1]
			local dropped = false

			local Dropdown = Instance.new("Frame")
			Dropdown.Size = UDim2.new(1, 0, 0, 34)
			Dropdown.BackgroundColor3 = SyruLib.Theme.Card
			Dropdown.ClipsDescendants = true
			Dropdown.Parent = Page

			local DropCorner = Instance.new("UICorner")
			DropCorner.CornerRadius = UDim.new(0, 6)
			DropCorner.Parent = Dropdown

			local DropStroke = Instance.new("UIStroke")
			DropStroke.Color = SyruLib.Theme.CardStroke
			DropStroke.Thickness = 1
			DropStroke.Parent = Dropdown

			local HeaderBtn = Instance.new("TextButton")
			HeaderBtn.Size = UDim2.new(1, 0, 0, 34)
			HeaderBtn.BackgroundTransparency = 1
			HeaderBtn.Text = ""
			HeaderBtn.Parent = Dropdown

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -100, 1, 0)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = SyruLib.Theme.Text
			Label.TextSize = 12
			Label.Font = Enum.Font.GothamSemibold
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = HeaderBtn

			local ValLabel = Instance.new("TextLabel")
			ValLabel.Size = UDim2.new(0, 70, 1, 0)
			ValLabel.Position = UDim2.new(1, -95, 0, 0)
			ValLabel.BackgroundTransparency = 1
			ValLabel.Text = selected
			ValLabel.TextColor3 = accentColor
			ValLabel.TextSize = 11
			ValLabel.Font = Enum.Font.GothamBold
			ValLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValLabel.Parent = HeaderBtn

			local Arrow = Instance.new("TextLabel")
			Arrow.Size = UDim2.new(0, 18, 1, 0)
			Arrow.Position = UDim2.new(1, -22, 0, 0)
			Arrow.BackgroundTransparency = 1
			Arrow.Text = "v"
			Arrow.TextColor3 = SyruLib.Theme.TextDark
			Arrow.TextSize = 11
			Arrow.Font = Enum.Font.GothamBold
			Arrow.Parent = HeaderBtn

			local OptionContainer = Instance.new("Frame")
			OptionContainer.Size = UDim2.new(1, -12, 0, #options * 26)
			OptionContainer.Position = UDim2.new(0, 6, 0, 34)
			OptionContainer.BackgroundTransparency = 1
			OptionContainer.Parent = Dropdown

			local OptionLayout = Instance.new("UIListLayout")
			OptionLayout.Padding = UDim.new(0, 2)
			OptionLayout.SortOrder = Enum.SortOrder.LayoutOrder
			OptionLayout.Parent = OptionContainer

			local function toggleDropdown()
				dropped = not dropped
				local targetHeight = dropped and (34 + (#options * 26) + 6) or 34
				TweenService:Create(Dropdown, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
				TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = dropped and 180 or 0}):Play()
			end

			HeaderBtn.MouseButton1Click:Connect(toggleDropdown)

			for _, optName in ipairs(options) do
				local OptBtn = Instance.new("TextButton")
				OptBtn.Size = UDim2.new(1, 0, 0, 24)
				OptBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
				OptBtn.Text = optName
				OptBtn.TextColor3 = SyruLib.Theme.TextDark
				OptBtn.TextSize = 11
				OptBtn.Font = Enum.Font.GothamMedium
				OptBtn.AutoButtonColor = false
				OptBtn.Parent = OptionContainer

				local OptCorner = Instance.new("UICorner")
				OptCorner.CornerRadius = UDim.new(0, 4)
				OptCorner.Parent = OptBtn

				OptBtn.MouseButton1Click:Connect(function()
					selected = optName
					ValLabel.Text = selected
					toggleDropdown()
					if callback then task.spawn(callback, selected) end
				end)
			end
		end

		return Elements
	end

	return Window
end

---------------------------------------------------------------------
-- WINDOW INITIALIZATION
---------------------------------------------------------------------
local Window = SyruLib:CreateWindow({
	Title = "SYRU HUB",
	SubTitle = "Chicken Farm",
	Accent = Color3.fromRGB(255, 105, 180)
})

local FarmTab = Window:CreateTab("Farm")
local MiscTab = Window:CreateTab("Misc")
local SettingsTab = Window:CreateTab("Settings")

---------------------------------------------------------------------
-- TAB 1: FARM AUTOMATION
---------------------------------------------------------------------
FarmTab:AddSection("Egg Harvesting")

-- 1. Persistent Multi-Pass Egg Collector (Relentlessly re-checks all eggs until picked up)
local eggConn = nil
local collectActive = false

FarmTab:AddToggle("Instant Collect Eggs", false, function(state)
	collectActive = state

	if state then
		-- Immediate spawn listener
		if not eggConn then
			eggConn = eggsFolder.ChildAdded:Connect(function(egg)
				if not collectActive then return end
				task.defer(function()
					fireServer(remoteEvent, "Collect Egg", egg.Name)
				end)
			end)
		end

		-- Persistent multi-pass loop (keeps hitting eggs that failed or were delayed)
		task.spawn(function()
			while collectActive do
				local eggs = eggsFolder:GetChildren()
				if #eggs > 0 then
					for i = 1, #eggs do
						if not collectActive then break end
						local egg = eggs[i]
						if egg and egg.Parent then
							fireServer(remoteEvent, "Collect Egg", egg.Name)
						end
						-- Yield every 15 checks so the client remote queue doesn't choke
						if i % 15 == 0 then
							task.wait()
						end
					end
				end
				task.wait(0.15)
			end
		end)
	else
		if eggConn then
			eggConn:Disconnect()
			eggConn = nil
		end
	end
end)

-- 2. Auto Deposit Eggs
local depositActive = false
FarmTab:AddToggle("Auto Deposit Eggs", false, function(state)
	depositActive = state
	if state then
		task.spawn(function()
			while depositActive do
				pcall(function()
					invokeServer(remoteFunction, "Deposit Eggs")
				end)
				task.wait(1)
			end
		end)
	end
end)

FarmTab:AddSection("Breeding & Merging")

-- 3. Auto Merge (Only runs when mergeable pairs exist)
local mergeActive = false
FarmTab:AddToggle("Auto Merge", false, function(state)
	mergeActive = state
	if state then
		task.spawn(function()
			while mergeActive do
				pcall(function()
					-- In the Paper framework, merging triggers without arguments or checks for pairs
					invokeServer(remoteFunction, "Merge Chickens")
				end)
				task.wait(1.5)
			end
		end)
	end
end)

FarmTab:AddSection("Obby Rewards")

-- 4. Complete Obby (Respects internal cooldown)
local obbyActive = false
FarmTab:AddToggle("Complete Obby", false, function(state)
	obbyActive = state
	if state then
		task.spawn(function()
			while obbyActive do
				local success, result = pcall(function()
					return invokeServer(remoteFunction, "Complete Obby")
				end)

				-- If returned false or throttled, wait for standard 60s cooldown, otherwise retry in 10s
				if success and result ~= false then
					task.wait(60)
				else
					task.wait(10)
				end
			end
		end)
	end
end)

FarmTab:AddSection("Economy & Upgrades")

-- 5. Auto Collect Cash
local cashActive = false
FarmTab:AddToggle("Auto Collect Cash", false, function(state)
	cashActive = state
	if state then
		task.spawn(function()
			while cashActive do
				pcall(function()
					invokeServer(remoteFunction, "Collect Cash")
				end)
				task.wait(0.5)
			end
		end)
	end
end)

-- 6. Auto Upgrade Process Level
local upgradeActive = false
FarmTab:AddToggle("Auto Upgrade Level", false, function(state)
	upgradeActive = state
	if state then
		task.spawn(function()
			while upgradeActive do
				pcall(function()
					invokeServer(remoteFunction, "Upgrade Process Level")
				end)
				task.wait(1.5)
			end
		end)
	end
end)

-- 7. Auto Buy Chickens (Cascade fallback: 100 -> 25 -> 5 -> 1)
local buyActive = false
local chickenTiers = {100, 25, 5, 1}
FarmTab:AddToggle("Auto Buy Chickens", false, function(state)
	buyActive = state
	if state then
		task.spawn(function()
			while buyActive do
				for _, amount in ipairs(chickenTiers) do
					local success, res = pcall(function()
						return invokeServer(remoteFunction, "Buy Chickens", amount)
					end)
					if success and res ~= false then
						break
					end
				end
				task.wait(2)
			end
		end)
	end
end)

---------------------------------------------------------------------
-- TAB 2: MISC UTILITIES
---------------------------------------------------------------------
MiscTab:AddSection("Movement")

local defaultSpeed = 16
MiscTab:AddSlider("Walk Speed", 16, 120, 16, function(val)
	defaultSpeed = val
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = val end
end)

local defaultJump = 50
MiscTab:AddSlider("Jump Power", 50, 200, 50, function(val)
	defaultJump = val
	local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = val
	end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = defaultSpeed
		hum.UseJumpPower = true
		hum.JumpPower = defaultJump
	end
end)

MiscTab:AddSection("Traversal")

local infJumpActive = false
MiscTab:AddToggle("Infinite Jump", false, function(state)
	infJumpActive = state
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpActive then
		local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

local noclipActive = false
local noclipConn = nil
MiscTab:AddToggle("NoClip", false, function(state)
	noclipActive = state
	if state then
		noclipConn = RunService.Stepped:Connect(function()
			if noclipActive and LocalPlayer.Character then
				for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
	end
end)

---------------------------------------------------------------------
-- TAB 3: SETTINGS
---------------------------------------------------------------------
SettingsTab:AddSection("Window Scaling")
SettingsTab:AddDropdown("UI Size", {"Tiny", "Small", "Medium", "Big", "Large"}, "Medium", function(size)
	Window:SetSize(size)
end)
