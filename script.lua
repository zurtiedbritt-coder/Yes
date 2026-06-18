local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ===== Config =====
local VALID_KEY = "Free"

-- ScreenGui (shared)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ===== Reusable drag helper =====
local function makeDraggable(frame, dragHandle)
	local dragging, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ============================================================
-- MAIN FLING UI
-- ============================================================
local function buildMainUI()
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(400, 280)
	main.Position = UDim2.new(0.5, -200, 0.5, -140)
	main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	main.BorderSizePixel = 0
	main.Active = true
	main.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = main

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	titleBar.BorderSizePixel = 0
	titleBar.Active = true
	titleBar.Parent = main

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, -52, 1, 0)
	titleText.Position = UDim2.fromOffset(12, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "newsupraaa's paid lua"
	titleText.TextColor3 = Color3.fromRGB(235, 235, 240)
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Font = Enum.Font.GothamMedium
	titleText.TextSize = 16
	titleText.Parent = titleBar

	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.fromOffset(28, 28)
	closeButton.Position = UDim2.new(1, -32, 0.5, -14)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 15
	closeButton.AutoButtonColor = true
	closeButton.Parent = titleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -48)
	content.Position = UDim2.fromOffset(12, 44)
	content.BackgroundTransparency = 1
	content.Parent = main

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	local function makeButton(text, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 38)
		btn.LayoutOrder = order
		btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
		btn.Text = text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 15
		btn.AutoButtonColor = true
		btn.Parent = content

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		return btn
	end

	local offButton = makeButton("OFF", 1)
	local onButton = makeButton("ON", 2)

	-- ===== Fling logic =====
	local savedCFrame = nil
	local flinging = false
	local LOOP_INTERVAL = 0.1
	local MAX_SAFE_VELOCITY = 1e8

	local function getRoot()
		local character = player.Character
		if not character then return nil end
		return character:FindFirstChild("HumanoidRootPart")
	end

	local function flingOnce()
		local root = getRoot()
		if not root then return end
		local angle = math.random() * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0.2, math.sin(angle)).Unit
		root.AssemblyLinearVelocity = dir * MAX_SAFE_VELOCITY
	end

	local function startFling()
		if flinging then return end
		local root = getRoot()
		if not root then return end
		flinging = true
		savedCFrame = root.CFrame
		task.spawn(function()
			while flinging do
				flingOnce()
				task.wait(LOOP_INTERVAL)
			end
		end)
	end

	local function stopFling()
		flinging = false
		local root = getRoot()
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			if savedCFrame then
				root.CFrame = savedCFrame
			end
		end
	end

	onButton.MouseButton1Click:Connect(startFling)
	offButton.MouseButton1Click:Connect(stopFling)
	closeButton.MouseButton1Click:Connect(function()
		stopFling()
		screenGui:Destroy()
	end)

	makeDraggable(main, titleBar)
end

-- ============================================================
-- KEY SYSTEM
-- ============================================================
local function buildKeyUI()
	local keyFrame = Instance.new("Frame")
	keyFrame.Name = "KeyFrame"
	keyFrame.Size = UDim2.fromOffset(360, 200)
	keyFrame.Position = UDim2.new(0.5, -180, 0.5, -100)
	keyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	keyFrame.BorderSizePixel = 0
	keyFrame.Active = true
	keyFrame.Parent = screenGui

	local kCorner = Instance.new("UICorner")
	kCorner.CornerRadius = UDim.new(0, 8)
	kCorner.Parent = keyFrame

	local kBar = Instance.new("Frame")
	kBar.Size = UDim2.new(1, 0, 0, 36)
	kBar.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	kBar.BorderSizePixel = 0
	kBar.Active = true
	kBar.Parent = keyFrame

	local kBarCorner = Instance.new("UICorner")
	kBarCorner.CornerRadius = UDim.new(0, 8)
	kBarCorner.Parent = kBar

	local kTitle = Instance.new("TextLabel")
	kTitle.Size = UDim2.new(1, -24, 1, 0)
	kTitle.Position = UDim2.fromOffset(12, 0)
	kTitle.BackgroundTransparency = 1
	kTitle.Text = "Key System"
	kTitle.TextColor3 = Color3.fromRGB(235, 235, 240)
	kTitle.TextXAlignment = Enum.TextXAlignment.Left
	kTitle.Font = Enum.Font.GothamMedium
	kTitle.TextSize = 16
	kTitle.Parent = kBar

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -24, 0, 24)
	status.Position = UDim2.fromOffset(12, 46)
	status.BackgroundTransparency = 1
	status.Text = "Enter your key to continue"
	status.TextColor3 = Color3.fromRGB(200, 200, 210)
	status.Font = Enum.Font.Gotham
	status.TextSize = 14
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = keyFrame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -24, 0, 38)
	box.Position = UDim2.fromOffset(12, 78)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	box.PlaceholderText = "Paste key here..."
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
	box.Font = Enum.Font.Gotham
	box.TextSize = 15
	box.ClearTextOnFocus = false
	box.Parent = keyFrame

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 6)
	boxCorner.Parent = box

	local submit = Instance.new("TextButton")
	submit.Size = UDim2.new(1, -24, 0, 38)
	submit.Position = UDim2.fromOffset(12, 126)
	submit.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	submit.Text = "Submit Key"
	submit.TextColor3 = Color3.fromRGB(255, 255, 255)
	submit.Font = Enum.Font.GothamMedium
	submit.TextSize = 15
	submit.AutoButtonColor = true
	submit.Parent = keyFrame

	local submitCorner = Instance.new("UICorner")
	submitCorner.CornerRadius = UDim.new(0, 6)
	submitCorner.Parent = submit

	local function checkKey()
		if box.Text == VALID_KEY then
			status.Text = "Correct! Loading..."
			status.TextColor3 = Color3.fromRGB(120, 220, 120)
			task.wait(0.4)
			keyFrame:Destroy()
			buildMainUI()
		else
			status.Text = "Invalid key, try again"
			status.TextColor3 = Color3.fromRGB(220, 90, 90)
		end
	end

	submit.MouseButton1Click:Connect(checkKey)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then checkKey() end
	end)

	makeDraggable(keyFrame, kBar)
end

-- ============================================================
-- START
-- ============================================================
buildKeyUI()
