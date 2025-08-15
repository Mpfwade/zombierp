local PLUGIN = PLUGIN
PLUGIN.name     = 'Multiple Voice-lines'
PLUGIN.author   = 'Bilwin'
PLUGIN.version  = 1.0

if CLIENT then
    net.Receive('ixPlaySound', function()
        local sound = net.ReadString()
        surface.PlaySound(sound)
    end)
end

ix.util.Include('sv_plugin.lua')