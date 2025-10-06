local DrawAndBulletModule = {}
DrawAndBulletModule.__index = DrawAndBulletModule

-- 构造函数，创建新实例
function DrawAndBulletModule.new(Window, Library)
    local self = setmetatable({}, DrawAndBulletModule)
    
    -- 实例变量，每个实例都有自己独立的设置和对象
    self.Window = Window
    self.Library = Library
    self.TabDraw = nil
    
    -- 绘制相关设置
    self.drawSettings = {
        enabled = false,
        players = false,
        npcs = false,
        boxes = false,
        names = false,
        distances = false,
        healthbars = false,
        teamColor = false,
        showTools = false,
        showBackpack = false,
        hideEnemies = false,
        hideTeammates = false
    }
    
    self.drawObjects = {}
    self.drawConnections = {}
    self.isRunning = false
    
    -- 瞄准相关设置
    self.aimSettings = {
        enabled = false,
        fovSize = 100,
        aimPart = "头部",
        ignoreTeam = true,
        ignoreEnemy = false,
        ignoreObscured = true,
        ignoreNPC = true,
        ignorePlayers = false,
        smoothness = 1,
        autoAim = true
    }
    
    self.aimbotConnections = {}
    self.isAimbotRunning = false
    self.currentTarget = nil
    self.screenGui = nil
    self.fovCircle = nil
    
    self.partNameMap = {
        ["头部"] = "Head",
        ["身体"] = "HumanoidRootPart",
        ["左手"] = "LeftHand",
        ["右手"] = "RightHand",
        ["左腿"] = "LeftLeg",
        ["右腿"] = "RightLeg",
        ["左脚"] = "LeftFoot",
        ["右脚"] = "RightFoot"
    }
    
    return self
end

-- 创建高亮框
function DrawAndBulletModule:createHighlight(character)
    if not character then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PlayerDrawHighlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    return highlight
end

-- 创建玩家名称标签
function DrawAndBulletModule:createNameTag(player, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerDrawNameTag"
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 0)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = billboard
    
    billboard.Parent = character
    
    return {billboard = billboard, nameLabel = nameLabel, distanceLabel = distanceLabel}
end

-- 创建NPC名称标签
function DrawAndBulletModule:createNPCNameTag(npcName, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NPCDrawNameTag"
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = npcName
    nameLabel.TextColor3 = Color3.new(1, 0, 0)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 0)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = billboard
    
    billboard.Parent = character
    
    return {billboard = billboard, nameLabel = nameLabel, distanceLabel = distanceLabel}
end

-- 创建血条
function DrawAndBulletModule:createHealthBar(character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerDrawHealthBar"
    billboard.Size = UDim2.new(0, 80, 0, 6)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BorderSizePixel = 1
    background.BorderColor3 = Color3.new(1, 1, 1)
    background.Parent = billboard
    
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = background
    
    billboard.Parent = character
    
    return {billboard = billboard, healthBar = healthBar, background = background}
end

-- 创建工具显示
function DrawAndBulletModule:createToolDisplay(character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerDrawTool"
    billboard.Size = UDim2.new(0, 25, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
    
    local toolImage = Instance.new("ImageLabel")
    toolImage.Size = UDim2.new(1, 0, 1, 0)
    toolImage.BackgroundTransparency = 1
    toolImage.Visible = false
    toolImage.Parent = billboard
    
    billboard.Parent = character
    
    return {billboard = billboard, toolImage = toolImage}
end

-- 创建背包显示
function DrawAndBulletModule:createBackpackDisplay(character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerDrawBackpack"
    billboard.Size = UDim2.new(0, 80, 0, 25)
    billboard.StudsOffset = Vector3.new(1.5, 0.8, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character.PrimaryPart
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 0.8
    container.BackgroundColor3 = Color3.new(0, 0, 0)
    container.Parent = billboard
    
    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Horizontal
    uiListLayout.Padding = UDim.new(0, 2)
    uiListLayout.Parent = container
    
    billboard.Parent = character
    
    return {billboard = billboard, container = container, uiListLayout = uiListLayout}
end

-- 获取装备的工具
function DrawAndBulletModule:getEquippedTool(character)
    if not character then return nil end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Parent == character then
            return tool
        end
    end
    
    return nil
end

-- 获取玩家背包图标
function DrawAndBulletModule:getPlayerBackpackIcons(player)
    if not player then return {} end
    
    local icons = {}
    local backpack = player:FindFirstChild("Backpack")
    
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(icons, item.TextureId or "rbxasset://textures/ui/Toolbox/Toolbox_Icon.png")
            end
        end
    end
    
    return icons
end

-- 判断是否为NPC
function DrawAndBulletModule:isNPC(model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character == model then
            return false
        end
    end
    
    return true
end

-- 判断是否为敌人
function DrawAndBulletModule:isEnemy(player)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return true
    end
    
    return localPlayer.Team ~= player.Team
end

-- 判断是否为队友
function DrawAndBulletModule:isTeammate(player)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return false
    end
    
    return localPlayer.Team == player.Team
end

-- 判断是否应该绘制该玩家
function DrawAndBulletModule:shouldDrawPlayer(player)
    if not self.drawSettings.players then
        return false
    end
    
    if self.drawSettings.hideEnemies and self:isEnemy(player) then
        return false
    end
    
    if self.drawSettings.hideTeammates and self:isTeammate(player) then
        return false
    end
    
    return true
end

-- 更新绘制
function DrawAndBulletModule:updateDrawings()
    if not self.drawSettings.enabled or not self.isRunning then return end
    
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    
    if not localRoot then return end
    
    -- 绘制玩家
    if self.drawSettings.players then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer and self:shouldDrawPlayer(player) then
                local character = player.Character
                
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and rootPart and humanoid.Health > 0 then
                        local distance = (localRoot.Position - rootPart.Position).Magnitude
                        
                        if not self.drawObjects[player] then
                            self.drawObjects[player] = {}
                        end
                        
                        -- 方框绘制
                        if self.drawSettings.boxes then
                            if not self.drawObjects[player].highlight then
                                self.drawObjects[player].highlight = self:createHighlight(character)
                            end
                            
                            local highlight = self.drawObjects[player].highlight
                            if highlight then
                                highlight.Enabled = true
                                
                                if self.drawSettings.teamColor and player.Team then
                                    highlight.FillColor = player.Team.TeamColor.Color
                                else
                                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                                end
                            end
                        else
                            if self.drawObjects[player].highlight then
                                self.drawObjects[player].highlight.Enabled = false
                            end
                        end
                        
                        -- 名称和距离
                        if self.drawSettings.names or self.drawSettings.distances then
                            if not self.drawObjects[player].nameTag then
                                self.drawObjects[player].nameTag = self:createNameTag(player, character)
                            end
                            
                            local nameTag = self.drawObjects[player].nameTag
                            if nameTag then
                                nameTag.billboard.Enabled = true
                                
                                if self.drawSettings.names then
                                    nameTag.nameLabel.Visible = true
                                    if self.drawSettings.teamColor and player.Team then
                                        nameTag.nameLabel.TextColor3 = player.Team.TeamColor.Color
                                    else
                                        nameTag.nameLabel.TextColor3 = Color3.new(1, 1, 1)
                                    end
                                else
                                    nameTag.nameLabel.Visible = false
                                end
                                
                                if self.drawSettings.distances then
                                    nameTag.distanceLabel.Visible = true
                                    nameTag.distanceLabel.Text = string.format("[%d]", math.floor(distance))
                                else
                                    nameTag.distanceLabel.Visible = false
                                end
                            end
                        else
                            if self.drawObjects[player].nameTag then
                                self.drawObjects[player].nameTag.billboard.Enabled = false
                            end
                        end
                        
                        -- 血条
                        if self.drawSettings.healthbars then
                            if not self.drawObjects[player].healthBar then
                                self.drawObjects[player].healthBar = self:createHealthBar(character)
                            end
                            
                            local healthBar = self.drawObjects[player].healthBar
                            if healthBar then
                                healthBar.billboard.Enabled = true
                                
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                healthBar.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                                
                                if healthPercent > 0.5 then
                                    healthBar.healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
                                elseif healthPercent > 0.25 then
                                    healthBar.healthBar.BackgroundColor3 = Color3.new(1, 1, 0)
                                else
                                    healthBar.healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
                                end
                            end
                        else
                            if self.drawObjects[player].healthBar then
                                self.drawObjects[player].healthBar.billboard.Enabled = false
                            end
                        end
                        
                        -- 工具显示
                        if self.drawSettings.showTools then
                            if not self.drawObjects[player].toolDisplay then
                                self.drawObjects[player].toolDisplay = self:createToolDisplay(character)
                            end
                            
                            local toolDisplay = self.drawObjects[player].toolDisplay
                            if toolDisplay then
                                local equippedTool = self:getEquippedTool(character)
                                if equippedTool then
                                    toolDisplay.billboard.Enabled = true
                                    toolDisplay.toolImage.Image = equippedTool.TextureId or "rbxasset://textures/ui/Toolbox/Toolbox_Icon.png"
                                    toolDisplay.toolImage.Visible = true
                                else
                                    toolDisplay.billboard.Enabled = false
                                    toolDisplay.toolImage.Visible = false
                                end
                            end
                        else
                            if self.drawObjects[player].toolDisplay then
                                self.drawObjects[player].toolDisplay.billboard.Enabled = false
                            end
                        end
                        
                        -- 背包显示
                        if self.drawSettings.showBackpack then
                            if not self.drawObjects[player].backpackDisplay then
                                self.drawObjects[player].backpackDisplay = self:createBackpackDisplay(character)
                            end
                            
                            local backpackDisplay = self.drawObjects[player].backpackDisplay
                            if backpackDisplay then
                                backpackDisplay.billboard.Enabled = true
                                
                                for _, child in ipairs(backpackDisplay.container:GetChildren()) do
                                    if child:IsA("ImageLabel") then
                                        child:Destroy()
                                    end
                                end
                                
                                local backpackIcons = self:getPlayerBackpackIcons(player)
                                for i, icon in ipairs(backpackIcons) do
                                    if i <= 3 then
                                        local imageLabel = Instance.new("ImageLabel")
                                        imageLabel.Size = UDim2.new(0, 20, 0, 20)
                                        imageLabel.BackgroundTransparency = 1
                                        imageLabel.Image = icon
                                        imageLabel.Parent = backpackDisplay.container
                                    end
                                end
                            end
                        else
                            if self.drawObjects[player].backpackDisplay then
                                self.drawObjects[player].backpackDisplay.billboard.Enabled = false
                            end
                        end
                    else
                        if self.drawObjects[player] then
                            if self.drawObjects[player].highlight then
                                self.drawObjects[player].highlight.Enabled = false
                            end
                            if self.drawObjects[player].nameTag then
                                self.drawObjects[player].nameTag.billboard.Enabled = false
                            end
                            if self.drawObjects[player].healthBar then
                                self.drawObjects[player].healthBar.billboard.Enabled = false
                            end
                            if self.drawObjects[player].toolDisplay then
                                self.drawObjects[player].toolDisplay.billboard.Enabled = false
                            end
                            if self.drawObjects[player].backpackDisplay then
                                self.drawObjects[player].backpackDisplay.billboard.Enabled = false
                            end
                        end
                    end
                else
                    if self.drawObjects[player] then
                        if self.drawObjects[player].highlight then
                            self.drawObjects[player].highlight:Destroy()
                        end
                        if self.drawObjects[player].nameTag then
                            self.drawObjects[player].nameTag.billboard:Destroy()
                        end
                        if self.drawObjects[player].healthBar then
                            self.drawObjects[player].healthBar.billboard:Destroy()
                        end
                        if self.drawObjects[player].toolDisplay then
                            self.drawObjects[player].toolDisplay.billboard:Destroy()
                        end
                        if self.drawObjects[player].backpackDisplay then
                            self.drawObjects[player].backpackDisplay.billboard:Destroy()
                        end
                        self.drawObjects[player] = nil
                    end
                end
            end
        end
    end
    
    -- 绘制NPC
    if self.drawSettings.npcs then
        for _, model in ipairs(workspace:GetDescendants()) do
            if self:isNPC(model) then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local rootPart = model:FindFirstChild("HumanoidRootPart")
                
                if humanoid and rootPart and humanoid.Health > 0 then
                    local distance = (localRoot.Position - rootPart.Position).Magnitude
                    
                    if not self.drawObjects[model] then
                        self.drawObjects[model] = {}
                    end
                    
                    if self.drawSettings.boxes then
                        if not self.drawObjects[model].highlight then
                            self.drawObjects[model].highlight = self:createHighlight(model)
                            self.drawObjects[model].highlight.FillColor = Color3.new(1, 0, 0)
                        end
                        self.drawObjects[model].highlight.Enabled = true
                    else
                        if self.drawObjects[model].highlight then
                            self.drawObjects[model].highlight.Enabled = false
                        end
                    end
                    
                    if self.drawSettings.names or self.drawSettings.distances then
                        if not self.drawObjects[model].nameTag then
                            self.drawObjects[model].nameTag = self:createNPCNameTag(model.Name, model)
                        end
                        
                        local nameTag = self.drawObjects[model].nameTag
                        if nameTag then
                            nameTag.billboard.Enabled = true
                            
                            if self.drawSettings.names then
                                nameTag.nameLabel.Visible = true
                                nameTag.nameLabel.TextColor3 = Color3.new(1, 0, 0)
                            else
                                nameTag.nameLabel.Visible = false
                            end
                            
                            if self.drawSettings.distances then
                                nameTag.distanceLabel.Visible = true
                                nameTag.distanceLabel.Text = string.format("[%d]", math.floor(distance))
                            else
                                nameTag.distanceLabel.Visible = false
                            end
                        end
                    else
                        if self.drawObjects[model].nameTag then
                            self.drawObjects[model].nameTag.billboard.Enabled = false
                        end
                    end
                    
                    if self.drawSettings.healthbars then
                        if not self.drawObjects[model].healthBar then
                            self.drawObjects[model].healthBar = self:createHealthBar(model)
                        end
                        
                        local healthBar = self.drawObjects[model].healthBar
                        if healthBar then
                            healthBar.billboard.Enabled = true
                            
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            healthBar.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                            
                            if healthPercent > 0.5 then
                                healthBar.healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
                            elseif healthPercent > 0.25 then
                                healthBar.healthBar.BackgroundColor3 = Color3.new(1, 1, 0)
                            else
                                healthBar.healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
                            end
                        end
                    else
                        if self.drawObjects[model].healthBar then
                            self.drawObjects[model].healthBar.billboard.Enabled = false
                        end
                    end
                else
                    if self.drawObjects[model] then
                        if self.drawObjects[model].highlight then
                            self.drawObjects[model].highlight.Enabled = false
                        end
                        if self.drawObjects[model].nameTag then
                            self.drawObjects[model].nameTag.billboard.Enabled = false
                        end
                        if self.drawObjects[model].healthBar then
                            self.drawObjects[model].healthBar.billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- 清除绘制
function DrawAndBulletModule:clearDrawings()
    for key, objects in pairs(self.drawObjects) do
        if objects.highlight then
            objects.highlight:Destroy()
        end
        if objects.nameTag then
            objects.nameTag.billboard:Destroy()
        end
        if objects.healthBar then
            objects.healthBar.billboard:Destroy()
        end
        if objects.toolDisplay then
            objects.toolDisplay.billboard:Destroy()
        end
        if objects.backpackDisplay then
            objects.backpackDisplay.billboard:Destroy()
        end
    end
    self.drawObjects = {}
    
    for _, connection in pairs(self.drawConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.drawConnections = {}
end

-- 更新FOV圆圈
function DrawAndBulletModule:updateFOVCircle()
    if self.fovCircle and self.fovCircle.Parent then
        self.fovCircle.Size = UDim2.new(0, self.aimSettings.fovSize * 2, 0, self.aimSettings.fovSize * 2)
    end
end

-- 获取最近的目标
function DrawAndBulletModule:getClosestTarget()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter then return nil end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    local camera = workspace.CurrentCamera
    local closestTarget = nil
    local closestDistance = self.aimSettings.fovSize
    
    -- 查找玩家目标
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player == localPlayer then continue end
        
        if self.aimSettings.ignoreTeam and player.Team == localPlayer.Team then continue end
        if self.aimSettings.ignoreEnemy and player.Team ~= localPlayer.Team then continue end
        if self.aimSettings.ignorePlayers then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart and humanoid.Health > 0 then
            local screenPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            
            if onScreen then
                local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                
                if distance <= closestDistance then
                    if self.aimSettings.ignoreObscured then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                        raycastParams.FilterDescendantsInstances = {localCharacter, character}
                        
                        local raycastResult = workspace:Raycast(
                            camera.CFrame.Position,
                            (rootPart.Position - camera.CFrame.Position),
                            raycastParams
                        )
                        
                        if not raycastResult then
                            closestTarget = character
                            closestDistance = distance
                        end
                    else
                        closestTarget = character
                        closestDistance = distance
                    end
                end
            end
        end
    end
    
    -- 查找NPC目标
    if not closestTarget and not self.aimSettings.ignoreNPC then
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                local isPlayerCharacter = false
                for _, player in ipairs(game.Players:GetPlayers()) do
                    if player.Character == model then
                        isPlayerCharacter = true
                        break
                    end
                end
                
                if not isPlayerCharacter then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    local rootPart = model:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and rootPart and humanoid.Health > 0 then
                        local screenPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                        
                        if onScreen then
                            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
                            
                            if distance <= closestDistance then
                                if self.aimSettings.ignoreObscured then
                                    local raycastParams = RaycastParams.new()
                                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                                    raycastParams.FilterDescendantsInstances = {localCharacter, model}
                                    
                                    local raycastResult = workspace:Raycast(
                                        camera.CFrame.Position,
                                        (rootPart.Position - camera.CFrame.Position),
                                        raycastParams
                                    )
                                    
                                    if not raycastResult then
                                        closestTarget = model
                                        closestDistance = distance
                                    end
                                else
                                    closestTarget = model
                                    closestDistance = distance
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

-- 瞄准目标
function DrawAndBulletModule:aimAtTarget(target)
    if not target then return end
    
    local camera = workspace.CurrentCamera
    local englishPartName = self.partNameMap[self.aimSettings.aimPart] or "Head"
    local aimPart = target:FindFirstChild(englishPartName)
    
    if not aimPart then
        aimPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("Head")
    end
    
    if aimPart then
        local currentCFrame = camera.CFrame
        local targetPosition = aimPart.Position
        
        local smoothness = math.max(0.1, self.aimSettings.smoothness)
        local newCFrame = currentCFrame:Lerp(
            CFrame.lookAt(currentCFrame.Position, targetPosition),
            1 / smoothness
        )
        
        camera.CFrame = newCFrame
    end
end

-- 瞄准循环
function DrawAndBulletModule:aimbotLoop()
    if not self.aimSettings.enabled or not self.isAimbotRunning then return end
    
    if self.aimSettings.autoAim then
        self.currentTarget = self:getClosestTarget()
        if self.currentTarget then
            self:aimAtTarget(self.currentTarget)
        end
    end
end

-- 开始瞄准
function DrawAndBulletModule:startAimbot()
    if self.isAimbotRunning then return end
    
    self.isAimbotRunning = true
    if self.fovCircle then
        self.fovCircle.Visible = self.aimSettings.enabled
    end
    
    self.aimbotConnections.renderStepped = game:GetService("RunService").RenderStepped:Connect(function()
        self:aimbotLoop()
    end)
    
    game:GetService("CoreGui"):SetCore("SendNotification", {
        Title = "瞄准功能",
        Text = "瞄准功能已启用",
        Duration = 3,
    })
end

-- 停止瞄准
function DrawAndBulletModule:stopAimbot()
    self.isAimbotRunning = false
    self.currentTarget = nil
    if self.fovCircle then
        self.fovCircle.Visible = false
    end
    
    for _, connection in pairs(self.aimbotConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.aimbotConnections = {}
    
    game:GetService("CoreGui"):SetCore("SendNotification", {
        Title = "瞄准功能",
        Text = "瞄准功能已禁用",
        Duration = 3,
    })
end

-- 创建UI并加载标签页
function DrawAndBulletModule:LoadDrawAndBulletTab()
    self.TabDraw = self.Window:Tab("绘制与子弹", '5436396975')
    local SectionDraw1 = self.TabDraw:section("绘制开关", true)
    local SectionDraw = self.TabDraw:section("绘制选项", true)
    
    -- 绘制开关
    SectionDraw1:Toggle("启用绘制", "EnableDrawing", false, function(state)
        self.drawSettings.enabled = state
        
        if state then
            self.isRunning = true
            self.drawConnections.renderStepped = game:GetService("RunService").RenderStepped:Connect(function()
                self:updateDrawings()
            end)
            
            game:GetService("CoreGui"):SetCore("SendNotification", {
                Title = "绘制功能",
                Text = "绘制功能已启用",
                Duration = 3,
            })
        else
            self.isRunning = false
            self:clearDrawings()
            game:GetService("CoreGui"):SetCore("SendNotification", {
                Title = "绘制功能",
                Text = "绘制功能已禁用",
                Duration = 3,
            })
        end
    end)
    
    SectionDraw1:Toggle("绘制玩家", "DrawPlayers", false, function(state)
        self.drawSettings.players = state
        if not state then
            for player, objects in pairs(self.drawObjects) do
                if typeof(player) == "Instance" and player:IsA("Player") then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    if objects.toolDisplay then objects.toolDisplay.billboard:Destroy() end
                    if objects.backpackDisplay then objects.backpackDisplay.billboard:Destroy() end
                    self.drawObjects[player] = nil
                end
            end
        end
    end)
    
    SectionDraw1:Toggle("绘制NPC", "DrawNPCs", false, function(state)
        self.drawSettings.npcs = state
        if not state then
            for model, objects in pairs(self.drawObjects) do
                if typeof(model) == "Instance" and model:IsA("Model") and not model:FindFirstChildOfClass("Player") then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    self.drawObjects[model] = nil
                end
            end
        end
    end)
    
    SectionDraw1:Toggle("不显示敌对玩家", "HideEnemies", false, function(state)
        self.drawSettings.hideEnemies = state
        if state then
            for player, objects in pairs(self.drawObjects) do
                if typeof(player) == "Instance" and player:IsA("Player") and self:isEnemy(player) then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    if objects.toolDisplay then objects.toolDisplay.billboard:Destroy() end
                    if objects.backpackDisplay then objects.backpackDisplay.billboard:Destroy() end
                    self.drawObjects[player] = nil
                end
            end
        end
    end)
    
    SectionDraw1:Toggle("不显示我方玩家", "HideTeammates", false, function(state)
        self.drawSettings.hideTeammates = state
        if state then
            for player, objects in pairs(self.drawObjects) do
                if typeof(player) == "Instance" and player:IsA("Player") and self:isTeammate(player) then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    if objects.toolDisplay then objects.toolDisplay.billboard:Destroy() end
                    if objects.backpackDisplay then objects.backpackDisplay.billboard:Destroy() end
                    self.drawObjects[player] = nil
                end
            end
        end
    end)
    
    -- 绘制选项
    SectionDraw:Toggle("显示方框", "ShowBoxes", false, function(state)
        self.drawSettings.boxes = state
    end)
    
    SectionDraw:Toggle("显示名称", "ShowNames", false, function(state)
        self.drawSettings.names = state
    end)
    
    SectionDraw:Toggle("显示距离", "ShowDistances", false, function(state)
        self.drawSettings.distances = state
    end)
    
    SectionDraw:Toggle("显示血条", "ShowHealthbars", false, function(state)
        self.drawSettings.healthbars = state
    end)
    
    SectionDraw:Toggle("队伍颜色", "UseTeamColor", false, function(state)
        self.drawSettings.teamColor = state
    end)
    
    SectionDraw:Toggle("显示手中道具", "ShowTools", false, function(state)
        self.drawSettings.showTools = state
    end)
    
    SectionDraw:Toggle("显示道具栏", "ShowBackpack", false, function(state)
        self.drawSettings.showBackpack = state
    end)
    
    -- 瞄准相关
    local SectionAim2 = self.TabDraw:section("瞄准开关", true)
    local SectionAim3 = self.TabDraw:section("瞄准选项", true)
    
    -- 创建FOV UI
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "AimbotFOV_" .. tostring(math.random(100000, 999999)) -- 随机名称避免冲突
    self.screenGui.Parent = game.CoreGui
    self.screenGui.ResetOnSpawn = false
    
    self.fovCircle = Instance.new("Frame")
    self.fovCircle.Name = "FOVCircle"
    self.fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    self.fovCircle.Size = UDim2.new(0, self.aimSettings.fovSize * 2, 0, self.aimSettings.fovSize * 2)
    self.fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.fovCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self.fovCircle.BackgroundTransparency = 0.7
    self.fovCircle.BorderSizePixel = 0
    self.fovCircle.Visible = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = self.fovCircle
    self.fovCircle.Parent = self.screenGui
    
    -- 瞄准开关
    SectionAim2:Toggle("启用瞄准", "EnableAimbot", false, function(state)
        self.aimSettings.enabled = state
        
        if state then
            self:startAimbot()
        else
            self:stopAimbot()
        end
    end)
    
    SectionAim2:Dropdown("瞄准部位", "AimPart", {
        "头部", 
        "身体", 
        "左手", 
        "右手", 
        "左腿", 
        "右腿",
        "左脚", 
        "右脚"
    }, function(selected)
        self.aimSettings.aimPart = selected
    end)
    
    -- 瞄准选项
    SectionAim3:Toggle("忽略队友", "IgnoreTeam", true, function(state)
        self.aimSettings.ignoreTeam = state
    end)
    
    SectionAim3:Toggle("忽略敌人", "IgnoreEnemy", false, function(state)
        self.aimSettings.ignoreEnemy = state
    end)
    
    SectionAim3:Toggle("忽略被遮挡", "IgnoreObscured", true, function(state)
        self.aimSettings.ignoreObscured = state
    end)
    
    SectionAim3:Toggle("忽略NPC", "IgnoreNPC", true, function(state)
        self.aimSettings.ignoreNPC = state
    end)
    
    SectionAim3:Toggle("忽略真人", "IgnorePlayers", false, function(state)
        self.aimSettings.ignorePlayers = state
    end)
    
    SectionAim3:Slider("瞄准平滑度", "AimSmoothness", 1, 10, 1, function(value)
        self.aimSettings.smoothness = value
    end)
    
    -- 子弹追踪
    local SectionAim4 = self.TabDraw:section("子弹追踪", true)
    
    SectionAim4:Button("启用子追(这个太特殊了无法进行更新)", function()
        local Camera = game:GetService("Workspace").CurrentCamera
        local Players = game:GetService("Players")
        local LocalPlayer = game:GetService("Players").LocalPlayer
        
        local function GetClosestPlayer()
            local ClosestPlayer = nil
            local FarthestDistance = math.huge
            for i, v in pairs(Players.GetPlayers(Players)) do
                if v ~= LocalPlayer and v.Character and v.Character.FindFirstChild(v.Character, "HumanoidRootPart") then
                    local DistanceFromPlayer = (LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if DistanceFromPlayer < FarthestDistance then
                        FarthestDistance = DistanceFromPlayer
                        ClosestPlayer = v
                    end
                end
            end
            if ClosestPlayer then return ClosestPlayer end
        end
        
        local GameMetaTable = getrawmetatable(game)
        local OldGameMetaTableNamecall = GameMetaTable.__namecall
        setreadonly(GameMetaTable, false)
        
        GameMetaTable.__namecall = newcclosure(function(object, ...)
            local NamecallMethod = getnamecallmethod()
            local Arguments = {...}
            if tostring(NamecallMethod) == "FindPartOnRayWithIgnoreList" then
                local ClosestPlayer = GetClosestPlayer()
                if ClosestPlayer and ClosestPlayer.Character then
                    Arguments[1] = Ray.new(Camera.CFrame.Position, (ClosestPlayer.Character.Head.Position - Camera.CFrame.Position).Unit * (Camera.CFrame.Position - ClosestPlayer.Character.Head.Position).Magnitude)
                end
            end
            return OldGameMetaTableNamecall(object, unpack(Arguments))
        end)
        
        setreadonly(GameMetaTable, true)
    end)
    
    -- 事件连接
    game.Players.PlayerRemoving:Connect(function(player)
        if self.drawObjects[player] then
            if self.drawObjects[player].highlight then
                self.drawObjects[player].highlight:Destroy()
            end
            if self.drawObjects[player].nameTag then
                self.drawObjects[player].nameTag.billboard:Destroy()
            end
            if self.drawObjects[player].healthBar then
                self.drawObjects[player].healthBar.billboard:Destroy()
            end
            if self.drawObjects[player].toolDisplay then
                self.drawObjects[player].toolDisplay.billboard:Destroy()
            end
            if self.drawObjects[player].backpackDisplay then
                self.drawObjects[player].backpackDisplay.billboard:Destroy()
            end
            self.drawObjects[player] = nil
        end
    end)
    
    game.Players.LocalPlayer.CharacterAdded:Connect(function()
        if self.drawSettings.enabled then
            task.wait(2)
            self:clearDrawings()
        end
        
        if self.aimSettings.enabled then
            task.wait(2)
            if self.fovCircle then
                self.fovCircle.Visible = true
            end
            if not self.isAimbotRunning then
                self:startAimbot()
            end
        end
    end)
    
    game:GetService("RunService").Heartbeat:Connect(function()
        if self.aimSettings.enabled and self.fovCircle and self.fovCircle.Visible then
            self:updateFOVCircle()
        end
    end)
    
    if not self.drawSettings.enabled then
        self:clearDrawings()
    end
    
    if self.aimSettings.enabled then
        self:startAimbot()
    else
        self:stopAimbot()
    end
    
    return self.TabDraw
end

-- 销毁实例，清理资源
function DrawAndBulletModule:Destroy()
    self:clearDrawings()
    self:stopAimbot()
    
    if self.screenGui then
        self.screenGui:Destroy()
    end
    
    if self.TabDraw then
        -- 如果库支持，尝试移除标签页
        pcall(function()
            self.Window:RemoveTab(self.TabDraw)
        end)
    end
end

return DrawAndBulletModule
