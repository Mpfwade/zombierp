local PLUGIN = PLUGIN or {}
util.AddNetworkString("TriggerScreenShake")
local function TriggerClientScreenShake(player, duration, intensity, radius, viewpunch) -- Function to trigger screenshake
    net.Start("TriggerScreenShake")
    net.WriteFloat(duration)
    net.WriteFloat(intensity)
    net.WriteFloat(radius)
    net.WriteVector(viewpunch or Vector(0, 0, 0))
    net.Send(player)
end

function PLUGIN:ForceVomiting(ply)
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    ply:TakeDamage(damageAmount, ply, ply)
    char:SetHunger(math.max(0, char:GetHunger() - 5))
    ply:EmitSound("citizensounds/puking.wav")
    ix.chat.Send(ply, "me", "vomits.")
    TriggerClientScreenShake(ply, 5, 5, 500, Vector(0, 5, 0))
    net.Start("TriggerPukeEffect")
    net.WriteEntity(ply)
    net.Broadcast()
    if not ply:GetNWBool("IsActing") then ply:ForceSequence("d2_coast03_postbattle_idle02_entry", nil, 2, false) end
end