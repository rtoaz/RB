local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- 等待游戏加载
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 获取本地玩家
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- 显示作者信息
local authorMessage = Instance.new("Message")
authorMessage.Text = "全局物体漂浮脚本修复版 - 作者: XTTT\n死亡自动关闭功能已修复\n方向控制已恢复"
authorMessage.Parent = Workspace
delay(3, function()
    authorMessage:Destroy()
end)

-- 全局变量
_G.processedParts = {}
_G.floatSpeed = 10
_G.moveDirectionType = "up"
_G.moveDirection = Vector3.new(0, 1, 0)
_G.fixedMode = false
_G.mainButton = nil
_G.controlPanel = nil
_G.isPlayerDead = false

-- 死亡检测系统
local function setupDeathDetection()
    local function onCharacterAdded(character)
        _G.isPlayerDead = false
        
        local humanoid = character:WaitForChild("Humanoid")
        
        humanoid.Died:Connect(function()
            _G.isPlayerDead = true
            print("玩家死亡，自动关闭漂浮功能")
            
            -- 关闭漂浮功能
            if anActivity then
                anActivity = false
                CleanupParts()
                
                -- 更新GUI状态
                if _G.mainButton then
                    _G.mainButton.Text = "漂浮: 关闭"
                    _G.mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                end
                
                -- 显示死亡提示
                local deathMessage = Instance.new("Message")
                deathMessage.Text = "检测到玩家死亡，已自动关闭漂浮功能"
                deathMessage.Parent = Workspace
                delay(3, function()
                    deathMessage:Destroy()
                end)
            end
        end)
    end
    
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
end

-- 立即设置死亡检测
setupDeathDetection()

-- 方向计算函数
local function CalculateMoveDirection()
    if _G.isPlayerDead then
        return Vector3.new(0, 0, 0)
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return Vector3.new(0, 1, 0) end

    if _G.moveDirectionType == "up" then
        return Vector3.new(0, 1, 0)
    elseif _G.moveDirectionType == "down" then
        return Vector3.new(0, -1, 0)
    elseif _G.moveDirectionType == "forward" then
        local lookVector = camera.CFrame.LookVector
        return Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    elseif _G.moveDirectionType == "back" then
        local lookVector = camera.CFrame.LookVector
        return -Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    elseif _G.moveDirectionType == "right" then
        local rightVector = camera.CFrame.RightVector
        return Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    elseif _G.moveDirectionType == "left" then
        local rightVector = camera.CFrame.RightVector
        return -Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    else
        return Vector3.new(0, 1, 0)
    end
end

-- 零件处理函数
local function ProcessPart(v)
    if _G.isPlayerDead then
        return
    end
    
    if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") then
        if _G.processedParts[v] then
            local existingBV = _G.processedParts[v].bodyVelocity
            local existingBG = _G.processedParts[v].bodyGyro
            if existingBV and existingBV.Parent then
                local finalVelocity = CalculateMoveDirection() * _G.floatSpeed
                if existingBV.Velocity ~= finalVelocity then
                    existingBV.Velocity = finalVelocity
                end
                
                if _G.fixedMode then
                    if not existingBG or not existingBG.Parent then
                        local bodyGyro = Instance.new("BodyGyro")
                        bodyGyro.Parent = v
                        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        bodyGyro.P = 1000
                        bodyGyro.D = 100
                        _G.processedParts[v].bodyGyro = bodyGyro
                    end
                    if existingBG then
                        existingBG.CFrame = v.CFrame
                    end
                else
                    if existingBG and existingBG.Parent then
                        existingBG:Destroy()
                        _G.processedParts[v].bodyGyro = nil
                    end
                end
                return
            else
                _G.processedParts[v] = nil
            end
        end

        for _, x in next, v:GetChildren() do
            if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or 
               x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") then
                x:Destroy()
            end
        end

        if v:FindFirstChild("Torque") then
            v.Torque:Destroy()
        end

        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Parent = v
        bodyVelocity.Velocity = CalculateMoveDirection() * _G.floatSpeed
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        local bodyGyro = nil
        if _G.fixedMode then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Parent = v
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 1000
            bodyGyro.D = 100
        end
        
        _G.processedParts[v] = { 
            bodyVelocity = bodyVelocity, 
            bodyGyro = bodyGyro 
        }
    end
end

local anActivity = false
local updateConnection = nil

local function ProcessAllParts()
    if _G.isPlayerDead then
        if anActivity then
            anActivity = false
            CleanupParts()
        end
        return
    end
    
    if anActivity then
        for _, v in next, Workspace:GetDescendants() do
            ProcessPart(v)
        end

        if updateConnection then
            updateConnection:Disconnect()
        end

        updateConnection = RunService.Heartbeat:Connect(function()
            UpdateAllPartsVelocity()
        end)
    else
        if updateConnection then
            updateConnection:Disconnect()
            updateConnection = nil
        end
    end
end

Workspace.DescendantAdded:Connect(function(v)
    if anActivity and not _G.isPlayerDead then
        ProcessPart(v)
    end
end)

local function CleanupParts()
    for _, data in pairs(_G.processedParts) do
        if data.bodyVelocity then
            data.bodyVelocity:Destroy()
        end
        if data.bodyGyro then
            data.bodyGyro:Destroy()
        end
    end
    _G.processedParts = {}

    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

local function UpdateAllPartsVelocity()
    if _G.isPlayerDead then
        for part, data in pairs(_G.processedParts) do
            if data.bodyVelocity and data.bodyVelocity.Parent then
                data.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end
        return
    end
    
    local direction = CalculateMoveDirection()
    for part, data in pairs(_G.processedParts) do
        if data.bodyVelocity and data.bodyVelocity.Parent then
            data.bodyVelocity.Velocity = direction * _G.floatSpeed
        end
        
        if _G.fixedMode and data.bodyGyro and data.bodyGyro.Parent then
            data.bodyGyro.CFrame = part.CFrame
        end
    end
end

local function StopAllParts()
    _G.floatSpeed = 0
    UpdateAllPartsVelocity()
end

local function PreventRotation()
    _G.fixedMode = true
    for part, data in pairs(_G.processedParts) do
        if data.bodyVelocity and data.bodyVelocity.Parent then
            if not data.bodyGyro or not data.bodyGyro.Parent then
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.Parent = part
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.P = 1000
                bodyGyro.D = 100
                data.bodyGyro = bodyGyro
            end
        end
    end
    UpdateAllPartsVelocity()
end

local function AllowRotation()
    _G.fixedMode = false
    for part, data in pairs(_G.processedParts) do
        if data.bodyGyro and data.bodyGyro.Parent then
            data.bodyGyro:Destroy()
            data.bodyGyro = nil
        end
    end
    UpdateAllPartsVelocity()
end

local function ToggleRotationPrevention()
    if _G.fixedMode then
        AllowRotation()
        return false
    else
        PreventRotation()
        return true
    end
end

-- GUI创建函数
local function CreateMobileGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MobileFloatingControl"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- 主开关按钮
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainToggle"
    mainButton.Size = UDim2.new(0, 120, 0, 50)
    mainButton.Position = UDim2.new(1, -130, 0, 10)
    mainButton.Text = "漂浮: 关闭"
    mainButton.TextSize = 16
    mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    mainButton.TextColor3 = Color3.new(1, 1, 1)
    mainButton.Parent = screenGui

    _G.mainButton = mainButton

    -- 控制面板
    local controlPanel = Instance.new("Frame")
    controlPanel.Name = "ControlPanel"
    controlPanel.Size = UDim2.new(0, 300, 0, 500)
    controlPanel.Position = UDim2.new(0.5, -150, 0.5, -250)
    controlPanel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    controlPanel.BackgroundTransparency = 0.3
    controlPanel.BorderSizePixel = 0
    controlPanel.Visible = false
    controlPanel.Parent = screenGui

    _G.controlPanel = controlPanel

    -- 速度标签
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(1, 0, 0, 40)
    speedLabel.Position = UDim2.new(0, 0, 0, 10)
    speedLabel.Text = "速度: " .. _G.floatSpeed
    speedLabel.TextColor3 = Color3.new(1, 1, 1)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextSize = 20
    speedLabel.Parent = controlPanel

    -- 速度控制按钮
    local speedUpButton = Instance.new("TextButton")
    speedUpButton.Name = "SpeedUp"
    speedUpButton.Size = UDim2.new(0, 60, 0, 60)
    speedUpButton.Position = UDim2.new(0.7, 0, 0, 60)
    speedUpButton.Text = "+"
    speedUpButton.TextSize = 30
    speedUpButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    speedUpButton.TextColor3 = Color3.new(1, 1, 1)
    speedUpButton.Parent = controlPanel

    local speedDownButton = Instance.new("TextButton")
    speedDownButton.Name = "SpeedDown"
    speedDownButton.Size = UDim2.new(0, 60, 0, 60)
    speedDownButton.Position = UDim2.new(0.3, 0, 0, 60)
    speedDownButton.Text = "-"
    speedDownButton.TextSize = 30
    speedDownButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    speedDownButton.TextColor3 = Color3.new(1, 1, 1)
    speedDownButton.Parent = controlPanel

    -- 停止按钮
    local stopButton = Instance.new("TextButton")
    stopButton.Name = "Stop"
    stopButton.Size = UDim2.new(0, 100, 0, 40)
    stopButton.Position = UDim2.new(0.5, -50, 0, 130)
    stopButton.Text = "停止移动"
    stopButton.TextSize = 16
    stopButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    stopButton.TextColor3 = Color3.new(1, 1, 1)
    stopButton.Parent = controlPanel

    -- 防旋转按钮
    local fixButton = Instance.new("TextButton")
    fixButton.Name = "FixRotation"
    fixButton.Size = UDim2.new(0, 120, 0, 40)
    fixButton.Position = UDim2.new(0.5, -60, 0, 180)
    fixButton.Text = "防止旋转: 关闭"
    fixButton.TextSize = 16
    fixButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    fixButton.TextColor3 = Color3.new(1, 1, 1)
    fixButton.Parent = controlPanel

    -- 方向控制标签
    local directionLabel = Instance.new("TextLabel")
    directionLabel.Name = "DirectionLabel"
    directionLabel.Size = UDim2.new(1, 0, 0, 40)
    directionLabel.Position = UDim2.new(0, 0, 0, 230)
    directionLabel.Text = "移动方向 (基于视角)"
    directionLabel.TextColor3 = Color3.new(1, 1, 1)
    directionLabel.BackgroundTransparency = 1
    directionLabel.TextSize = 20
    directionLabel.Parent = controlPanel

    -- 方向按钮 - 修复了左右按钮位置
    local directions = {
        {name = "向上", dir = "up", pos = UDim2.new(0.5, -30, 0, 280)},
        {name = "向下", dir = "down", pos = UDim2.new(0.5, -30, 0, 350)},
        {name = "向前", dir = "forward", pos = UDim2.new(0.5, -30, 0, 315)},
        {name = "向后", dir = "back", pos = UDim2.new(0.8, -30, 0, 315)},
        {name = "向左", dir = "left", pos = UDim2.new(0.2, -30, 0, 315)},
        {name = "向右", dir = "right", pos = UDim2.new(0.95, -30, 0, 315)}
    }

    for i, dirInfo in ipairs(directions) do
        local button = Instance.new("TextButton")
        button.Name = dirInfo.name
        button.Size = UDim2.new(0, 60, 0, 60)
        button.Position = dirInfo.pos
        button.Text = dirInfo.name
        button.TextSize = 12
        button.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Parent = controlPanel

        button.MouseButton1Click:Connect(function()
            if _G.isPlayerDead then
                local warningMsg = Instance.new("Message")
                warningMsg.Text = "玩家死亡时无法更改漂浮方向"
                warningMsg.Parent = Workspace
                delay(2, function()
                    warningMsg:Destroy()
                end)
                return
            end
            
            _G.moveDirectionType = dirInfo.dir
            UpdateAllPartsVelocity()

            local originalColor = button.BackgroundColor3
            button.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            delay(0.2, function()
                button.BackgroundColor3 = originalColor
            end)
        end)
    end

    -- 关闭面板按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "ClosePanel"
    closeButton.Size = UDim2.new(0, 100, 0, 40)
    closeButton.Position = UDim2.new(0.5, -50, 0, 430)
    closeButton.Text = "关闭面板"
    closeButton.TextSize = 16
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Parent = controlPanel

    -- 打开面板按钮
    local openPanelButton = Instance.new("TextButton")
    openPanelButton.Name = "OpenPanel"
    openPanelButton.Size = UDim2.new(0, 120, 0, 40)
    openPanelButton.Position = UDim2.new(1, -130, 0, 70)
    openPanelButton.Text = "打开控制面板"
    openPanelButton.TextSize = 14
    openPanelButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    openPanelButton.TextColor3 = Color3.new(1, 1, 1)
    openPanelButton.Parent = screenGui

    -- 按钮事件处理
    mainButton.MouseButton1Click:Connect(function()
        if _G.isPlayerDead then
            local warningMsg = Instance.new("Message")
            warningMsg.Text = "玩家死亡时无法开启漂浮功能"
            warningMsg.Parent = Workspace
            delay(2, function()
                warningMsg:Destroy()
            end)
            return
        end
        
        anActivity = not anActivity
        ProcessAllParts()
        
        if anActivity then
            mainButton.Text = "漂浮: 开启"
            mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        else
            mainButton.Text = "漂浮: 关闭"
            mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)

    speedUpButton.MouseButton1Click:Connect(function()
        if _G.isPlayerDead then return end
        _G.floatSpeed = math.clamp(_G.floatSpeed + 5, 1, 100)
        speedLabel.Text = "速度: " .. _G.floatSpeed
        UpdateAllPartsVelocity()
    end)

    speedDownButton.MouseButton1Click:Connect(function()
        if _G.isPlayerDead then return end
        _G.floatSpeed = math.clamp(_G.floatSpeed - 5, 1, 100)
        speedLabel.Text = "速度: " .. _G.floatSpeed
        UpdateAllPartsVelocity()
    end)

    stopButton.MouseButton1Click:Connect(function()
        if _G.isPlayerDead then return end
        StopAllParts()
    end)

    fixButton.MouseButton1Click:Connect(function()
        if _G.isPlayerDead then return end
        local newFixedState = ToggleRotationPrevention()
        if newFixedState then
            fixButton.Text = "防止旋转: 开启"
            fixButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        else
            fixButton.Text = "防止旋转: 关闭"
            fixButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)

    openPanelButton.MouseButton1Click:Connect(function()
        controlPanel.Visible = not controlPanel.Visible
        if controlPanel.Visible then
            openPanelButton.Text = "关闭控制面板"
        else
            openPanelButton.Text = "打开控制面板"
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        controlPanel.Visible = false
        openPanelButton.Text = "打开控制面板"
    end)
end

-- 延迟创建GUI，确保玩家已加载
delay(1, function()
    CreateMobileGUI()
end)

print("漂浮脚本已加载 - 死亡自动关闭功能已启用")