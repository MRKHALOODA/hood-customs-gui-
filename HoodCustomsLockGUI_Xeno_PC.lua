
-- ✅ Hood Customs Lock GUI for Xeno PC (Fully Working Version)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Kavo UI Library (compatible with Xeno)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Hood Customs Lock GUI", "Sentinel")

-- Globals
local LockedPlayer = nil
local LockPart = "HumanoidRootPart"
local TPWalkEnabled = false
local TPWalkSpeed = 20
local FlyEnabled = false
local BodyGyro, BodyVelocity

-- 🔒 Cam Lock Tab
local LockTab = Window:NewTab("Cam Lock")
local LockSection = LockTab:NewSection("Players in Server")

local function LockOn(player)
    LockedPlayer = player
    print("🎯 Locked onto:", player.Name)
end

local function Unlock()
    LockedPlayer = nil
    Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
    print("🔓 Unlocked")
end

local function RefreshPlayers()
    LockSection:ClearAllChildren()
    LockSection:NewButton("🔄 Refresh", "Reload players", RefreshPlayers)
    LockSection:NewButton("🔓 Unlock", "Stop cam lock", Unlock)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            LockSection:NewButton(player.DisplayName .. " (@" .. player.Name .. ")", "Lock on", function()
                LockOn(player)
            end)
        end
    end
end

RefreshPlayers()

RunService.RenderStepped:Connect(function()
    if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild(LockPart) then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, LockedPlayer.Character[LockPart].Position)
    end
end)

-- ⚙️ Settings Tab
local SettingsTab = Window:NewTab("Settings")
local SettingsSection = SettingsTab:NewSection("Configuration")

SettingsSection:NewDropdown("Lock Part", "Choose body part to lock onto", {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso"}, function(part)
    LockPart = part
end)

SettingsSection:NewDropdown("GUI Theme", "Set GUI color theme", {
    "Sentinel", "DarkTheme", "LightTheme", "BloodTheme", "GrapeTheme", "Ocean", "Midnight", "Synapse"
}, function(theme)
    Library:Notify("Theme changed. Re-execute script to apply.")
end)

-- 🛠️ Misc Tab
local MiscTab = Window:NewTab("Misc")
local Misc = MiscTab:NewSection("Tools")

-- Fly Toggle
Misc:NewButton("🕊️ Fly (E)", "Toggle flight mode", function()
    local Character = LocalPlayer.Character
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    FlyEnabled = not FlyEnabled
    if FlyEnabled then
        BodyGyro = Instance.new("BodyGyro", HRP)
        BodyGyro.P = 9e4
        BodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BodyGyro.CFrame = HRP.CFrame

        BodyVelocity = Instance.new("BodyVelocity", HRP)
        BodyVelocity.velocity = Vector3.new(0, 0, 0)
        BodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)

        RunService.RenderStepped:Connect(function()
            if FlyEnabled then
                BodyGyro.CFrame = Camera.CFrame
                local moveVec = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec += Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec -= Camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec -= Camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec += Camera.CFrame.RightVector end
                BodyVelocity.velocity = moveVec.Unit * 50
            end
        end)
    else
        if BodyGyro then BodyGyro:Destroy() end
        if BodyVelocity then BodyVelocity:Destroy() end
    end
end)

-- TPWalk Toggle
Misc:NewSlider("TPWalk Speed", "Set how far you teleport per step", 50, 1, function(val)
    TPWalkSpeed = val
end)

Misc:NewButton("🚶 Toggle TPWalk", "Enable or disable TPWalk", function()
    TPWalkEnabled = not TPWalkEnabled
    Library:Notify("TPWalk " .. (TPWalkEnabled and "enabled" or "disabled"))

    if TPWalkEnabled then
        local connection
        connection = UIS.InputBegan:Connect(function(input, gpe)
            if gpe or not TPWalkEnabled then return end
            local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not HRP then return end

            local dir
            if input.KeyCode == Enum.KeyCode.W then dir = Camera.CFrame.LookVector
            elseif input.KeyCode == Enum.KeyCode.S then dir = -Camera.CFrame.LookVector
            elseif input.KeyCode == Enum.KeyCode.A then dir = -Camera.CFrame.RightVector
            elseif input.KeyCode == Enum.KeyCode.D then dir = Camera.CFrame.RightVector
            end

            if dir then HRP.CFrame = HRP.CFrame + dir.Unit * TPWalkSpeed end
        end)

        spawn(function()
            while TPWalkEnabled do wait() end
            if connection then connection:Disconnect() end
        end)
    end
end)

-- GoTo with smart match
Misc:NewTextBox("GoTo (Name)", "Type 3+ letters of a name", function(text)
    if #text < 3 then Library:Notify("Enter at least 3 characters") return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (plr.Name:lower():find(text:lower()) or plr.DisplayName:lower():find(text:lower())) then
            local HRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if HRP and myHRP then
                myHRP.CFrame = HRP.CFrame + Vector3.new(0, 3, 0)
                Library:Notify("Teleported to " .. plr.Name)
            end
            return
        end
    end
    Library:Notify("No match found.")
end)

-- TPTool
Misc:NewButton("🛠️ TPTool", "Click to teleport", function()
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "TPTool"
    tool.Activated:Connect(function()
        local pos = Mouse.Hit + Vector3.new(0, 3, 0)
        if LocalPlayer.Character then
            LocalPlayer.Character:MoveTo(pos.Position)
        end
    end)
    tool.Parent = LocalPlayer.Backpack
end)
