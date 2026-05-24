local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Global Configuration States
local ESPEnabled = true
local HitboxExpansionEnabled = true
local AimbotEnabled = true
local TargetHitboxSize = Vector3.new(15, 15, 15)

-- Determine Platform Environment
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

-- Role Identity Constants
local Colors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Innocent = Color3.fromRGB(0, 255, 0)
}

local function getRoleColor(player)
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    if char and (char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))) then
        return Colors.Murderer
    elseif char and (char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))) then
        return Colors.Sheriff
    else
        return Colors.Innocent
    end
end

-- UI Master Menu Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_SmartHitbox_System"
ScreenGui.ResetOnSpawn = false

local success, err = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main Management Panel
local MainMenu = Instance.new("Frame", ScreenGui)
MainMenu.Size = UDim2.new(0, 180, 0, 190)
MainMenu.Position = UDim2.new(0, 30, 0, 80)
MainMenu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainMenu.BorderSizePixel = 0
MainMenu.Active = true

local UICorner = Instance.new("UICorner", MainMenu)
UICorner.CornerRadius = UDim.new(0, 8)

local MenuTitle = Instance.new("TextLabel", MainMenu)
MenuTitle.Size = UDim2.new(1, 0, 0, 35)
MenuTitle.Text = "MM2 Smart UI [INS]"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MenuTitle.Font = Enum.Font.SourceSansBold
MenuTitle.TextSize = 16

local TitleCorner = Instance.new("UICorner", MenuTitle)
TitleCorner.CornerRadius = UDim.new(0, 8)

-- 1. Player ESP Button
local ESPButton = Instance.new("TextButton", MainMenu)
ESPButton.Size = UDim2.new(0, 150, 0, 40)
ESPButton.Position = UDim2.new(0, 15, 0, 50)
ESPButton.Text = "Player ESP: ON"
ESPButton.Font = Enum.Font.SourceSans
ESPButton.TextSize = 14
ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", ESPButton).CornerRadius = UDim.new(0, 6)

-- 2. Smart Hitbox Toggle Button
local HitboxButton = Instance.new("TextButton", MainMenu)
HitboxButton.Size = UDim2.new(0, 150, 0, 40)
HitboxButton.Position = UDim2.new(0, 15, 0, 95)
HitboxButton.Text = "Smart Hitbox: ON"
HitboxButton.Font = Enum.Font.SourceSans
HitboxButton.TextSize = 14
HitboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", HitboxButton).CornerRadius = UDim.new(0, 6)

-- 3. Hard Aimbot Toggle Button
local AimbotButton = Instance.new("TextButton", MainMenu)
AimbotButton.Size = UDim2.new(0, 150, 0, 40)
AimbotButton.Position = UDim2.new(0, 15, 0, 140)
AimbotButton.Text = "Hard Aimbot: ON"
AimbotButton.Font = Enum.Font.SourceSans
AimbotButton.TextSize = 14
AimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimbotButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
Instance.new("UICorner", AimbotButton).CornerRadius = UDim.new(0, 6)

-- 4. Exclusive Murderer "Bring All" Indicator Status Button
local BringAllButton = Instance.new("TextButton", MainMenu)
BringAllButton.Size = UDim2.new(0, 150, 0, 40)
BringAllButton.Position = UDim2.new(0, 15, 0, 185)
BringAllButton.Text = "Press [C] to Bring"
BringAllButton.Font = Enum.Font.SourceSansBold
BringAllButton.TextSize = 14
BringAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BringAllButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
BringAllButton.Visible = false
Instance.new("UICorner", BringAllButton).CornerRadius = UDim.new(0, 6)

-- --- MOBILE MINIMIZE UTILITY ---
local MinimizeToggle = Instance.new("TextButton", ScreenGui)
MinimizeToggle.Size = UDim2.new(0, 45, 0, 45)
MinimizeToggle.Position = UDim2.new(0, 15, 0, 15)
MinimizeToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeToggle.BorderSizePixel = 0
MinimizeToggle.Text = "M"
MinimizeToggle.Font = Enum.Font.SourceSansBold
MinimizeToggle.TextSize = 18
MinimizeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)

local ToggleCorner = Instance.new("UICorner", MinimizeToggle)
ToggleCorner.CornerRadius = UDim.new(0, 22.5)

MinimizeToggle.MouseButton1Click:Connect(function()
    MainMenu.Visible = not MainMenu.Visible
end)

-- --- UI DRAGGING MODULE ---
local dragToggle = false
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    game:GetService("TweenService"):Create(MainMenu, TweenInfo.new(0.08), {Position = position}):Play()
end

MainMenu.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = MainMenu.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

MainMenu.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragToggle then
            updateInput(input)
        end
    end
end)

-- Interactive UI Signals
ESPButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    ESPButton.Text = ESPEnabled and "Player ESP: ON" or "Player ESP: OFF"
    ESPButton.BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

HitboxButton.MouseButton1Click:Connect(function()
    HitboxExpansionEnabled = not HitboxExpansionEnabled
    HitboxButton.Text = HitboxExpansionEnabled and "Smart Hitbox: ON" or "Smart Hitbox: OFF"
    HitboxButton.BackgroundColor3 = HitboxExpansionEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

AimbotButton.MouseButton1Click:Connect(function()
    AimbotEnabled = not AimbotEnabled
    AimbotButton.Text = AimbotEnabled and "Hard Aimbot: ON" or "Hard Aimbot: OFF"
    AimbotButton.BackgroundColor3 = AimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

-- Core Function to Teleport All Players with Button Flash
local function executeBringAll()
    if getRoleColor(LocalPlayer) == Colors.Murderer and LocalPlayer.Character then
        local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            BringAllButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            BringAllButton.Text = "BRINGING PLAYERS..."
            
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if targetHrp and targetHumanoid and targetHumanoid.Health > 0 then
                        targetHrp.CFrame = myHrp.CFrame * CFrame.new(0, 0, -3)
                    end
                end
            end
            
            task.delay(0.4, function()
                BringAllButton.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
                BringAllButton.Text = "Press [C] to Bring"
            end)
        end
    end
end

BringAllButton.MouseButton1Click:Connect(executeBringAll)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Insert then
        MainMenu.Visible = not MainMenu.Visible
    end
end)

-- Dynamic UI Visibility Optimization Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if getRoleColor(LocalPlayer) == Colors.Murderer then
            BringAllButton.Visible = true
            MainMenu.Size = UDim2.new(0, 180, 0, 240)
        else
            BringAllButton.Visible = false
            MainMenu.Size = UDim2.new(0, 180, 0, 190)
        end
    end
end)

local function getMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getRoleColor(p) == Colors.Murderer then
            return p
        end
    end
    return nil
end

-- --- PLATFORM HYBRID ENGINE ---
local holdingAimKey = false

RunService.RenderStepped:Connect(function()
    if AimbotEnabled and getRoleColor(LocalPlayer) == Colors.Sheriff then
        if IsMobile or holdingAimKey then
            local targetPlayer = getMurderer()
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = targetPlayer.Character.HumanoidRootPart
                if targetPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, hrp.Position)
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.UserInputType == Enum.UserInputType.MouseButton2 and getRoleColor(LocalPlayer) == Colors.Sheriff then
            holdingAimKey = true
        elseif input.KeyCode == Enum.KeyCode.C and getRoleColor(LocalPlayer) == Colors.Murderer then
            executeBringAll()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        holdingAimKey = false
    end
end)

-- --- ADAPTIVE ACCELERATED HITBOX CONFIGURATION ENGINE ---
task.spawn(function()
    while true do
        task.wait(0.2)
        local myColor = getRoleColor(LocalPlayer)
        local amISheriff = (myColor == Colors.Sheriff)
        local amIMurderer = (myColor == Colors.Murderer)
        local amIInnocent = (myColor == Colors.Innocent)
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                local char = targetPlayer.Character
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if humanoid and humanoid.Health > 0 and hrp then
                    local targetColor = getRoleColor(targetPlayer)
                    local shouldExpand = false
                    
                    if HitboxExpansionEnabled then
                        if amIMurderer then
                            shouldExpand = true
                        elseif amIInnocent or amISheriff then
                            shouldExpand = false
                        end
                    end
                    
                    pcall(function()
                        local visualIndicator = hrp:FindFirstChild("HitboxIndicatorMesh")
                        if shouldExpand then
                            hrp.Size = TargetHitboxSize
                            hrp.CanCollide = false
                            hrp.Transparency = 1
                            if not visualIndicator then
                                visualIndicator = Instance.new("SelectionBox")
                                visualIndicator.Name = "HitboxIndicatorMesh"
                                visualIndicator.LineThickness = 0.05
                                visualIndicator.SurfaceTransparency = 0.85
                                visualIndicator.Parent = hrp
                            end
                            visualIndicator.Adornee = hrp
                            visualIndicator.Color3 = targetColor
                            visualIndicator.SurfaceColor3 = targetColor
                        else
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.CanCollide = true
                            hrp.Transparency = 1
                            if visualIndicator then
                                visualIndicator:Destroy()
                            end
                        end
                    end)
                end
            elseif targetPlayer == LocalPlayer and LocalPlayer.Character then
                pcall(function()
                    local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        myHrp.Size = Vector3.new(2, 2, 1)
                        myHrp.CanCollide = true
                        myHrp.Transparency = 1
                        local localInd = myHrp:FindFirstChild("HitboxIndicatorMesh")
                        if localInd then localInd:Destroy() end
                    end
                end)
            end
        end
    end
end)

-- Central Tracker Registry for Player ESP Memory Allocations
local ActiveESP = {}

local function setupESP(player)
    if player == LocalPlayer then return end
    local line = Drawing.new("Line")
    local text = Drawing.new("Text")
    text.Center = true
    text.Size = 20
    
    local renderConnection
    local characterAddedConnection
    local backpackConnection = nil
    local highlightInstance = nil
    
    local function cleanupCharacterESP()
        line.Visible = false
        text.Visible = false
    end
    
    local function applyHighlight(char)
        if highlightInstance then
            pcall(function() highlightInstance:Destroy() end)
        end
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.1)
        if not player.Parent then return end
        
        highlightInstance = Instance.new("Highlight")
        highlightInstance.Adornee = char
        highlightInstance.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlightInstance.FillTransparency = 0.5
        highlightInstance.OutlineTransparency = 0
        highlightInstance.Parent = char
    end
    
    local function monitorBackpack()
        local bp = player:WaitForChild("Backpack", 5)
        if bp then
            if backpackConnection then backpackConnection:Disconnect() end
            backpackConnection = bp.ChildAdded:Connect(function()
                task.wait(0.05)
            end)
        end
    end
    
    if player.Character then task.spawn(applyHighlight, player.Character) end
    monitorBackpack()
    
    characterAddedConnection = player.CharacterAdded:Connect(function(char)
        cleanupCharacterESP()
        task.spawn(applyHighlight, char)
        monitorBackpack()
    end)
    
    renderConnection = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local roleColor = getRoleColor(player)
            if highlightInstance and highlightInstance.Parent then
                highlightInstance.Enabled = ESPEnabled
                highlightInstance.FillColor = roleColor
                highlightInstance.OutlineColor = roleColor
            elseif not highlightInstance or not highlightInstance.Parent then
                if player.Character then task.spawn(applyHighlight, player.Character) end
            end
            
            if ESPEnabled and hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = roleColor
                    line.Visible = true
                    text.Text = player.Name
                    text.Position = Vector2.new(pos.X, pos.Y - 25)
                    text.Color = roleColor
                    text.Visible = true
                else
                    cleanupCharacterESP()
                end
            else
                cleanupCharacterESP()
            end
        else
            cleanupCharacterESP()
            if highlightInstance then highlightInstance.Enabled = false end
        end
    end)
    
    ActiveESP[player] = {
        Render = renderConnection,
        CharAdded = characterAddedConnection,
        BackpackConn = backpackConnection,
        Drawings = {line, text},
        GetHighlight = function() return highlightInstance end
    }
end

local function removeESP(player)
    local data = ActiveESP[player]
    if data then
        if data.Render then data.Render:Disconnect() end
        if data.CharAdded then data.CharAdded:Disconnect() end
        if data.BackpackConn then data.BackpackConn:Disconnect() end
        local currentHighlight = data.GetHighlight()
        if currentHighlight then pcall(function() currentHighlight:Destroy() end) end
        for _, drawingItem in ipairs(data.Drawings) do
            drawingItem:Remove()
        end
        ActiveESP[player] = nil
    end
end

local function setupLocalPlayer()
    local bp = LocalPlayer:WaitForChild("Backpack", 5)
    if bp then
        bp.ChildAdded:Connect(function() task.wait(0.05) end)
    end
    LocalPlayer.CharacterAdded:Connect(function()
        local newBp = LocalPlayer:WaitForChild("Backpack", 5)
        if newBp then
            newBp.ChildAdded:Connect(function() task.wait(0.05) end)
        end
    end)
end
task.spawn(setupLocalPlayer)

-- Runtime Initialization Sequences
for _, player in ipairs(Players:GetPlayers()) do
    setupESP(player)
end
Players.PlayerAdded:Connect(setupESP)
Players.PlayerRemoving:Connect(removeESP)
