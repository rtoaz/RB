-- 绘制与子弹模块（无冲突版）
local DrawAndBulletModule = {}
DrawAndBulletModule.__index = DrawAndBulletModule

-- 生成唯一ID（避免全局命名冲突）
local function generateUniqueId(prefix)
    return prefix .. "_" .. tostring(math.random(1000000, 9999999)) .. "_" .. os.time()
end

-- 构造函数：创建独立实例（每个实例完全隔离）
function DrawAndBulletModule.new(Window, Library)
    local self = setmetatable({}, DrawAndBulletModule)
    
    -- 1. 实例唯一标识（核心：避免多实例资源冲突）
    self.uniqueId = generateUniqueId("DrawBulletInst")
    self.uiPrefix = "DrawBulletUI_" .. self.uniqueId
    self.settingPrefix = "DrawBulletSetting_" .. self.uniqueId
    
    -- 2. 全局依赖（仅通过参数传入，不直接全局引用）
    self.Window = Window
    self.Library = Library
    self.TabDraw = nil
    
    -- 3. 实例私有配置（不暴露到全局）
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
    
    -- 4. 实例私有资源（存储当前实例的绘制对象/连接，卸载时可完全清理）
    self.drawObjects = {}  -- 绘制相关UI（高亮框、血条等）
    self.drawConnections = {}  -- 绘制相关服务连接
    self.aimbotConnections = {}  -- 瞄准相关服务连接
    self.uiElements = {}  -- 实例创建的所有UI元素（便于销毁）
    
    -- 5. 状态变量（局部化，不污染全局）
    self.isRunning = false
    self.isAimbotRunning = false
    self.currentTarget = nil
    self.screenGui = nil
    self.fovCircle = nil
    
    -- 6. 瞄准配置（局部映射表，避免全局变量覆盖）
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
    
    return self
end

-- -------------- 私有工具方法（仅实例内部调用，不暴露）--------------
-- 创建高亮框（带唯一标识，避免多实例UI冲突）
local function createHighlight(self, character)
    if not character then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = self.uiPrefix .. "_PlayerHighlight"
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    table.insert(self.uiElements, highlight)
    return highlight
end

-- 创建玩家名称标签（唯一命名，避免覆盖）
local function createNameTag(self, player, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = self.uiPrefix .. "_PlayerNameTag"
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
    table.insert(self.uiElements, billboard)
    return {billboard = billboard, nameLabel = nameLabel, distanceLabel = distanceLabel}
end

-- 创建NPC名称标签（唯一命名）
local function createNPCNameTag(self, npcName, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = self.uiPrefix .. "_NPCNameTag"
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
    table.insert(self.uiElements, billboard)
    return {billboard = billboard, nameLabel = nameLabel, distanceLabel = distanceLabel}
end

-- 创建血条（唯一命名）
local function createHealthBar(self, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = self.uiPrefix .. "_HealthBar"
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
    table.insert(self.uiElements, billboard)
    return {billboard = billboard, healthBar = healthBar, background = background}
end

-- 创建工具显示（唯一命名）
local function createToolDisplay(self, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = self.uiPrefix .. "_ToolDisplay"
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
    table.insert(self.uiElements, billboard)
    return {billboard = billboard, toolImage = toolImage}
end

-- 创建背包显示（唯一命名）
local function createBackpackDisplay(self, character)
    if not character then return nil end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = self.uiPrefix .. "_BackpackDisplay"
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
    table.insert(self.uiElements, billboard)
    return {billboard = billboard, container = container, uiListLayout = uiListLayout}
end

-- 判断是否为NPC（局部方法，避免全局函数冲突）
local function isNPC(self, model)
    if not model:IsA("Model") then return false end
    if not model:FindFirstChildOfClass("Humanoid") then return false end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character == model then
            return false
        end
    end
    return true
end

-- 判断是否为敌人（局部方法）
local function isEnemy(self, player)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return true
    end
    return localPlayer.Team ~= player.Team
end

-- 判断是否为队友（局部方法）
local function isTeammate(self, player)
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return false
    end
    return localPlayer.Team == player.Team
end

-- 判断是否应该绘制该玩家（局部方法）
local function shouldDrawPlayer(self, player)
    if not self.drawSettings.players then
        return false
    end
    if self.drawSettings.hideEnemies and isEnemy(self, player) then
        return false
    end
    if self.drawSettings.hideTeammates and isTeammate(self, player) then
        return false
    end
    return true
end

-- -------------- 实例方法（对外暴露的功能）--------------
-- 更新绘制（核心逻辑：仅处理当前实例的绘制对象）
function DrawAndBulletModule:updateDrawings()
    if not self.drawSettings.enabled or not self.isRunning then return end
    
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    -- 绘制玩家
    if self.drawSettings.players then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer and shouldDrawPlayer(self, player) then
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
                                self.drawObjects[player].highlight = createHighlight(self, character)
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
                                self.drawObjects[player].nameTag = createNameTag(self, player, character)
                            end
                            local nameTag = self.drawObjects[player].nameTag
                            if nameTag then
                                nameTag.billboard.Enabled = true
                                nameTag.nameLabel.Visible = self.drawSettings.names
                                nameTag.distanceLabel.Visible = self.drawSettings.distances
                                if self.drawSettings.names and self.drawSettings.teamColor and player.Team then
                                    nameTag.nameLabel.TextColor3 = player.Team.TeamColor.Color
                                end
                                if self.drawSettings.distances then
                                    nameTag.distanceLabel.Text = string.format("[%d]", math.floor(distance))
                                end
                            end
                        else
                            if self.drawObjects[player].nameTag then
                                self.drawObjects[player].nameTag.billboard.Enabled = false
                            end
                        end
                        
                        -- 血条、工具、背包显示（逻辑同上，均使用当前实例的私有方法）
                        if self.drawSettings.healthbars then
                            if not self.drawObjects[player].healthBar then
                                self.drawObjects[player].healthBar = createHealthBar(self, character)
                            end
                            local healthBar = self.drawObjects[player].healthBar
                            if healthBar then
                                healthBar.billboard.Enabled = true
                                local healthPercent = humanoid.Health / humanoid.MaxHealth
                                healthBar.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                                healthBar.healthBar.BackgroundColor3 = healthPercent > 0.5 and Color3.new(0, 1, 0) or (healthPercent > 0.25 and Color3.new(1, 1, 0) or Color3.new(1, 0, 0))
                            end
                        else
                            if self.drawObjects[player].healthBar then
                                self.drawObjects[player].healthBar.billboard.Enabled = false
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 绘制NPC（逻辑类似，使用私有方法 createNPCNameTag）
    if self.drawSettings.npcs then
        for _, model in ipairs(workspace:GetDescendants()) do
            if isNPC(self, model) then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local rootPart = model:FindFirstChild("HumanoidRootPart")
                if humanoid and rootPart and humanoid.Health > 0 then
                    local distance = (localRoot.Position - rootPart.Position).Magnitude
                    if not self.drawObjects[model] then
                        self.drawObjects[model] = {}
                    end
                    
                    if self.drawSettings.boxes then
                        if not self.drawObjects[model].highlight then
                            self.drawObjects[model].highlight = createHighlight(self, model)
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
                            self.drawObjects[model].nameTag = createNPCNameTag(self, model.Name, model)
                        end
                        local nameTag = self.drawObjects[model].nameTag
                        if nameTag then
                            nameTag.billboard.Enabled = true
                            nameTag.nameLabel.Visible = self.drawSettings.names
                            nameTag.distanceLabel.Visible = self.drawSettings.distances
                            if self.drawSettings.distances then
                                nameTag.distanceLabel.Text = string.format("[%d]", math.floor(distance))
                            end
                        end
                    else
                        if self.drawObjects[model].nameTag then
                            self.drawObjects[model].nameTag.billboard.Enabled = false
                        end
                    end
                end
            end
        end
    end
end

-- 清除绘制资源（完全清理当前实例的绘制对象，避免残留）
function DrawAndBulletModule:clearDrawings()
    -- 1. 销毁绘制对象
    for key, objects in pairs(self.drawObjects) do
        if objects.highlight then objects.highlight:Destroy() end
        if objects.nameTag then objects.nameTag.billboard:Destroy() end
        if objects.healthBar then objects.healthBar.billboard:Destroy() end
        if objects.toolDisplay then objects.toolDisplay.billboard:Destroy() end
        if objects.backpackDisplay then objects.backpackDisplay.billboard:Destroy() end
    end
    self.drawObjects = {}
    
    -- 2. 断开绘制相关连接
    for _, conn in ipairs(self.drawConnections) do
        if conn then conn:Disconnect() end
    end
    self.drawConnections = {}
    
    -- 3. 销毁所有UI元素
    for _, ui in ipairs(self.uiElements) do
        if ui and ui.Parent then ui:Destroy() end
    end
    self.uiElements = {}
end

-- 瞄准核心逻辑（局部化，不依赖全局变量）
function DrawAndBulletModule:getClosestTarget()
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter then return nil end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not localRoot or not camera then return nil end
    
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
                        local raycastResult = workspace:Raycast(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position), raycastParams)
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
            if isNPC(self, model) then
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
                                local raycastResult = workspace:Raycast(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position), raycastParams)
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
    
    return closestTarget
end

-- 瞄准目标（仅操作当前实例的瞄准配置）
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
        local newCFrame = currentCFrame:Lerp(CFrame.lookAt(currentCFrame.Position, targetPosition), 1 / smoothness)
        camera.CFrame = newCFrame
    end
end

-- 瞄准循环（仅当前实例生效）
function DrawAndBulletModule:aimbotLoop()
    if not self.aimSettings.enabled or not self.isAimbotRunning then return end
    if self.aimSettings.autoAim then
        self.currentTarget = self:getClosestTarget()
        if self.currentTarget then
            self:aimAtTarget(self.currentTarget)
        end
    end
end

-- 开始瞄准（创建独立连接，不与其他实例冲突）
function DrawAndBulletModule:startAimbot()
    if self.isAimbotRunning then return end
    
    self.isAimbotRunning = true
    if self.fovCircle then
        self.fovCircle.Visible = true
    end
    
    -- 创建独立的RenderStepped连接（存储到当前实例的连接表）
    self.aimbotConnections.renderStepped = game:GetService("RunService").RenderStepped:Connect(function()
        self:aimbotLoop()
    end)
    
    -- 通知（带实例标识，避免与其他脚本通知混淆）
    game:GetService("CoreGui"):SetCore("SendNotification", {
        Title = "瞄准功能_" .. self.uniqueId,
        Text = "瞄准功能已启用（实例：" .. self.uniqueId .. "）",
        Duration = 3,
    })
end

-- 停止瞄准（完全清理当前实例的瞄准资源）
function DrawAndBulletModule:stopAimbot()
    self.isAimbotRunning = false
    self.currentTarget = nil
    if self.fovCircle then
        self.fovCircle.Visible = false
    end
    
    -- 断开瞄准相关连接
    for _, conn in ipairs(self.aimbotConnections) do
        if conn then conn:Disconnect() end
    end
    self.aimbotConnections = {}
    
    game:GetService("CoreGui"):SetCore("SendNotification", {
        Title = "瞄准功能_" .. self.uniqueId,
        Text = "瞄准功能已禁用（实例：" .. self.uniqueId .. "）",
        Duration = 3,
    })
end

-- 创建FOV UI（唯一命名，避免多实例UI覆盖）
function DrawAndBulletModule:createFOVUI()
    -- 销毁旧UI（避免重复创建）
    if self.screenGui then self.screenGui:Destroy() end
    
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = self.uiPrefix .. "_AimbotFOV"
    self.screenGui.Parent = game.CoreGui
    self.screenGui.ResetOnSpawn = false
    table.insert(self.uiElements, self.screenGui)
    
    self.fovCircle = Instance.new("Frame")
    self.fovCircle.Name = self.uiPrefix .. "_FOVCircle"
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
    table.insert(self.uiElements, self.fovCircle)
end

-- 加载标签页（配置项带唯一前缀，避免多实例设置冲突）
function DrawAndBulletModule:LoadDrawAndBulletTab()
    -- 创建标签页（带实例标识，避免与其他标签页重名）
    self.TabDraw = self.Window:Tab("绘制与子弹_" .. self.uniqueId, '5436396975')
    local SectionDraw1 = self.TabDraw:section("绘制开关_" .. self.uniqueId, true)
    local SectionDraw = self.TabDraw:section("绘制选项_" .. self.uniqueId, true)
    local SectionAim2 = self.TabDraw:section("瞄准开关_" .. self.uniqueId, true)
    local SectionAim3 = self.TabDraw:section("瞄准选项_" .. self.uniqueId, true)
    local SectionAim4 = self.TabDraw:section("子弹追踪_" .. self.uniqueId, true)
    
    -- 1. 绘制开关（配置项带唯一前缀，避免多实例设置冲突）
    SectionDraw1:Toggle("启用绘制", self.settingPrefix .. "EnableDrawing", false, function(state)
        self.drawSettings.enabled = state
        if state then
            self.isRunning = true
            -- 创建独立的绘制循环连接
            self.drawConnections.renderStepped = game:GetService("RunService").RenderStepped:Connect(function()
                self:updateDrawings()
            end)
            game:GetService("CoreGui"):SetCore("SendNotification", {
                Title = "绘制功能_" .. self.uniqueId,
                Text = "绘制功能已启用（实例：" .. self.uniqueId .. "）",
                Duration = 3,
            })
        else
            self.isRunning = false
            self:clearDrawings()
            game:GetService("CoreGui"):SetCore("SendNotification", {
                Title = "绘制功能_" .. self.uniqueId,
                Text = "绘制功能已禁用（实例：" .. self.uniqueId .. "）",
                Duration = 3,
            })
        end
    end)
    
    SectionDraw1:Toggle("绘制玩家", self.settingPrefix .. "DrawPlayers", false, function(state)
        self.drawSettings.players = state
        if not state then
            for player, objects in pairs(self.drawObjects) do
                if typeof(player) == "Instance" and player:IsA("Player") then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    self.drawObjects[player] = nil
                end
            end
        end
    end)
    
    SectionDraw1:Toggle("绘制NPC", self.settingPrefix .. "DrawNPCs", false, function(state)
        self.drawSettings.npcs = state
        if not state then
            for model, objects in pairs(self.drawObjects) do
                if typeof(model) == "Instance" and model:IsA("Model") and isNPC(self, model) then
                    if objects.highlight then objects.highlight:Destroy() end
                    if objects.nameTag then objects.nameTag.billboard:Destroy() end
                    if objects.healthBar then objects.healthBar.billboard:Destroy() end
                    self.drawObjects[model] = nil
                end
            end
        end
    end)
    
    -- 2. 绘制选项（配置项均带唯一前缀）
    SectionDraw:Toggle("显示方框", self.settingPrefix .. "ShowBoxes", false, function(state)
        self.drawSettings.boxes = state
    end)
    SectionDraw:Toggle("显示名称", self.settingPrefix .. "ShowNames", false, function(state)
        self.drawSettings.names = state
    end)
    SectionDraw:Toggle("显示距离", self.settingPrefix .. "ShowDistances", false, function(state)
        self.drawSettings.distances = state
    end)
    SectionDraw:Toggle("显示血条", self.settingPrefix .. "ShowHealthbars", false, function(state)
        self.drawSettings.healthbars = state
    end)
    
    -- 3. 瞄准开关（创建独立FOV UI）
    self:createFOVUI()
    SectionAim2:Toggle("启用瞄准", self.settingPrefix .. "EnableAimbot", false, function(state)
        self.aimSettings.enabled = state
        if state then
            self:startAimbot()
        else
            self:stopAimbot()
        end
    end)
    
    SectionAim2:Dropdown("瞄准部位", self.settingPrefix .. "AimPart", {
        "头部", "身体", "左手", "右手", "左腿", "右腿", "左脚", "右脚"
    }, function(selected)
        self.aimSettings.aimPart = selected
    end)
    
    -- 4. 瞄准选项（配置项带唯一前缀）
    SectionAim3:Toggle("忽略队友", self.settingPrefix .. "IgnoreTeam", true, function(state)
        self.aimSettings.ignoreTeam = state
    end)
    SectionAim3:Toggle("忽略敌人", self.settingPrefix .. "IgnoreEnemy", false, function(state)
        self.aimSettings.ignoreEnemy = state
    end)
    SectionAim3:Slider("瞄准平滑度", self.settingPrefix .. "AimSmoothness", 1, 10, 1, function(value)
        self.aimSettings.smoothness = value
    end)
    
    -- 5. 子弹追踪（独立逻辑，不依赖全局函数）
    SectionAim4:Button("启用子弹追踪", function()
        local Camera = game:GetService("Workspace").CurrentCamera
        local Players = game:GetService("Players")
        local LocalPlayer = game.Players.LocalPlayer
        
        -- 局部函数：获取最近玩家（不污染全局）
        local function GetClosestPlayer()
            local ClosestPlayer = nil
            local FarthestDistance = math.huge
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - v.Character.HumanoidRootPart.Position).Magnitude
                    if Distance < FarthestDistance then
                        FarthestDistance = Distance
                        ClosestPlayer = v
                    end
                end
            end
            return ClosestPlayer
        end
        
        -- 局部元表钩子（仅当前实例生效，不影响全局）
        local GameMetaTable = getrawmetatable(game)
        local OldNamecall = GameMetaTable.__namecall
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
            return OldNamecall(object, unpack(Arguments))
        end)
        
        setreadonly(GameMetaTable, true)
        game:GetService("CoreGui"):SetCore("SendNotification", {
            Title = "子弹追踪_" .. self.uniqueId,
            Text = "子弹追踪已启用（实例：" .. self.uniqueId .. "）",
            Duration = 3,
        })
    end)
    
    -- 角色重生时重新初始化（仅当前实例）
    game.Players.LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        if self.drawSettings.enabled then
            self:clearDrawings()
            self.drawConnections.renderStepped = game:GetService("RunService").RenderStepped:Connect(function()
                self:updateDrawings()
            end)
        end
        if self.aimSettings.enabled then
            self:createFOVUI()
            self:startAimbot()
        end
    end)
    
    return self.TabDraw
end

-- 销毁实例（完全清理所有资源，无残留冲突）
function DrawAndBulletModule:Destroy()
    -- 1. 清理绘制资源
    self:clearDrawings()
    
    -- 2. 清理瞄准资源
    self:stopAimbot()
    
    -- 3. 销毁标签页（若支持）
    if self.TabDraw and self.Window.RemoveTab then
        pcall(function()
            self.Window:RemoveTab(self.TabDraw)
        end)
    end
    
    -- 4. 清空实例引用
    setmetatable(self, nil)
end

return DrawAndBulletModule
