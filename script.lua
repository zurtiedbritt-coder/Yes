local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local player = Players.LocalPlayer

local THEME = {
    SunTop = Color3.fromRGB(255, 170, 60),
    SunBottom = Color3.fromRGB(255, 120, 40),
    SeaTop = Color3.fromRGB(60, 170, 220),
    SeaBottom = Color3.fromRGB(30, 110, 180),
    Sand = Color3.fromRGB(250, 240, 215),
    Accent = Color3.fromRGB(255, 140, 50),
    AccentHover = Color3.fromRGB(255, 165, 80),
    AccentDown = Color3.fromRGB(225, 110, 30),
    Field = Color3.fromRGB(235, 248, 255),
    Text = Color3.fromRGB(255, 255, 255),
    Danger = Color3.fromRGB(225, 80, 80),
    Good = Color3.fromRGB(90, 200, 120),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local MY_GROUP = "MyPlayerGroup"
local OTHERS_GROUP = "OthersGroup"
pcall(function()
    PhysicsService:CreateCollisionGroup(MY_GROUP)
    PhysicsService:CreateCollisionGroup(OTHERS_GROUP)
end)
PhysicsService:CollisionGroupSetCollidable(MY_GROUP, OTHERS_GROUP, false)

local function setupCollisionFiltering()
    local character = player.Character
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, MY_GROUP)
        end
    end

    for _, other in ipairs(Players:GetPlayers()) do
        if other == player or not other.Character then continue end
        local char = other.Character
        local isExploiter = char:GetAttribute("KiciaHook") or char:GetAttribute("Unnamed") or char:GetAttribute("Kiciaczek") or char:GetAttribute("Hook") or
                           char:FindFirstChild("KiciaHook") or char:FindFirstChild("Unnamed") or char:FindFirstChild("UnnamedESP") or char:FindFirstChild("Kicia") or
                           (char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid"):GetAttribute("Kicia")) or
                           other:GetAttribute("UsingKicia") or other:GetAttribute("UsingUnnamed")

        if isExploiter then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    PhysicsService:SetPartCollisionGroup(part, OTHERS_GROUP)
                end
            end
        end
    end
end

player.CharacterAdded:Connect(function() task.wait(0.5) setupCollisionFiltering() end)
if player.Character then task.spawn(setupCollisionFiltering) end
Players.PlayerAdded:Connect(function(other)
    other.CharacterAdded:Connect(function() task.wait(1) setupCollisionFiltering() end)
end)

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Sand
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function wireButtonTweens(btn, base, hover, down)
    local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, info, {BackgroundColor3 = hover}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, info, {BackgroundColor3 = base}):Play() end)
    btn.MouseButton1Down:Connect(function() TweenService:Create(btn, info, {BackgroundColor3 = down}):Play() end)
    btn.MouseButton1Up:Connect(function() TweenService:Create(btn, info, {BackgroundColor3 = hover}):Play() end)
end

local function makeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main UI
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(400, 380)
main.Position = UDim2.new(0.5, -200, 0.5, -190)
main.BackgroundColor3 = THEME.Field
main.BorderSizePixel = 0
main.Parent = screenGui
addCorner(main, 12)
addStroke(main, THEME.Sand, 1, 0.3)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = THEME.SunTop
titleBar.BorderSizePixel = 0
titleBar.Parent = main
addCorner(titleBar, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Rivals Cheat"
title.TextColor3 = THEME.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(30, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.Danger
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

makeDraggable(main, titleBar)

local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, -20, 0, 40)
tabHolder.Position = UDim2.new(0, 10, 0, 50)
tabHolder.BackgroundTransparency = 1
tabHolder.Parent = main

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -20, 1, -100)
contentHolder.Position = UDim2.new(0, 10, 0, 100)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = main

local tabs = {}
local currentTab

local function createTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 90, 1, 0)
    tabBtn.BackgroundColor3 = THEME.SeaBottom
    tabBtn.Text = icon .. " " .. name
    tabBtn.TextColor3 = THEME.Text
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 14
    tabBtn.Parent = tabHolder
    addCorner(tabBtn, 8)
    addStroke(tabBtn, THEME.Accent, 1)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = THEME.Accent
    content.Visible = false
    content.Parent = contentHolder

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = content

    table.insert(tabs, {btn = tabBtn, content = content})

    tabBtn.MouseButton1Click:Connect(function()
        if currentTab then currentTab.content.Visible = false end
        content.Visible = true
        currentTab = {btn = tabBtn, content = content}
    end)
    return content
end

local combatTab = createTab("Combat", "⚔")
local visualsTab = createTab("Visuals", "👁")
local miscTab = createTab("Misc", "⚙")

if tabs[1] then
    tabs[1].content.Visible = true
    currentTab = tabs[1]
end

-- VoidSpam
local voidSpamEnabled = false
local voidSpamConn = nil

local function startVoidSpam()
    if voidSpamConn then return end
    voidSpamConn = RunService.Heartbeat:Connect(function()
        if not voidSpamEnabled then return end
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or (hum and hum.Health <= 0) then return end

        pcall(function()
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    tool:Activate()
                end
            end
            if math.random(1,3) == 1 then
                root.CFrame = root.CFrame * CFrame.new(0,0,-0.4) * CFrame.Angles(0, math.rad(math.random(-12,12)), 0)
            end
        end)
    end)
end

local function stopVoidSpam()
    if voidSpamConn then
        voidSpamConn:Disconnect()
        voidSpamConn = nil
    end
end

local voidBtn = Instance.new("TextButton")
voidBtn.Size = UDim2.new(1,-10,0,45)
voidBtn.BackgroundColor3 = THEME.SeaTop
voidBtn.Text = "VoidSpam: OFF\nL | luaaa"
voidBtn.TextColor3 = THEME.Text
voidBtn.Font = Enum.Font.GothamBold
voidBtn.TextSize = 15
voidBtn.Parent = miscTab
addCorner(voidBtn,8)
wireButtonTweens(voidBtn, THEME.SeaTop, THEME.AccentHover, THEME.AccentDown)

voidBtn.MouseButton1Click:Connect(function()
    voidSpamEnabled = not voidSpamEnabled
    if voidSpamEnabled then
        voidBtn.Text = "VoidSpam: ON\nL | luaaa"
        voidBtn.BackgroundColor3 = THEME.Good
        startVoidSpam()
    else
        voidBtn.Text = "VoidSpam: OFF\nL | luaaa"
        voidBtn.BackgroundColor3 = THEME.SeaTop
        stopVoidSpam()
    end
end)

UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.L then
        voidSpamEnabled = not voidSpamEnabled
        if voidSpamEnabled then
            voidBtn.Text = "VoidSpam: ON\nL | luaaa"
            voidBtn.BackgroundColor3 = THEME.Good
            startVoidSpam()
        else
            voidBtn.Text = "VoidSpam: OFF\nL | luaaa"
            voidBtn.BackgroundColor3 = THEME.SeaTop
            stopVoidSpam()
        end
    end
end)

player.Chatted:Connect(function(msg)
    if msg:lower() == "luaaa" then
        voidSpamEnabled = not voidSpamEnabled
        if voidSpamEnabled then
            voidBtn.Text = "VoidSpam: ON\nL | luaaa"
            voidBtn.BackgroundColor3 = THEME.Good
            startVoidSpam()
        else
            voidBtn.Text = "VoidSpam: OFF\nL | luaaa"
            voidBtn.BackgroundColor3 = THEME.SeaTop
            stopVoidSpam()
        end
    end
end)

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if voidSpamEnabled then
        stopVoidSpam()
        startVoidSpam()
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

print("Loaded")
