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
authorMessage.Text = "全局物体漂浮脚本 - 作者: XTTT\n死亡自动关闭功能已修复"
authorMessage.Parent = Workspace
delay(3, function()
    authorMessage:Destroy()
end)

-- 全局变量
local processedParts = {}
local floatSpeed = 10
local moveDirectionType = "up"
local fixedMode = false
local anActivity = false
local updateConnection = nil

-- 死亡状态跟踪
local isPlayerDead = false
local humanoidDiedConnection = nil
local characterAddedConnection = nil

-- 死亡检测系统
local function setupDeathDetection()
    local function onCharacterAdded(character)
        isPlayerDead = false
        
        local humanoid = character:WaitForChild("Humanoid")
        
        -- 清理旧的连接
        if humanoidDiedConnection then
            humanoidDiedConnection:Disconnect()
        end
        
        humanoidDiedConnection = humanoid.Died:Connect(function()
            isPlayerDead = true
            print("玩家死亡，关闭漂浮功能")
            
            -- 关闭漂浮功能
            anActivity = false
            
            -- 清理所有处理的零件
            for part, data in pairs(processedParts) do
                if data.bodyVelocity and data.bodyVelocity.Parent then
                    data.bodyVelocity:Destroy()
                end
                if data.bodyGyro and data.bodyGyro.Parent then
                    data.bodyGyro:Destroy()
                end
            end
            processedParts = {}
            
            -- 停止更新循环
            if updateConnection then
                updateConnection:Disconnect()
                updateConnection = nil
            end
            
            -- 更新GUI状态
            if mainButton then
                mainButton.Text = "漂浮: 关闭"
                mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
            
            -- 显示死亡提示
            local deathMsg = Instance.new("Message")
            deathMsg.Text = "玩家死亡，漂浮功能已自动关闭"
            deathMsg.Parent = Workspace
            delay(3, function()
                deathMsg:Destroy()
            end)
        end)
    end
    
    -- 监听角色添加
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
    end
    
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
    -- 处理现有角色
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
end

-- 计算移动方向
local function calculateMoveDirection()
    if isPlayerDead then
        return Vector3.new(0, 0, 0)
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return Vector3.new(0, 1, 0) end

    if moveDirectionType == "up" then
        return Vector3.new(0, 1, 0)
    elseif moveDirectionType == "down" then
        return Vector3.new(0, -1, 0)
    elseif moveDirectionType == "forward" then
        local lookVector = camera.CFrame.LookVector
        return Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    elseif moveDirectionType == "back" then
        local lookVector = camera.CFrame.LookVector
        return -Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    elseif moveDirectionType == "right" then
        local rightVector = camera.CFrame.RightVector
        return Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    elseif moveDirectionType == "left" then
        local rightVector = camera.CFrame.RightVector
        return -Vector3.new(rightVector.X, 0, rightVector.Z).Unit
    else
        return Vector3.new(0, 1, 0)
    end
end

-- 处理单个零件
local function processPart(part)
    if isPlayerDead then return end
    
    if part:IsA("Part") and not part.Anchored and not part.Parent:FindFirstChild("Humanoid") then
        if processedParts[part] then
            local data = processedParts[part]
            if data.bodyVelocity and data.bodyVelocity.Parent then
                data.bodyVelocity.Velocity = calculateMoveDirection() * floatSpeed
                return
            else
                processedParts[part] = nil
            end
        end

        -- 清理现有的物理效果
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("BodyVelocity") or child:IsA("BodyGyro") or child:IsA("BodyForce") then
                child:Destroy()
            end
        end

        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = calculateMoveDirection() * floatSpeed
        bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
        bodyVelocity.Parent = part
        
        local bodyGyro = nil
        if fixedMode then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
            bodyGyro.P = 1000
            bodyGyro.D = 100
            bodyGyro.Parent = part
        end
        
        processedParts[part] = {
            bodyVelocity = bodyVelocity,
            bodyGyro = bodyGyro
        }
    end
end

-- 清理所有零件
local function cleanupParts()
    for part, data in pairs(processedParts) do
        if data.bodyVelocity then
            data.bodyVelocity:Destroy()
        end
        if data.bodyGyro then
            data.bodyGyro:Destroy()
        end
    end
    processedParts = {}
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
end

-- 更新所有零件速度
local function updateAllParts()
    if isPlayerDead then
        cleanupParts()
        return
    end
    
    local direction = calculateMoveDirection()
    for part, data in pairs(processedParts) do
        if data.bodyVelocity and data.bodyVelocity.Parent then
            data.bodyVelocity.Velocity = direction * floatSpeed
        end
    end
end

-- 停止所有零件
local function stopAllParts()
    floatSpeed = 0
    updateAllParts()
end

-- 切换防旋转模式
local function toggleRotationPrevention()
    fixedMode = not fixedMode
    
    for part, data in pairs(processedParts) do
        if fixedMode then
            if not data.bodyGyro or not data.bodyGyro.Parent then
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
                bodyGyro.P = 1000
                bodyGyro.D = 100
                bodyGyro.Parent = part
                data.bodyGyro = bodyGyro
            end
        else
            if data.bodyGyro and data.bodyGyro.Parent then
                data.bodyGyro:Destroy()
                data.bodyGyro = nil
            end
        end
    end
    
    return fixedMode
end

-- 创建可拖动GUI函数
local function makeDraggable(gui)
    gui.Active = true
    gui.Draggable = true
end

-- 主GUI创建函数
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FloatingControl"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- 主开关按钮
    local mainButton = Instance.new("TextButton")
    mainButton.Name = "MainButton"
    mainButton.Size = UDim2.new(0, 120, 0, 50)
    mainButton.Position = UDim2.new(0, 10, 0, 10)
    mainButton.Text = "漂浮: 关闭"
    mainButton.TextSize = 16
    mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    mainButton.TextColor3 = Color3.new(1, 1, 1)
    mainButton.Parent = screenGui
    makeDraggable(mainButton)

    -- 控制面板
    local controlPanel = Instance.new("Frame")
    controlPanel.Name = "ControlPanel"
    controlPanel.Size = UDim2.new(0, 200, 0, 300)
    controlPanel.Position = UDim2.new(0, 140, 0, 10)
    controlPanel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    controlPanel.BackgroundTransparency = 0.2
    controlPanel.Visible = false
    controlPanel.Parent = screenGui
    makeDraggable(controlPanel)

    -- 速度标签
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, 0, 0, 30)
    speedLabel.Position = UDim2.new(0, 0, 0, 10)
    speedLabel.Text = "速度: " .. floatSpeed
    speedLabel.TextColor3 = Color3.new(1, 1, 1)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextSize = 16
    speedLabel.Parent = controlPanel

    -- 速度控制按钮
    local speedUp = Instance.new("TextButton")
    speedUp.Size = UDim2.new(0, 40, 0, 40)
    speedUp.Position = UDim2.new(0.7, 0, 0, 50)
    speedUp.Text = "+"
    speedUp.TextSize = 20
    speedUp.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    speedUp.Parent = controlPanel

    local speedDown = Instance.new("TextButton")
    speedDown.Size = UDim2.new(0, 40, 0, 40)
    speedDown.Position = UDim2.new(0.3, 0, 0, 50)
    speedDown.Text = "-"
    speedDown.TextSize = 20
    speedDown.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    speedDown.Parent = controlPanel

    -- 方向按钮
    local directions = {
        {name = "上", dir = "up", pos = UDim2.new(0.5, -20, 0, 100)},
        {name = "下", dir = "down", pos = UDim2.new(0.5, -20, 0, 150)},
        {name = "前", dir = "forward", pos = UDim2.new(0.2, -20, 0, 125)},
        {name = "后", dir = "back", pos = UDim2.new(0.8, -20, 0, 125)}
    }

    for _, dir in ipairs(directions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.Position = dir.pos
        btn.Text = dir.name
        btn.TextSize = 14
        btn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
        btn.Parent = controlPanel
        
        btn.MouseButton1Click:Connect(function()
            if isPlayerDead then return end
            moveDirectionType = dir.dir
            updateAllParts()
        end)
    end

    -- 防旋转按钮
    local fixBtn = Instance.new("TextButton")
    fixBtn.Size = UDim2.new(0, 80, 0, 30)
    fixBtn.Position = UDim2.new(0.5, -40, 0, 200)
    fixBtn.Text = "防旋转: 关"
    fixBtn.TextSize = 12
    fixBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    fixBtn.Parent = controlPanel

    -- 面板开关按钮
    local panelBtn = Instance.new("TextButton")
    panelBtn.Size = UDim2.new(0, 120, 0, 30)
    panelBtn.Position = UDim2.new(0, 0, 0, 70)
    panelBtn.Text = "打开控制面板"
    panelBtn.TextSize = 12
    panelBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    panelBtn.Parent = screenGui
    makeDraggable(panelBtn)

    -- 按钮事件
    mainButton.MouseButton1Click:Connect(function()
        if isPlayerDead then
            local msg = Instance.new("Message")
            msg.Text = "玩家死亡时无法开启漂浮"
            msg.Parent = Workspace
            delay(2, function() msg:Destroy() end)
            return
        end
        
        anActivity = not anActivity
        
        if anActivity then
            mainButton.Text = "漂浮: 开启"
            mainButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            
            -- 开始处理零件
            for _, part in ipairs(Workspace:GetDescendants()) do
                processPart(part)
            end
            
            updateConnection = RunService.Heartbeat:Connect(updateAllParts)
        else
            mainButton.Text = "漂浮: 关闭"
            mainButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            cleanupParts()
        end
    end)

    speedUp.MouseButton1Click:Connect(function()
        if isPlayerDead then return end
        floatSpeed = math.min(floatSpeed + 5, 100)
        speedLabel.Text = "速度: " .. floatSpeed
        updateAllParts()
    end)

    speedDown.MouseButton1Click:Connect(function()
        if isPlayerDead then return end
        floatSpeed = math.max(floatSpeed - 5, 1)
        speedLabel.Text = "速度: " .. floatSpeed
        updateAllParts()
    end)
    
    fixBtn.MouseButton1Click:Connect(function()
        if isPlayerDead then return end
        local state = toggleRotationPrevention()
        fixBtn.Text = state and "防旋转: 开" or "防旋转: 关"
        fixBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 100, 100)
    end)

    panelBtn.MouseButton1Click:Connect(function()
        controlPanel.Visible = not controlPanel.Visible
        panelBtn.Text = controlPanel.Visible and "关闭控制面板" or "打开控制面板"
    end)

    -- 监听新零件添加
    Workspace.DescendantAdded:Connect(function(descendant)
        if anActivity and not isPlayerDead then
            processPart(descendant)
        end
    end)

    return mainButton
end

-- 初始化脚本
local function initialize()
    -- 先设置死亡检测
    setupDeathDetection()
    
    -- 然后创建GUI
    local mainButton = createGUI()
    
    print("漂浮脚本加载完成，死亡检测已启用")
end

-- 启动脚本
initialize()
