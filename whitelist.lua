local Whitelist = {}

Whitelist.Users = {
    [pro_xx863] = {"用户1的发言1", "用户1的发言2"}, -- 替换为实际用户ID
    [用户名] = {"用户2的发言1", "用户2的发言2"}  -- 替换为实际用户ID
}

function Whitelist.GetMessage(player)
    local userId = player.UserId
    if Whitelist.Users[userId] then
        local userMessages = Whitelist.Users[userId]
        return userMessages[math.random(1, #userMessages)]
    else
        return nil 
    end
end

return Whitelist
