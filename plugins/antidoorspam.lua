local PLUGIN = PLUGIN
local useSpam = 0

PLUGIN.name = "Anti-Door Spam"
PLUGIN.author = "Wade"
PLUGIN.schema = "Any"

function PLUGIN:PlayerBindPress(client, bind, pressed)

 if bind == "+use" and pressed then
    if client:Alive() and useSpam >= 4 then
        return true
        elseif client:Alive() then
        useSpam = useSpam + 1
        timer.Simple(3, function() useSpam = useSpam - 1 end)
    end
  end
end
        