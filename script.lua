local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== Config =====
local VALID_KEYS = {"Free","BrayIsGay"}
local AIMBOT_KEYBIND = Enum.KeyCode.Q
local AIMBOT_SMOOTHNESS = 0.15
local AIMBOT_FOV = 250
local AIMBOT_WALL_CHECK = true

-- ===== Summer / Aloha palette =====
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
    DarkText = Color3.fromRGB(20, 55, 80),
    SubText = Color3.fromRGB(235, 245, 250),
    Danger = Color3.fromRGB(225, 80, 80),
    Good = Color3.fromRGB(90, 200, 120),
    Bad = Color3.fromRGB(230, 90, 90),
}

-- ScreenGui (shared)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- FOV Circle for Aimbot
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.fromOffset(AIMBOT_FOV * 2, AIMBOT_FOV * 2)
fovCircle.Position = UDim2.new(0.5, -AIMBOT_FOV, 0.5, -AIMBOT_FOV)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = screenGui

local fovCircleUI = Instance.new("UICorner")
fovCircleUI.CornerRadius = UDim.new(1, 0)
fovCircleUI.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = THEME.Accent
fovStroke.Thickness = 2
fovStroke.Transparency = 0.5
fovStroke.Parent = fovCircle

-- ===== Styling helpers =====
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function addGradient(parent, topColor, bottomColor, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(topColor, bottomColor)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
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

-- Hover/press color tweens for buttons
local function wireButtonTweens(btn, base, hover, down)
    local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = hover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = base}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = down}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = hover}):Play()
    end)
end

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

-- ===== Aimbot Functions =====
local aimbotActive = false
local aimbotTarget = nil

local function isVisible(targetPart)
    if not AIMBOT_WALL_CHECK then return true end
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = AIMBOT_FOV
    
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            local head = otherPlayer.Character:FindFirstChild("Head")
            local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and head and root then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance and isVisible(head) then
                        shortestDistance = distance
                        closestPlayer = otherPlayer
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function aimAt(target)
    if not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local targetPos = head.Position
    local currentCFrame = camera.CFrame
    local targetDirection = (targetPos - currentCFrame.Position).Unit
    
    local newCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + targetDirection)
    camera.CFrame = currentCFrame:Lerp(newCFrame, 1 - AIMBOT_SMOOTHNESS)
end

-- Aimbot loop
RunService.RenderStepped:Connect(function()
    if aimbotActive then
        if not aimbotTarget or not aimbotTarget.Character then
            aimbotTarget = getClosestPlayerToCursor()
        end
        
        if aimbotTarget and aimbotTarget.Character then
            local humanoid = aimbotTarget.Character:FindFirstChild("Humanoid")
            local head = aimbotTarget.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local screenPos = camera:WorldToViewportPoint(head.Position)
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                if distance > AIMBOT_FOV * 1.5 or not isVisible(head) then
                    aimbotTarget = getClosestPlayerToCursor()
                else
                    aimAt(aimbotTarget)
                end
            else
                aimbotTarget = getClosestPlayerToCursor()
            end
        end
        
        fovCircle.Visible = true
    else
        aimbotTarget = nil
        fovCircle.Visible = false
    end
end)

-- Keybind handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AIMBOT_KEYBIND then
        aimbotActive = not aimbotActive
    end
end)

-- ============================================================
-- MAIN FLING UI
-- ============================================================
local function buildMainUI()
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(400, 450)
    main.Position = UDim2.new(0.5, -200, 0.5, -225)
    main.BackgroundColor3 = THEME.SeaTop
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = screenGui
    addCorner(main, 10)
    addGradient(main, THEME.SeaTop, THEME.SeaBottom)
    addStroke(main, THEME.Sand, 1.5, 0.4)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = THEME.SunTop
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = main
    addCorner(titleBar, 10)
    addGradient(titleBar, THEME.SunTop, THEME.SunBottom)

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -52, 1, 0)
    titleText.Position = UDim2.fromOffset(12, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🌺 Aloha — Bray's Summer Lua 🌴"
    titleText.TextColor3 = THEME.Text
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 14
    titleText.Parent = titleBar

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.fromOffset(30, 30)
    closeButton.Position = UDim2.new(1, -36, 0.5, -15)
    closeButton.BackgroundColor3 = THEME.Danger
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 15
    closeButton.AutoButtonColor = true
    closeButton.Parent = titleBar
    addCorner(closeButton, 6)

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -50)
    content.Position = UDim2.fromOffset(12, 46)
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
        btn.BackgroundColor3 = THEME.Accent
        btn.Text = text
        btn.TextColor3 = THEME.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.AutoButtonColor = false
        btn.Parent = content
        addCorner(btn, 6)
        addStroke(btn, THEME.Sand, 1, 0.6)
        wireButtonTweens(btn, THEME.Accent, THEME.AccentHover, THEME.AccentDown)
        return btn
    end

    local offButton = makeButton("☀️ OFF", 1)
    local onButton = makeButton("🌊 ON", 2)
    local orbitButton = makeButton("🛰️ Orbit Nearest", 3)
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, 0, 0, 2)
    separator.LayoutOrder = 4
    separator.BackgroundColor3 = THEME.Sand
    separator.BackgroundTransparency = 0.5
    separator.BorderSizePixel = 0
    separator.Parent = content
    
    local aimbotLabel = Instance.new("TextLabel")
    aimbotLabel.Size = UDim2.new(1, 0, 0, 20)
    aimbotLabel.LayoutOrder = 5
    aimbotLabel.BackgroundTransparency = 1
    aimbotLabel.Text = "🎯 AIMBOT (Key: " .. tostring(AIMBOT_KEYBIND):gsub("Enum.KeyCode.", "") .. ")"
    aimbotLabel.TextColor3 = THEME.Text
    aimbotLabel.Font = Enum.Font.GothamBold
    aimbotLabel.TextSize = 14
    aimbotLabel.Parent = content
    
    local aimbotStatus = makeButton("🎯 Aimbot: OFF", 6)
    local aimbotSmoothLabel = Instance.new("TextLabel")
    aimbotSmoothLabel.Size = UDim2.new(1, 0, 0, 20)
    aimbotSmoothLabel.LayoutOrder = 7
    aimbotSmoothLabel.BackgroundTransparency = 1
    aimbotSmoothLabel.Text = "Smoothness: " .. tostring(AIMBOT_SMOOTHNESS)
    aimbotSmoothLabel.TextColor3 = THEME.SubText
    aimbotSmoothLabel.Font = Enum.Font.Gotham
    aimbotSmoothLabel.TextSize = 12
    aimbotSmoothLabel.Parent = content

    -- ===== Fling logic =====
    local savedCFrame = nil
    local flinging = false
    local LOOP_INTERVAL = 0.05 -- Faster loop for more aggressive flinging
    local MAX_VELOCITY = 9e18 -- Maximum velocity Roblox allows (close to math.huge)

    local function getRoot()
        local character = player.Character
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart")
    end

    local function flingOnce()
        local root = getRoot()
        if not root then return end
        -- Random direction with upward bias for maximum chaos
        local angle = math.random() * math.pi * 2
        local dir = Vector3.new(math.cos(angle), math.random() * 0.5 + 0.1, math.sin(angle)).Unit
        root.AssemblyLinearVelocity = dir * MAX_VELOCITY
        root.AssemblyAngularVelocity = Vector3.new(
            math.random(-MAX_VELOCITY, MAX_VELOCITY),
            math.random(-MAX_VELOCITY, MAX_VELOCITY),
            math.random(-MAX_VELOCITY, MAX_VELOCITY)
        )
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
            root.AssemblyAngularVelocity = Vector3.zero
            if savedCFrame then
                root.CFrame = savedCFrame
            end
        end
    end

    -- ===== Orbit logic =====
    local orbiting = false
    local orbitConn = nil
    local ORBIT_OFFSET = Vector3.new(5, 4, 8)
    local ORBIT_SPEED = 25
    local orbitAngle = 0

    local function getNearestRoot()
        local myRoot = getRoot()
        if not myRoot then return nil end

        local closest, closestDist = nil, math.huge
        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character then
                local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
                if oRoot then
                    local dist = (oRoot.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closest, closestDist = oRoot, dist
                    end
                end
            end
        end
        return closest
    end

    local function startOrbit()
        if orbiting then return end
        local root = getRoot()
        if not root then return end
        orbiting = true
        root.AssemblyLinearVelocity = Vector3.zero

        orbitConn = RunService.Heartbeat:Connect(function(dt)
            local myRoot = getRoot()
            local target = getNearestRoot()
            if not myRoot or not target then return end

            orbitAngle = orbitAngle + ORBIT_SPEED * dt
            local r = math.sqrt(ORBIT_OFFSET.X ^ 2 + ORBIT_OFFSET.Z ^ 2)
            local offsetX = math.cos(orbitAngle) * r
            local offsetZ = math.sin(orbitAngle) * r
            local offset = Vector3.new(offsetX, ORBIT_OFFSET.Y, offsetZ)

            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.CFrame = CFrame.lookAt(target.Position + offset, target.Position)
        end)
    end

    local function stopOrbit()
        orbiting = false
        if orbitConn then
            orbitConn:Disconnect()
            orbitConn = nil
        end
        local root = getRoot()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end

    -- ===== Button wiring =====
    offButton.MouseButton1Click:Connect(function()
        stopFling()
    end)

    onButton.MouseButton1Click:Connect(function()
        stopOrbit()
        startFling()
    end)

    orbitButton.MouseButton1Click:Connect(function()
        if orbiting then
            stopOrbit()
            orbitButton.Text = "🛰️ Orbit Nearest"
        else
            stopFling()
            startOrbit()
            orbitButton.Text = "🛰️ Orbiting… (click to stop)"
        end
    end)
    
    aimbotStatus.MouseButton1Click:Connect(function()
        aimbotActive = not aimbotActive
        if aimbotActive then
            aimbotStatus.Text = "🎯 Aimbot: ON (Glue Mode)"
            fovCircle.Visible = true
        else
            aimbotStatus.Text = "🎯 Aimbot: OFF"
            fovCircle.Visible = false
            aimbotTarget = nil
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        stopFling()
        stopOrbit()
        aimbotActive = false
        fovCircle.Visible = false
        main.Visible = false
    end)

    makeDraggable(main, titleBar)

    return main
end

-- ============================================================
-- KEY SYSTEM UI
-- ============================================================
local function buildKeyUI(onValid)
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.fromOffset(340, 220)
    keyFrame.Position = UDim2.new(0.5, -170, 0.5, -110)
    keyFrame.BackgroundColor3 = THEME.SeaTop
    keyFrame.BorderSizePixel = 0
    keyFrame.Active = true
    keyFrame.Parent = screenGui
    addCorner(keyFrame, 10)
    addGradient(keyFrame, THEME.SeaTop, THEME.SeaBottom)
    addStroke(keyFrame, THEME.Sand, 1.5, 0.4)

    -- Title bar
    local keyBar = Instance.new("Frame")
    keyBar.Size = UDim2.new(1, 0, 0, 38)
    keyBar.BackgroundColor3 = THEME.SunTop
    keyBar.BorderSizePixel = 0
    keyBar.Active = true
    keyBar.Parent = keyFrame
    addCorner(keyBar, 10)
    addGradient(keyBar, THEME.SunTop, THEME.SunBottom)

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -52, 1, 0)
    keyTitle.Position = UDim2.fromOffset(12, 0)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "🔑 Key:discord.gg/nQ6wthsQeV"
    keyTitle.TextColor3 = THEME.Text
    keyTitle.TextXAlignment = Enum.TextXAlignment.Left
    keyTitle.Font = Enum.Font.GothamBold
    keyTitle.TextSize = 16
    keyTitle.Parent = keyBar

    -- Close (X) button for key system
    local keyCloseButton = Instance.new("TextButton")
    keyCloseButton.Name = "KeyCloseButton"
    keyCloseButton.Size = UDim2.fromOffset(30, 30)
    keyCloseButton.Position = UDim2.new(1, -36, 0.5, -15)
    keyCloseButton.BackgroundColor3 = THEME.Danger
    keyCloseButton.Text = "X"
    keyCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyCloseButton.Font = Enum.Font.GothamBold
    keyCloseButton.TextSize = 15
    keyCloseButton.AutoButtonColor = true
    keyCloseButton.Parent = keyBar
    addCorner(keyCloseButton, 6)

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -24, 0, 38)
    keyBox.Position = UDim2.fromOffset(12, 54)
    keyBox.BackgroundColor3 = THEME.Field
    keyBox.PlaceholderText = "Paste your key here…"
    keyBox.Text = ""
    keyBox.TextColor3 = THEME.DarkText
    keyBox.PlaceholderColor3 = THEME.SubText
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = keyFrame
    addCorner(keyBox, 6)
    addStroke(keyBox, THEME.Sand, 1, 0.6)
    
    local keysHint = Instance.new("TextLabel")
    keysHint.Size = UDim2.new(1, -24, 0, 20)
    keysHint.Position = UDim2.fromOffset(12, 96)
    keysHint.BackgroundTransparency = 1
    keysHint.Text = "Valid keys: " .. table.concat(VALID_KEYS, ", ")
    keysHint.TextColor3 = THEME.SubText
    keysHint.Font = Enum.Font.Gotham
    keysHint.TextSize = 11
    keysHint.TextXAlignment = Enum.TextXAlignment.Left
    keysHint.Parent = keyFrame

    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(1, -24, 0, 38)
    submit.Position = UDim2.fromOffset(12, 122)
    submit.BackgroundColor3 = THEME.Accent
    submit.Text = "🌊 Submit"
    submit.TextColor3 = THEME.Text
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 15
    submit.AutoButtonColor = false
    submit.Parent = keyFrame
    addCorner(submit, 6)
    addStroke(submit, THEME.Sand, 1, 0.6)
    wireButtonTweens(submit, THEME.Accent, THEME.AccentHover, THEME.AccentDown)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 18)
    status.Position = UDim2.fromOffset(12, 166)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = THEME.Bad
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = keyFrame

    submit.MouseButton1Click:Connect(function()
        local enteredKey = keyBox.Text:gsub("^%s*(.-)%s*$", "%1")
        local isValid = false
        
        for _, validKey in ipairs(VALID_KEYS) do
            if enteredKey == validKey then
                isValid = true
                break
            end
        end
        
        if isValid then
            status.TextColor3 = THEME.Good
            status.Text = "✅ Valid key — loading…"
            task.wait(0.4)
            keyFrame:Destroy()
            if onValid then onValid() end
        else
            status.TextColor3 = THEME.Bad
            status.Text = "❌ Invalid key, try again."
        end
    end)

    keyCloseButton.MouseButton1Click:Connect(function()
        keyFrame:Destroy()
    end)

    makeDraggable(keyFrame, keyBar)
    return keyFrame
end

-- ============================================================
-- BOOT
-- ============================================================
buildKeyUI(function()
    buildMainUI()
end)
