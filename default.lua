local DefaultMessages = {}

DefaultMessages.Messages = {
    "通用消息1",
    "通用消息2",
    "通用消息3"
}

function DefaultMessages.GetMessage()
    return DefaultMessages.Messages[math.random(1, #DefaultMessages.Messages)]
end

return DefaultMessages
