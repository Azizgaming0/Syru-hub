local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Pre-cache remotes and containers
local remotes = ReplicatedStorage:WaitForChild("Paper"):WaitForChild("Remotes")
local remoteEvent = remotes:WaitForChild("__remoteevent")
local remoteFunction = remotes:WaitForChild("__remotefunction")
local eggsFolder = Workspace:WaitForChild("Eggs")

local fireServer = remoteEvent.FireServer
local invokeServer = remoteFunction.InvokeServer

local function getRoot()
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- SYRU UI LIBRARY
---------------------------------------------------------------------
local SyruLib = {
	Theme = {
		Background = Color3.fromRGB(20, 20, 24),
		Sidebar = Color3.fromRGB(25, 25, 30),
		Card = Color3.fromRGB(30, 30, 36),
		CardStroke = Color3.fromRGB(45, 45, 55),
		Accent = Color3.fromRGB(255, 105, 180),
		Text = Color3.fromRGB(240, 240, 240),
		TextDark = Color3.fromRGB(160, 160, 170)
	},
	Sizes = {
		["Medium"] = Vector2.new(520, 320)
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
	-- FLOATING TOGGLE BUTTON
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
	-- TAB SYSTEM
	---------------------------------------------------------------------
	local Window = { Tabs = {}, ActiveTab = nil }

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
		Page.Visible = false
		Page.Parent = ContentContainer

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.Padding = UDim.new(0, 6)
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Parent = Page

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingTop = UDim.new(0, 4)
		PagePadding.PaddingBottom = UDim.new(0, 14)
		PagePadding.PaddingRight = UDim.new(0, 6)
		PagePadding.Parent = Page

		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end)

		local function activateTab()
			for _, tab in pairs(Window.Tabs) do
				tab.Page.Visible = false
				TweenService:Create(tab.Button, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(25, 25, 30),
					TextColor3 = SyruLib.Theme.TextDark
				}):Play()
			end
			Page.Visible = true
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
			TweenService:Create(TabButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(35, 35, 42),
				TextColor3 = accentColor
			}):Play()
			Window.ActiveTab = Page
		end

		TabButton.MouseButton1Click:Connect(activateTab)
		table.insert(Window.Tabs, { Button = TabButton, Page = Page })

		if #Window.Tabs == 1 then activateTab() end

		local Elements = {}
		local elementOrder = 0

		local function nextOrder()
			elementOrder = elementOrder + 1
			return elementOrder
		end

		function Elements:AddSection(text)
			local Section = Instance.new("Frame")
			Section.Size = UDim2.new(1, 0, 0, 20)
			Section.BackgroundTransparency = 1
			Section.LayoutOrder = nextOrder()
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
			Toggle.LayoutOrder = nextOrder()
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
			Label.Active = false
			Label.Parent = Toggle

			local Switch = Instance.new("Frame")
			Switch.Size = UDim2.new(0, 32, 0, 18)
			Switch.Position = UDim2.new(1, -40, 0.5, -9)
			Switch.BackgroundColor3 = state and accentColor or Color3.fromRGB(45, 45, 52)
			Switch.BorderSizePixel = 0
			Switch.Active = false
			Switch.Parent = Toggle

			local SwitchCorner = Instance.new("UICorner")
			SwitchCorner.CornerRadius = UDim.new(1, 0)
			SwitchCorner.Parent = Switch

			local Circle = Instance.new("Frame")
			Circle.Size = UDim2.new(0, 12, 0, 12)
			Circle.Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
			Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Circle.BorderSizePixel = 0
			Circle.Active = false
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

		return Elements
	end

	return Window
end

---------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------
local Window = SyruLib:CreateWindow({
	Title = "SYRU HUB",
	SubTitle = "Chicken Farm",
	Accent = Color3.fromRGB(255, 105, 180)
})

local FarmTab = Window:CreateTab("Farm")

---------------------------------------------------------------------
-- TAB: FARM AUTOMATION
---------------------------------------------------------------------
FarmTab:AddSection("Egg Harvesting")

local collectActive = false
local returnToStart = true

FarmTab:AddToggle("Auto Teleport Collect Eggs", false, function(state)
	collectActive = state

	if state then
		task.spawn(function()
			while collectActive do
				local root = getRoot()
				local eggs = eggsFolder:GetChildren()

				if root and #eggs > 0 then
					local savedOrigin = root.CFrame

					for i = 1, #eggs do
						if not collectActive then break end
						local egg = eggs[i]

						if egg and egg.Parent then
							local pos = egg:IsA("Model") and egg:GetPivot()
								or (egg:IsA("BasePart") and egg.CFrame)
								or (egg:FindFirstChildWhichIsA("BasePart") and egg:FindFirstChildWhichIsA("BasePart").CFrame)

							if pos then
								root.CFrame = pos + Vector3.new(0, 1.5, 0)
								root.AssemblyLinearVelocity = Vector3.zero
								task.wait(0.08)

								fireServer(remoteEvent, "Collect Egg", egg.Name)

								local t = 0
								while egg.Parent and t < 0.2 do
									task.wait(0.02)
									t = t + 0.02
								end
							end
						end
					end

					if returnToStart and root and collectActive then
						root.CFrame = savedOrigin
						root.AssemblyLinearVelocity = Vector3.zero
					end
				end

				task.wait(0.3)
			end
		end)
	end
end)

FarmTab:AddToggle("Return to Origin Spot", true, function(state)
	returnToStart = state
end)

FarmTab:AddSection("Breeding & Merging")

local mergeActive = false
FarmTab:AddToggle("Auto Merge", false, function(state)
	mergeActive = state
	if state then
		task.spawn(function()
			while mergeActive do
				pcall(function()
					invokeServer(remoteFunction, "Merge Chickens")
				end)
				task.wait(1.5)
			end
		end)
	end
end)

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

FarmTab:AddSection("Obby Rewards")

local obbyActive = false
FarmTab:AddToggle("Complete Obby", false, function(state)
	obbyActive = state
	if state then
		task.spawn(function()
			while obbyActive do
				local claimed = false

				pcall(function()
					local r1 = invokeServer(remoteFunction, "Claim Obby")
					if r1 ~= false and r1 ~= nil then claimed = true end
				end)

				if not claimed then
					pcall(function()
						local r2 = invokeServer(remoteFunction, "Claim Obby", 1)
						if r2 ~= false and r2 ~= nil then claimed = true end
					end)
				end

				local root = getRoot()
				if root and firetouchinterest then
					for _, obj in ipairs(Workspace:GetDescendants()) do
						if obj:IsA("BasePart") and (obj.Name:lower():find("finish") or obj.Name:lower():find("endpad") or obj.Name:lower():find("winpad")) then
							pcall(function()
								firetouchinterest(root, obj, 0)
								firetouchinterest(root, obj, 1)
								claimed = true
							end)
							break
						end
					end
				end

				if claimed then
					task.wait(60)
				else
					task.wait(10)
				end
			end
		end)
	end
end)

FarmTab:AddSection("Economy & Upgrades")

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

-- Upgraded to 0.1s delay
local upgradeActive = false
FarmTab:AddToggle("Auto Upgrade Level", false, function(state)
	upgradeActive = state
	if state then
		task.spawn(function()
			while upgradeActive do
				pcall(function()
					invokeServer(remoteFunction, "Upgrade Process Level")
				end)
				task.wait(0.1)
			end
		end)
	end
end)

-- Upgraded to 0.1s delay
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
				task.wait(0.1)
			end
		end)
	end
end)
