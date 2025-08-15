PLUGIN.name = "Chat Bubbles"
PLUGIN.author = "YourName"
PLUGIN.description = "Displays what players say above their heads."
if CLIENT then
    local bubbles = {}
    hook.Add("PostDrawTranslucentRenderables", "ixChatBubbles", function()
    for client, data in pairs(bubbles) do
        if not IsValid(client) or not client:Alive() or not data.text then
            bubbles[client] = nil
            continue
        end

        local remaining = data.expire - CurTime()
        if remaining <= 0 then
            bubbles[client] = nil
            continue
        end

        local alpha = 55
        if remaining < 1 then -- Fade out during the last second
            alpha = math.Clamp(remaining * 55, 0, 55)
        end

        local ang = EyeAngles()
        ang:RotateAroundAxis(ang:Up(), -90)
        ang:RotateAroundAxis(ang:Forward(), 90)

        local pos = client:GetPos() + Vector(0, 0, 85)
        local maxWidth = 300
        local text = data.text

        surface.SetFont("CloseCaption_Normal")
        local textWidth = surface.GetTextSize(text)

        -- Truncate text if too wide
        if textWidth > maxWidth then
            local quoteAtStart = false
            local quoteAtEnd = false

            if text:sub(1, 1) == "\"" then
                quoteAtStart = true
                text = text:sub(2)
            end
            if text:sub(-1) == "\"" then
                quoteAtEnd = true
                text = text:sub(1, -2)
            end

            local dots = "..."
            local ellipsisWidth = surface.GetTextSize(dots)
            local quoteWidth = surface.GetTextSize("\"")
            local targetWidth = maxWidth - ellipsisWidth
            if quoteAtEnd then targetWidth = targetWidth - quoteWidth end

            while #text > 0 do
                local w = surface.GetTextSize(text)
                if w <= targetWidth then break end
                text = text:sub(1, -2)
            end

            text = (quoteAtStart and "\"" or "") .. text .. dots .. (quoteAtEnd and "\"" or "")
        end

        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.2)
            draw.SimpleTextOutlined(
                text,
                "CloseCaption_Normal",
                0, 0,
                Color(255, 255, 150, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(0, 0, 0, alpha)
            )
        cam.End3D2D()
    end
end)

net.Receive("ixChatBubble", function()
    local client = net.ReadEntity()
    local text = net.ReadString()

    if IsValid(client) then
        local existing = bubbles[client]

        -- If same message is sent again, increment the counter
        if existing and existing.baseText == text then
            existing.count = (existing.count or 1) + 1
            existing.expire = CurTime() + 5

            local display = text .. " x" .. existing.count
            existing.text = display
        else
            bubbles[client] = {
                baseText = text,
                text = text,
                count = 1,
                expire = CurTime() + 5
            }
        end
    end
end)
end


if SERVER then
    util.AddNetworkString("ixChatBubble")
    function PLUGIN:PlayerMessageSend(speaker, chatType, text) -- Hook into Helix's PlayerMessageSend
        if not IsValid(speaker) or not isstring(text) then return end
        local allowedTypes = {
            ic = true,
            whisper = true,
            yell = true,
            me = true
        }

        if allowedTypes[chatType] then
            local displayText = text
            if chatType == "me" then
                displayText = "*** " .. text
            else
                displayText = "\"" .. text .. "\""
            end

            net.Start("ixChatBubble")
            net.WriteEntity(speaker)
            net.WriteString(displayText)
            net.Broadcast()
        end
    end
end