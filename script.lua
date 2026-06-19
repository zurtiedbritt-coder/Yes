local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===== Config =====
local AIMBOT_KEYBIND = Enum.KeyCode.Q
local AIMBOT_SMOOTHNESS = 0.08
local AIMBOT_FOV = 300

-- ===== Modern Dark Theme =====
local THEME = {
    Background = Color3.fromRGB(10, 10, 15),
    Surface = Color3.fromRGB(20, 20, 30),
    SurfaceLight = Color3.fromRGB(35, 35, 50),
    Primary = Color3.fromRGB(0, 255, 255),
    Secondary = Color3.fromRGB(180, 0, 255),
    Accent = Color3.fromRGB(255, 50, 150),
    Success = Color3.fromRGB(0, 255, 150),
    Danger = Color3.fromRGB(255, 50, 80),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(150, 150, 170),
}

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VoidUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- FOV Circle
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Size = UDim2.fromOffset(AIMBOT_FOV * 2, AIMBOT_FOV * 2)
fovCircle.Position = UDim2.new(0.5, -AIMBOT_FOV, 0.5, -AIMBOT_FOV)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = THEME.Primary
fovStroke.Thickness = 2
fovStroke.Transparency = 0.5
fovStroke.Parent = fovCircle

-- Helper functions
local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.Primary
    s.Thickness = thickness or 1.5
    s.Transparency = 0.3
    s.Parent = parent
    return s
end

local function addGlow(parent, color)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.Image = "rbxassetid://4996890006"
    glow.ImageColor3 = color or THEME.Primary
    glow.ImageTransparency = 0.6
    glow.ZIndex = parent.ZIndex - 1
    glow.Parent = parent
    return glow
end

-- Modern button effects
local function wireButton(btn, baseColor)
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = baseColor:Lerp(Color3.fromRGB(255,255,255), 0.15),
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 4, btn.Size.Y.Scale, btn.Size.Y.Offset + 4)
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
        end
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = baseColor,
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 4, btn.Size.Y.Scale, btn.Size.Y.Offset - 4)
        }):Play()
        if stroke then
            TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
        end
    end)
    
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset - 6, btn.Size.Y.Scale, btn.Size.Y.Offset - 6)
        }):Play()
    end)
    
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(btn.Size.X.Scale, btn.Size.X.Offset + 4, btn.Size.Y.Scale, btn.Size.Y.Offset + 4)
        }):Play()
    end)
end

-- DRAGGABLE FUNCTION - Fixed and Improved
local function makeDraggable(frame, dragHandle)
    local dragging = false
    local dragStart, startPos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local currentPos = Vector2.new(input.Position.X, input.Position.Y)
            local delta = currentPos - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ===== VOIDSPAM LOGIC =====
local voidspamming = false
local voidspamConn = nil
local bodyVel = nil

local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

local function createBodyVelocity()
    if bodyVel then bodyVel:Destroy() end
    local root = getRoot()
    if not root then return end
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.zero
    bodyVel.P = 50000
    bodyVel.Parent = root
end

local function destroyBodyVelocity()
    if bodyVel then
        bodyVel:Destroy()
        bodyVel = nil
    end
end

local function doVoidspam()
    local root = getRoot()
    local humanoid = getHumanoid()
    if not root or not humanoid then return end
    
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    
    local randomOffset = Vector3.new(
        math.random(-500000, 500000),
        math.random(-500000, 500000),
        math.random(-500000, 500000)
    )
    root.CFrame = root.CFrame + randomOffset
    root.AssemblyLinearVelocity = Vector3.new(
        math.random(-1000000, 1000000),
        math.random(-1000000, 1000000),
        math.random(-1000000, 1000000)
    )
    
    if bodyVel then
        bodyVel.Velocity = Vector3.new(
            math.random(-500000, 500000),
            math.random(-500000, 500000),
            math.random(-500000, 500000)
        )
    end
    
    root.AssemblyAngularVelocity = Vector3.new(
        math.random(-500000, 500000),
        math.random(-500000, 500000),
        math.random(-500000, 500000)
    )
end

local function startVoidspam()
    if voidspamming then return end
    voidspamming = true
    createBodyVelocity()
    voidspamConn = RunService.Heartbeat:Connect(function()
        if not voidspamming then return end
        doVoidspam()
    end)
end

local function stopVoidspam()
    voidspamming = false
    if voidspamConn then
        voidspamConn:Disconnect()
        voidspamConn = nil
    end
    destroyBodyVelocity()
    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    local humanoid = getHumanoid()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    end
end

-- ===== ORBIT =====
local orbiting = false
local orbitConn = nil
local orbitAngle = 0

local function getNearestRoot()
    local myRoot = getRoot()
    if not myRoot then return nil end
    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local theirRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local d = (theirRoot.Position - myRoot.Position).Magnitude
                if d < dist then
                    dist = d
                    closest = theirRoot
                end
            end
        end
    end
    return closest
end

local function startOrbit()
    if orbiting then return end
    orbiting = true
    orbitConn = RunService.Heartbeat:Connect(function(dt)
        local myRoot = getRoot()
        local target = getNearestRoot()
        if not myRoot or not target then return end
        orbitAngle = orbitAngle + 15 * dt
        local offset = Vector3.new(math.cos(orbitAngle) * 8, 3, math.sin(orbitAngle) * 8)
        myRoot.CFrame = CFrame.lookAt(target.Position + offset, target.Position)
        myRoot.AssemblyLinearVelocity = Vector3.zero
    end)
end

local function stopOrbit()
    orbiting = false
    if orbitConn then
        orbitConn:Disconnect()
        orbitConn = nil
    end
end

-- ===== AIMBOT =====
local aimbotActive = false
local aimbotTarget = nil

local function getClosestPlayer()
    local closest, shortest = nil, AIMBOT_FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local humanoid = p.Character:FindFirstChild("Humanoid")
            if head and humanoid and humanoid.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimbotActive then
        if not aimbotTarget or not aimbotTarget.Character then
            aimbotTarget = getClosestPlayer()
        end
        if aimbotTarget and aimbotTarget.Character then
            local head = aimbotTarget.Character:FindFirstChild("Head")
            if head then
                local targetCF = CFrame.new(camera.CFrame.Position, head.Position)
                camera.CFrame = camera.CFrame:Lerp(targetCF, 1 - AIMBOT_SMOOTHNESS)
            end
        end
        fovCircle.Visible = true
    else
        aimbotTarget = nil
        fovCircle.Visible = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == AIMBOT_KEYBIND then
        aimbotActive = not aimbotActive
    end
end)

-- ===== TIDES EXECUTOR =====
local tidesOpen = false

local function createTidesExecutor()
    if tidesOpen then return end
    tidesOpen = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(550, 380)
    frame.Position = UDim2.new(0.5, -275, 0.5, -190)
    frame.BackgroundColor3 = THEME.Surface
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    addCorner(frame, 16)
    addStroke(frame, THEME.Primary)
    
    local glow = addGlow(frame, THEME.Primary)
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = THEME.SurfaceLight
    header.BorderSizePixel = 0
    header.Parent = frame
    addCorner(header, 16)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.fromOffset(20, 0)
    title.BackgroundTransparency = 1
    title.Text = "🌊 Tides Executor"
    title.TextColor3 = THEME.Primary
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = header
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(36, 36)
    close.Position = UDim2.new(1, -46, 0.5, -18)
    close.BackgroundColor3 = THEME.Danger
    close.Text = "×"
    close.TextColor3 = THEME.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 24
    close.Parent = header
    addCorner(close, 10)
    
    close.MouseButton1Click:Connect(function()
        tidesOpen = false
        frame:Destroy()
    end)
    
    local editor = Instance.new("Frame")
    editor.Size = UDim2.new(1, -30, 0, 250)
    editor.Position = UDim2.fromOffset(15, 60)
    editor.BackgroundColor3 = THEME.Background
    editor.BorderSizePixel = 0
    editor.Parent = frame
    addCorner(editor, 12)
    addStroke(editor, THEME.SurfaceLight)
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, -20, 1, -20)
    codeBox.Position = UDim2.fromOffset(10, 10)
    codeBox.BackgroundTransparency = 1
    codeBox.Text = "-- Tides Lua Executor\n-- Paste script here..."
    codeBox.TextColor3 = THEME.Text
    codeBox.PlaceholderText = "-- Enter code..."
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 13
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.Parent = editor
    
    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(0.48, 0, 0, 45)
    execBtn.Position = UDim2.fromOffset(15, 320)
    execBtn.BackgroundColor3 = THEME.Success
    execBtn.Text = "▶ Execute"
    execBtn.TextColor3 = THEME.Text
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 15
    execBtn.Parent = frame
    addCorner(execBtn, 12)
    addStroke(execBtn, THEME.Success)
    wireButton(execBtn, THEME.Success)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0.48, 0, 0, 45)
    clearBtn.Position = UDim2.new(0.52, 0, 0, 320)
    clearBtn.BackgroundColor3 = THEME.Danger
    clearBtn.Text = "🗑 Clear"
    clearBtn.TextColor3 = THEME.Text
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 15
    clearBtn.Parent = frame
    addCorner(clearBtn, 12)
    addStroke(clearBtn, THEME.Danger)
    wireButton(clearBtn, THEME.Danger)
    
    execBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        if code ~= "" then
            local success, err = pcall(function() loadstring(code)() end)
            if not success then warn("Error: " .. err) end
        end
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        codeBox.Text = ""
    end)
    
    makeDraggable(frame, header)
end

-- ===== MAIN UI =====
local function buildMainUI()
    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(400, 520)
    main.Position = UDim2.new(0.5, -200, 0.5, -260)
    main.BackgroundColor3 = THEME.Surface
    main.BorderSizePixel = 0
    main.Parent = screenGui
    addCorner(main, 20)
    addStroke(main, THEME.Primary)
    
    local glow = addGlow(main, THEME.Primary)
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = THEME.SurfaceLight
    header.BorderSizePixel = 0
    header.Parent = main
    addCorner(header, 20)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 35)
    title.Position = UDim2.fromOffset(20, 10)
    title.BackgroundTransparency = 1
    title.Text = "VOIDSPAM ULTRA"
    title.TextColor3 = THEME.Text
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 24
    title.Parent = header
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -80, 0, 20)
    sub.Position = UDim2.fromOffset(20, 42)
    sub.BackgroundTransparency = 1
    sub.Text = "discord.gg/nQ6wthsQeV"
    sub.TextColor3 = THEME.Primary
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.Parent = header
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(40, 40)
    close.Position = UDim2.new(1, -50, 0, 15)
    close.BackgroundColor3 = THEME.Danger
    close.Text = "×"
    close.TextColor3 = THEME.Text
    close.Font = Enum.Font.GothamBlack
    close.TextSize = 28
    close.Parent = header
    addCorner(close, 12)
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -30, 1, -85)
    content.Position = UDim2.fromOffset(15, 80)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    local function makeBtn(text, order, color, isLarge)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, isLarge and 55 or 45)
        btn.LayoutOrder = order
        btn.BackgroundColor3 = color or THEME.SurfaceLight
        btn.Text = text
        btn.TextColor3 = THEME.Text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = isLarge and 18 or 15
        btn.Parent = content
        addCorner(btn, 12)
        addStroke(btn, color or THEME.Primary)
        if isLarge then addGlow(btn, color or THEME.Primary) end
        wireButton(btn, color or THEME.SurfaceLight)
        return btn
    end
    
    local tidesBtn = makeBtn("🌊 TIDES EXECUTOR", 0, THEME.Secondary, true)
    
    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(1, 0, 0, 2)
    sep1.LayoutOrder = 1
    sep1.BackgroundColor3 = THEME.SurfaceLight
    sep1.BorderSizePixel = 0
    sep1.Parent = content
    
    local voidspamBtn = makeBtn("🌀 VOIDSPAM: OFF", 2, THEME.Danger, true)
    local orbitBtn = makeBtn("🐚 ORBIT NEAREST", 3, THEME.SurfaceLight, false)
    
    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(1, 0, 0, 2)
    sep2.LayoutOrder = 4
    sep2.BackgroundColor3 = THEME.SurfaceLight
    sep2.BorderSizePixel = 0
    sep2.Parent = content
    
    local aimbotLabel = Instance.new("TextLabel")
    aimbotLabel.Size = UDim2.new(1, 0, 0, 20)
    aimbotLabel.LayoutOrder = 5
    aimbotLabel.BackgroundTransparency = 1
    aimbotLabel.Text = "AIMBOT (KEY: " .. AIMBOT_KEYBIND.Name .. ")"
    aimbotLabel.TextColor3 = THEME.TextDim
    aimbotLabel.Font = Enum.Font.GothamBold
    aimbotLabel.TextSize = 12
    aimbotLabel.Parent = content
    
    local aimbotBtn = makeBtn("🎯 AIMBOT: OFF", 6, THEME.SurfaceLight, false)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.LayoutOrder = 7
    status.BackgroundTransparency = 1
    status.Text = "Ready"
    status.TextColor3 = THEME.Success
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.Parent = content
    
    tidesBtn.MouseButton1Click:Connect(function()
        createTidesExecutor()
    end)
    
    voidspamBtn.MouseButton1Click:Connect(function()
        if voidspamming then
            stopVoidspam()
            voidspamBtn.Text = "🌀 VOIDSPAM: OFF"
            voidspamBtn.BackgroundColor3 = THEME.Danger
            status.Text = "Voidspam Stopped"
            status.TextColor3 = THEME.Danger
        else
            stopOrbit()
            orbitBtn.Text = "🐚 ORBIT NEAREST"
            startVoidspam()
            voidspamBtn.Text = "🌀 VOIDSPAM: ON"
            voidspamBtn.BackgroundColor3 = THEME.Success
            status.Text = "Voidspam Active"
            status.TextColor3 = THEME.Success
        end
    end)
    
    orbitBtn.MouseButton1Click:Connect(function()
        if orbiting then
            stopOrbit()
            orbitBtn.Text = "🐚 ORBIT NEAREST"
            status.Text = "Orbit Stopped"
        else
            stopVoidspam()
            voidspamBtn.Text = "🌀 VOIDSPAM: OFF"
            voidspamBtn.BackgroundColor3 = THEME.Danger
            startOrbit()
            orbitBtn.Text = "🐚 ORBITING..."
            status.Text = "Orbit Active"
        end
    end)
    
    aimbotBtn.MouseButton1Click:Connect(function()
        aimbotActive = not aimbotActive
        if aimbotActive then
            aimbotBtn.Text = "🎯 AIMBOT: ON"
            aimbotBtn.BackgroundColor3 = THEME.Primary
            fovCircle.Visible = true
            status.Text = "Aimbot Active"
        else
            aimbotBtn.Text = "🎯 AIMBOT: OFF"
            aimbotBtn.BackgroundColor3 = THEME.SurfaceLight
            fovCircle.Visible = false
            aimbotTarget = nil
            status.Text = "Aimbot Off"
        end
    end)
    
    close.MouseButton1Click:Connect(function()
        stopVoidspam()
        stopOrbit()
        aimbotActive = false
        fovCircle.Visible = false
        main:Destroy()
    end)
    
    makeDraggable(main, header)
end

-- ===== START =====
buildMainUI()
