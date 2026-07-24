print("Hello, world!");print("Aimbot Universal Lucille F.P");-- Aimbot con Target Lock + Settings - Potassium Executor
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Impostazioni
local Settings = {
    Enabled = false,
    TargetPart = "Head",
    Smoothness = 0.25,
    MaxDistance = 5000,
    UseMaxDistance = false,
    TeamCheck = false,
    WallCheck = false,
    TargetPlayers = true,
    TargetNPCs = true,
    Prediction = 0.165,
    LockOnTarget = true,
    FOV = 250,
}

local BodyParts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart", "LeftHand", "RightHand"}
local CurrentBodyPartIndex = 1

local LockedTarget = nil
local Aiming = false

local function isValidHumanoid(humanoid)
    return humanoid and humanoid.Health > 0 and humanoid.Parent
end

local function isValidCharacter(char)
    if not char or not char.Parent then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not isValidHumanoid(humanoid) then return false end
    
    local targetPart = char:FindFirstChild(Settings.TargetPart) 
        or char:FindFirstChild("Head") 
        or char:FindFirstChild("UpperTorso") 
        or char:FindFirstChild("Torso") 
        or char:FindFirstChild("HumanoidRootPart")
    
    return targetPart ~= nil, targetPart
end

local function hasLineOfSight(targetPart)
    if not Settings.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = Workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function findTarget()
    local bestTarget = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + 36)
    
    if Settings.TargetPlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                local valid, part = isValidCharacter(player.Character)
                if valid then
                    if Settings.UseMaxDistance then
                        local dist3D = (Camera.CFrame.Position - part.Position).Magnitude
                        if dist3D > Settings.MaxDistance then continue end
                    end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist2D < shortestDist and dist2D < Settings.FOV and hasLineOfSight(part) then
                            shortestDist = dist2D
                            bestTarget = player.Character
                        end
                    end
                end
            end
        end
    end
    
    if Settings.TargetNPCs then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") and isValidHumanoid(obj) then
                local char = obj.Parent
                local isPlayer = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == char then isPlayer = true break end
                end
                
                if not isPlayer then
                    local valid, part = isValidCharacter(char)
                    if valid then
                        if Settings.UseMaxDistance then
                            local dist3D = (Camera.CFrame.Position - part.Position).Magnitude
                            if dist3D > Settings.MaxDistance then continue end
                        end
                        
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist2D < shortestDist and dist2D < Settings.FOV and hasLineOfSight(part) then
                                shortestDist = dist2D
                                bestTarget = char
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

-- FOV Circle (visual)
local FOVCircle = Drawing and Drawing.new("Circle") or nil
if FOVCircle then
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 60
    FOVCircle.Color = Color3.fromRGB(100, 200, 100)
    FOVCircle.Filled = false
    FOVCircle.Visible = true
    FOVCircle.Transparency = 1
end

-- Target Dot (point marker per target mirato)
local TargetDot = Drawing and Drawing.new("Circle") or nil
if TargetDot then
    TargetDot.Radius = 5
    TargetDot.Color = Color3.fromRGB(255, 100, 100)
    TargetDot.Filled = true
    TargetDot.Visible = false
    TargetDot.Transparency = 0.8
end

RunService.RenderStepped:Connect(function()
    local mousePos = Vector2.new(Mouse.X, Mouse.Y + 36)
    
    if FOVCircle then
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Position = mousePos
        FOVCircle.Visible = Settings.Enabled
    end
    
    -- Target Dot (dot per il target mirato)
    if TargetDot and LockedTarget then
        local valid, targetPart = isValidCharacter(LockedTarget)
        if valid and targetPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                TargetDot.Position = Vector2.new(screenPos.X, screenPos.Y)
                TargetDot.Visible = Settings.Enabled and Aiming
            else
                TargetDot.Visible = false
            end
        else
            TargetDot.Visible = false
        end
    else
        TargetDot.Visible = false
    end
    
    if not Settings.Enabled or not Aiming then
        LockedTarget = nil
        return
    end
    
    if Settings.LockOnTarget and LockedTarget then
        local valid = isValidCharacter(LockedTarget)
        if not valid then
            LockedTarget = nil
        end
    end
    
    if not LockedTarget then
        LockedTarget = findTarget()
    end
    
    if LockedTarget then
        local valid, targetPart = isValidCharacter(LockedTarget)
        if valid and targetPart then
            local velocity = targetPart.AssemblyLinearVelocity or Vector3.new()
            local predictedPos = targetPart.Position + (velocity * Settings.Prediction)
            
            local currentCF = Camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, predictedPos)
            Camera.CFrame = currentCF:Lerp(targetCF, Settings.Smoothness)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aiming = false
        LockedTarget = nil
    end
end)

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotMenuLucille"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 260, 0, 520)
Main.Position = UDim2.new(0, 20, 0, 80)
Main.BackgroundColor3 = Color3.fromRGB(20, 35, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true

-- SFONDO MAZZA LUCILLE
local LucilleBackground = Instance.new("ImageLabel", Main)
LucilleBackground.Size = UDim2.new(1, 0, 1, 0)
LucilleBackground.Position = UDim2.new(0, 0, 0, 0)
LucilleBackground.BackgroundTransparency = 1
LucilleBackground.Image = "https://cdn.workik.com/generated-images/392665/ff166183ea7f45d19215e4ce03e3749f.png"
LucilleBackground.ImageTransparency = 0.85
LucilleBackground.ZIndex = 0
LucilleBackground.ScaleType = Enum.ScaleType.Slice
LucilleBackground.SliceCenter = Rect.new(10, 10, 10, 10)

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 6)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
Title.BorderSizePixel = 0
Title.Text = "Aimbot Universal Lucille F.P"
Title.TextColor3 = Color3.fromRGB(100, 255, 100)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.ZIndex = 1

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "x"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 2
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local function createToggle(name, y, key, default)
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -20, 0, 24)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(50, 80, 50)
    btn.Text = name .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(200, 255, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 1
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 180, 50) or Color3.fromRGB(50, 80, 50)
    end)
end

-- Slider generico
local function createSlider(name, y, key, minVal, maxVal, decimals)
    local label = Instance.new("TextLabel", Main)
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Position = UDim2.new(0, 10, 0, y)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(Settings[key])
    label.TextColor3 = Color3.fromRGB(150, 255, 150)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 1
    
    local barBg = Instance.new("Frame", Main)
    barBg.Size = UDim2.new(1, -20, 0, 8)
    barBg.Position = UDim2.new(0, 10, 0, y + 18)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 1
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)
    
    local fill = Instance.new("Frame", barBg)
    local pct = (Settings[key] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    fill.BorderSizePixel = 0
    fill.ZIndex = 1
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
    
    local dragging = false
    local function updateSlider(input)
        local relX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * relX
        if decimals then
            value = math.floor(value * (10 ^ decimals) + 0.5) / (10 ^ decimals)
        else
            value = math.floor(value + 0.5)
        end
        Settings[key] = value
        fill.Size = UDim2.new(relX, 0, 1, 0)
        label.Text = name .. ": " .. tostring(value)
    end
    
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Cycle body part
local function createCycler(name, y)
    local label = Instance.new("TextLabel", Main)
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Position = UDim2.new(0, 10, 0, y)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(150, 255, 150)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 1
    
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(1, -20, 0, 24)
    btn.Position = UDim2.new(0, 10, 0, y + 18)
    btn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    btn.Text = "< " .. Settings.TargetPart .. " >"
    btn.TextColor3 = Color3.fromRGB(200, 255, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.ZIndex = 1
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        CurrentBodyPartIndex = CurrentBodyPartIndex + 1
        if CurrentBodyPartIndex > #BodyParts then CurrentBodyPartIndex = 1 end
        Settings.TargetPart = BodyParts[CurrentBodyPartIndex]
        btn.Text = "< " .. Settings.TargetPart .. " >"
    end)
end

-- Layout
createToggle("Aimbot", 40, "Enabled", false)
createToggle("Target Players", 68, "TargetPlayers", true)
createToggle("Target NPCs", 96, "TargetNPCs", true)
createToggle("Lock Target", 124, "LockOnTarget", true)
createToggle("Team Check", 152, "TeamCheck", false)
createToggle("Wall Check", 180, "WallCheck", false)
createToggle("Limit Distance", 208, "UseMaxDistance", false)

createSlider("FOV", 240, "FOV", 20, 800)
createSlider("Smoothness", 285, "Smoothness", 0.05, 1, 2)
createCycler("Target Body Part", 330)

-- English instructions (below controls)
local Info = Instance.new("TextLabel", Main)
Info.Size = UDim2.new(1, -20, 0, 100)
Info.Position = UDim2.new(0, 10, 0, 400)
Info.BackgroundColor3 = Color3.fromRGB(25, 50, 25)
Info.BorderSizePixel = 0
Info.Text = "[ INSTRUCTIONS ]\nHOLD RIGHT MOUSE = aim\nINSERT = hide/show menu\nX button = close menu\nLock keeps target until release\nDrag title bar to move menu"
Info.TextColor3 = Color3.fromRGB(150, 255, 150)
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.TextWrapped = true
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.TextXAlignment = Enum.TextXAlignment.Center
Info.ZIndex = 1
Instance.new("UICorner", Info).CornerRadius = UDim.new(0, 4)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    end
end)
