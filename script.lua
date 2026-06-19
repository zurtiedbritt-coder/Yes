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

-- ===== Beach / Tides Palette =====
local THEME = {
    OceanDeep = Color3.fromRGB(0, 105, 148),
    OceanMid = Color3.fromRGB(0, 150, 199),
    OceanShallow = Color3.fromRGB(72, 202, 228),
    SandLight = Color3.fromRGB(255, 245, 220),
    SandDark = Color3.fromRGB(238, 214, 175),
    PalmGreen = Color3.fromRGB(34, 139, 34),
    PalmDark = Color3.fromRGB(0, 100, 0),
    SkyBlue = Color3.fromRGB(135, 206, 235),
    SunGold = Color3.fromRGB(255, 215, 0),
    Coral = Color3.fromRGB(255, 127, 80),
    White = Color3.fromRGB(255, 255, 255),
    Danger = Color3.fromRGB(220, 60, 60),
    Good = Color3.fromRGB(50, 205, 50),
    Bad = Color3.fromRGB(220, 80, 80),
}

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TidesUI"
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
fovStroke.Color = THEME.Coral
fovStroke.Thickness = 3
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

-- ===== Styling helpers =====
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function addGradient(parent, color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.SandLight
    s.Thickness = thickness or 2
    s.Transparency = 0.3
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function addShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
end

-- Hover/press animations
local function wireButtonTweens(btn, base, hover, down)
    local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = hover, Size = UDim2.new(1, 4, 0, 42)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = base, Size = UDim2.new(1, 0, 0, 38)}):Play()
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = down, Size = UDim2.new(1, -2, 0, 36)}):Play()
    end)
    
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, info, {BackgroundColor3 = hover, Size = UDim2.new(1, 4, 0, 40)}):Play()
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
-- TIDES LUA EXECUTOR
-- ============================================================
local tidesExecutor = nil

local function createTidesExecutor()
    if tidesExecutor then tidesExecutor:Destroy() end
    
    local executor = Instance.new("Frame")
    executor.Name = "TidesExecutor"
    executor.Size = UDim2.fromOffset(500, 350)
    executor.Position = UDim2.new(0.5, -250, 0.5, -175)
    executor.BackgroundColor3 = THEME.OceanMid
    executor.BorderSizePixel = 0
    executor.Active = true
    executor.ZIndex = 100
    executor.Parent = screenGui
    
    addCorner(executor, 15)
    addStroke(executor, THEME.SandLight, 3)
    addShadow(executor)
    
    -- Animated gradient background
    local animGradient = Instance.new("UIGradient")
    animGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.OceanDeep),
        ColorSequenceKeypoint.new(0.5, THEME.OceanMid),
        ColorSequenceKeypoint.new(1, THEME.OceanShallow)
    })
    animGradient.Rotation = 45
    animGradient.Parent = executor
    
    -- Animate gradient
    task.spawn(function()
        while executor and executor.Parent do
            TweenService:Create(animGradient, TweenInfo.new(3, Enum.EasingStyle.Linear), {
                Rotation = animGradient.Rotation + 180
            }):Play()
            task.wait(3)
        end
    end)
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = THEME.SandLight
    titleBar.BorderSizePixel = 0
    titleBar.Parent = executor
    addCorner(titleBar, 15)
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.fromOffset(15, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🌊 Tides Lua Executor"
    titleText.TextColor3 = THEME.OceanDeep
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.Parent = titleBar
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -16)
    closeBtn.BackgroundColor3 = THEME.Danger
    closeBtn.Text = "X"
    closeBtn.TextColor3 = THEME.White
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    addCorner(closeBtn, 8)
    
    closeBtn.MouseButton1Click:Connect(function()
        executor:Destroy()
        tidesExecutor = nil
    end)
    
    -- Code editor
    local editorFrame = Instance.new("Frame")
    editorFrame.Size = UDim2.new(1, -30, 0, 220)
    editorFrame.Position = UDim2.fromOffset(15, 57)
    editorFrame.BackgroundColor3 = THEME.OceanDeep
    editorFrame.BorderSizePixel = 0
    editorFrame.Parent = executor
    addCorner(editorFrame, 10)
    addStroke(editorFrame, THEME.SandLight, 1)
    
    local codeBox = Instance.new("TextBox")
    codeBox.Name = "CodeBox"
    codeBox.Size = UDim2.new(1, -20, 1, -20)
    codeBox.Position = UDim2.fromOffset(10, 10)
    codeBox.BackgroundTransparency = 1
    codeBox.Text = "-- 🌊 Welcome to Tides Lua Executor\n-- Paste your script here..."
    codeBox.TextColor3 = THEME.White
    codeBox.PlaceholderText = "-- Enter Lua code here..."
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 13
    codeBox.ClearTextOnFocus = false
    codeBox.MultiLine = true
    codeBox.TextWrapped = true
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.Parent = editorFrame
    
    -- Execute button
    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(0.48, 0, 0, 40)
    execBtn.Position = UDim2.fromOffset(15, 290)
    execBtn.BackgroundColor3 = THEME.PalmGreen
    execBtn.Text = "🌊 Execute"
    execBtn.TextColor3 = THEME.White
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 16
    execBtn.Parent = executor
    addCorner(execBtn, 10)
    wireButtonTweens(execBtn, THEME.PalmGreen, Color3.fromRGB(50, 180, 50), THEME.PalmDark)
    
    -- Clear button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.48, 0, 0, 40)
    clearBtn.Position = UDim2.new(0.52, 0, 0, 290)
    clearBtn.BackgroundColor3 = THEME.Coral
    clearBtn.Text = "🏖️ Clear"
    clearBtn.TextColor3 = THEME.White
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 16
    clearBtn.Parent = executor
    addCorner(clearBtn, 10)
    wireButtonTweens(clearBtn, THEME.Coral, Color3.fromRGB(255, 150, 100), Color3.fromRGB(200, 100, 60))
    
    execBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        if code and code ~= "" then
            local success, err = pcall(function()
                loadstring(code)()
            end)
            if not success then
                warn("Tides Error: " .. tostring(err))
            end
        end
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        codeBox.Text = ""
    end)
    
    makeDraggable(executor, titleBar)
    tidesExecutor = executor
    return executor
end

-- ============================================================
-- MAIN TIDES UI
-- ============================================================
local function buildMainUI()
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(420, 520)
    main.Position = UDim2.new(0.5, -210, 0.5, -260)
    main.BackgroundColor3 = THEME.SandLight
    main.BorderSizePixel = 0
    main.Active = true
    main.ClipsDescendants = true
    main.Parent = screenGui
    
    addCorner(main, 20)
    addStroke(main, THEME.OceanShallow, 4)
    addShadow(main)
    
    -- Ocean header background
    local oceanHeader = Instance.new("Frame")
    oceanHeader.Size = UDim2.new(1, 0, 0, 100)
    oceanHeader.BackgroundColor3 = THEME.OceanMid
    oceanHeader.BorderSizePixel = 0
    oceanHeader.Parent = main
    
    local oceanGradient = Instance.new("UIGradient")
    oceanGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, THEME.OceanShallow),
        ColorSequenceKeypoint.new(1, THEME.OceanDeep)
    })
    oceanGradient.Rotation = 180
    oceanGradient.Parent = oceanHeader
    
    addCorner(oceanHeader, 20)
    
    -- Wave decoration
    local wave = Instance.new("Frame")
    wave.Size = UDim2.new(1, 0, 0, 25)
    wave.Position = UDim2.new(0, 0, 1, -12)
    wave.BackgroundColor3 = THEME.SandLight
    wave.BorderSizePixel = 0
    wave.Parent = oceanHeader
    
    local waveCorner = Instance.new("UICorner")
    waveCorner.CornerRadius = UDim.new(1, 0)
    waveCorner.Parent = wave
    
    -- Title (inside ocean header)
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 0, 30)
    titleText.Position = UDim2.fromOffset(20, 15)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🏝️ Tides Beach"
    titleText.TextColor3 = THEME.White
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 20
    titleText.Parent = oceanHeader
    
    -- Discord text
    local discordText = Instance.new("TextLabel")
    discordText.Size = UDim2.new(1, -80, 0, 20)
    discordText.Position = UDim2.fromOffset(20, 48)
    discordText.BackgroundTransparency = 1
    discordText.Text = "discord.gg/nQ6wthsQeV"
    discordText.TextColor3 = THEME.SandLight
    discordText.TextXAlignment = Enum.TextXAlignment.Left
    discordText.Font = Enum.Font.Gotham
    discordText.TextSize = 12
    discordText.Parent = oceanHeader

    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.fromOffset(35, 35)
    closeButton.Position = UDim2.new(1, -50, 0, 15)
    closeButton.BackgroundColor3 = THEME.Danger
    closeButton.Text = "X"
    closeButton.TextColor3 = THEME.White
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = oceanHeader
    addCorner(closeButton, 10)

    -- Draggable area
    local dragArea = Instance.new("Frame")
    dragArea.Size = UDim2.new(1, 0, 0, 100)
    dragArea.BackgroundTransparency = 1
    dragArea.Parent = main

    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -120)
    content.Position = UDim2.fromOffset(20, 110)
    content.BackgroundTransparency = 1
    content.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local function makeButton(text, order, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 42)
        btn.LayoutOrder = order
        btn.BackgroundColor3 = color or THEME.OceanMid
        btn.Text = text
        btn.TextColor3 = THEME.White
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.AutoButtonColor = false
        btn.Parent = content
        addCorner(btn, 10)
        addStroke(btn, THEME.SandLight, 2)
        
        local hoverColor = color and color:Lerp(Color3.fromRGB(255,255,255), 0.2) or THEME.OceanShallow
        local downColor = color and color:Lerp(Color3.fromRGB(0,0,0), 0.2) or THEME.OceanDeep
        wireButtonTweens(btn, color or THEME.OceanMid, hoverColor, downColor)
        return btn
    end

    -- 🌊 TIDES LUA EXECUTOR BUTTON (Featured at top)
    local tidesBtn = makeButton("🌊 Tides Lua Executor", 0, THEME.PalmGreen)
    tidesBtn.Size = UDim2.new(1, 0, 0, 50)
    tidesBtn.TextSize = 17
    
    -- Separator
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, 0, 0, 2)
    separator.LayoutOrder = 1
    separator.BackgroundColor3 = THEME.OceanShallow
    separator.BackgroundTransparency = 0.5
    separator.BorderSizePixel = 0
    separator.Parent = content

    -- Fling controls
    local flingLabel = Instance.new("TextLabel")
    flingLabel.Size = UDim2.new(1, 0, 0, 20)
    flingLabel.LayoutOrder = 2
    flingLabel.BackgroundTransparency = 1
    flingLabel.Text = "🏄 FLING CONTROLS"
    flingLabel.TextColor3 = THEME.OceanDeep
    flingLabel.Font = Enum.Font.GothamBold
    flingLabel.TextSize = 13
    flingLabel.Parent = content

    local offButton = makeButton("🏖️ FLING OFF", 3, THEME.Coral)
    local onButton = makeButton("🌴 FLING ON", 4, THEME.PalmGreen)
    local orbitButton = makeButton("🐚 Orbit Nearest", 5, THEME.OceanMid)
    
    -- Separator
    local separator2 = Instance.new("Frame")
    separator2.Size = UDim2.new(1, 0, 0, 2)
    separator2.LayoutOrder = 6
    separator2.BackgroundColor3 = THEME.OceanShallow
    separator2.BackgroundTransparency = 0.5
    separator2.BorderSizePixel = 0
    separator2.Parent = content
    
    -- Aimbot section
    local aimbotLabel = Instance.new("TextLabel")
    aimbotLabel.Size = UDim2.new(1, 0, 0, 20)
    aimbotLabel.LayoutOrder = 7
    aimbotLabel.BackgroundTransparency = 1
    aimbotLabel.Text = "🎯 AIMBOT (Key: " .. tostring(AIMBOT_KEYBIND):gsub("Enum.KeyCode.", "") .. ")"
    aimbotLabel.TextColor3 = THEME.OceanDeep
    aimbotLabel.Font = Enum.Font.GothamBold
    aimbotLabel.TextSize = 13
    aimbotLabel.Parent = content
    
    local aimbotStatus = makeButton("🎯 Aimbot: OFF", 8, THEME.OceanMid)
    
    local smoothnessLabel = Instance.new("TextLabel")
    smoothnessLabel.Size = UDim2.new(1, 0, 0, 18)
    smoothnessLabel.LayoutOrder = 9
    smoothnessLabel.BackgroundTransparency = 1
    smoothnessLabel.Text = "Smoothness: " .. tostring(AIMBOT_SMOOTHNESS) .. " | Lower = Stickier"
    smoothnessLabel.TextColor3 = THEME.OceanMid
    smoothnessLabel.Font = Enum.Font.Gotham
    smoothnessLabel.TextSize = 11
    smoothnessLabel.Parent = content

    -- ===== Fling logic =====
    local savedCFrame = nil
    local flinging = false
    local LOOP_INTERVAL = 0.03
    local MAX_VELOCITY = 9e18

    local function getRoot()
        local character = player.Character
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart")
    end

    local function flingOnce()
        local root = getRoot()
        if not root then return end
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
    tidesBtn.MouseButton1Click:Connect(function()
        createTidesExecutor()
    end)
    
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
            orbitButton.Text = "🐚 Orbit Nearest"
        else
            stopFling()
            startOrbit()
            orbitButton.Text = "🐚 Orbiting… (click to stop)"
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

    makeDraggable(main, dragArea)

    return main
end

-- ============================================================
-- KEY SYSTEM UI
-- ============================================================
local function buildKeyUI(onValid)
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.fromOffset(360, 240)
    keyFrame.Position = UDim2.new(0.5, -180, 0.5, -120)
    keyFrame.BackgroundColor3 = THEME.SandLight
    keyFrame.BorderSizePixel = 0
    keyFrame.Active = true
    keyFrame.Parent = screenGui
    
    addCorner(keyFrame, 20)
    addStroke(keyFrame, THEME.OceanShallow, 4)
    addShadow(keyFrame)

    -- Ocean header
    local oceanHeader = Instance.new("Frame")
    oceanHeader.Size = UDim2.new(1, 0, 0, 60)
    oceanHeader.BackgroundColor3 = THEME.OceanMid
    oceanHeader.BorderSizePixel = 0
    oceanHeader.Parent = keyFrame
    addCorner(oceanHeader, 20)
    
    local headerGradient = Instance.new("UIGradient")
    headerGradient.Color = ColorSequence.new(THEME.OceanShallow, THEME.OceanDeep)
    headerGradient.Rotation = 180
    headerGradient.Parent = oceanHeader

    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -60, 1, 0)
    keyTitle.Position = UDim2.fromOffset(20, 0)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "🌊 Tides Access"
    keyTitle.TextColor3 = THEME.White
    keyTitle.TextXAlignment = Enum.TextXAlignment.Left
    keyTitle.Font = Enum.Font.GothamBold
    keyTitle.TextSize = 22
    keyTitle.Parent = oceanHeader

    -- Close (X) button for key system
    local keyCloseButton = Instance.new("TextButton")
    keyCloseButton.Name = "KeyCloseButton"
    keyCloseButton.Size = UDim2.fromOffset(35, 35)
    keyCloseButton.Position = UDim2.new(1, -50, 0.5, -17)
    keyCloseButton.BackgroundColor3 = THEME.Danger
    keyCloseButton.Text = "X"
    keyCloseButton.TextColor3 = THEME.White
    keyCloseButton.Font = Enum.Font.GothamBold
    keyCloseButton.TextSize = 14
    keyCloseButton.Parent = oceanHeader
    addCorner(keyCloseButton, 10)

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, -40, 0, 42)
    keyBox.Position = UDim2.fromOffset(20, 75)
    keyBox.BackgroundColor3 = THEME.White
    keyBox.PlaceholderText = "Enter your beach key..."
    keyBox.Text = ""
    keyBox.TextColor3 = THEME.OceanDeep
    keyBox.PlaceholderColor3 = THEME.OceanMid
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 15
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = keyFrame
    addCorner(keyBox, 10)
    addStroke(keyBox, THEME.OceanShallow, 2)
    
    local keysHint = Instance.new("TextLabel")
    keysHint.Size = UDim2.new(1, -40, 0, 20)
    keysHint.Position = UDim2.fromOffset(20, 122)
    keysHint.BackgroundTransparency = 1
    keysHint.Text = "Valid keys: " .. table.concat(VALID_KEYS, ", ")
    keysHint.TextColor3 = THEME.OceanMid
    keysHint.Font = Enum.Font.Gotham
    keysHint.TextSize = 12
    keysHint.TextXAlignment = Enum.TextXAlignment.Left
    keysHint.Parent = keyFrame

    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(1, -40, 0, 42)
    submit.Position = UDim2.fromOffset(20, 150)
    submit.BackgroundColor3 = THEME.PalmGreen
    submit.Text = "🌊 Unlock Tides"
    submit.TextColor3 = THEME.White
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 16
    submit.AutoButtonColor = false
    submit.Parent = keyFrame
    addCorner(submit, 10)
    addStroke(submit, THEME.SandLight, 2)
    wireButtonTweens(submit, THEME.PalmGreen, Color3.fromRGB(50, 180, 50), THEME.PalmDark)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.fromOffset(20, 198)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = THEME.Bad
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextXAlignment = Enum.TextXAlignment.Center
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
            status.Text = "✅ Welcome to Tides!"
            TweenService:Create(keyFrame, TweenInfo.new(0.5), {Size = UDim2.fromOffset(360, 0)}):Play()
            task.wait(0.5)
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

    makeDraggable(keyFrame, oceanHeader)
    return keyFrame
end

-- ============================================================
-- BOOT
-- ============================================================
buildKeyUI(function()
    buildMainUI()
end)
