local PLUGIN = PLUGIN or {}
PLUGIN.name = "Emote Moods"
PLUGIN.author = "DrodA (Ported from NS)"
PLUGIN.description = "With this plugin, characters can set their mood."
PLUGIN.schema = "Any"
PLUGIN.version = 1.2

MOOD_NONE = 0
MOOD_RELAXED = 1
MOOD_FRUSTRATED = 2
MOOD_MODEST = 3
MOOD_COWER = 4
MOOD_HOLDING = 5 -- New mood for FACTION_CCA
MOOD_CROSSED = 6

PLUGIN.MoodTextTable = {
    [MOOD_NONE] = "Default",
    [MOOD_RELAXED] = "Relaxed",
    [MOOD_FRUSTRATED] = "Frustrated",
    [MOOD_MODEST] = "Modest",
    [MOOD_COWER] = "Cower",
}

PLUGIN.CPMoodTextTable = {
    [MOOD_NONE] = "Default",
    [MOOD_HOLDING] = "Intimidating",
    [MOOD_CROSSED] = "Hands Crossed",
}

PLUGIN.MoodBadMovetypes = {
    [MOVETYPE_FLY] = true,
    [MOVETYPE_LADDER] = true,
    [MOVETYPE_NOCLIP] = true
}

PLUGIN.MoodAnimTable = {
    [MOOD_RELAXED] = {
        [0] = "LineIdle01",
        [1] = "walk_all_Moderate",
        [2] = "run_all"
    },
    [MOOD_FRUSTRATED] = {
        [0] = "LineIdle02",
        [1] = "pace_all",
        [2] = "run_all"
    },
    [MOOD_MODEST] = {
        [0] = "LineIdle04",
        [1] = "plaza_walk_all",
        [2] = "run_all"
    },
}

PLUGIN.MoodAnimTableCCA = {
    [MOOD_HOLDING] = {
        [0] = "plazathreat1", -- Example CCA animation names
        [1] = "plaza_walk_all",
        [2] = "run_all"
    },

    [MOOD_CROSSED] = {
        [0] = "plazathreat2", -- Example CCA animation names
        [1] = "plaza_walk_all",
        [2] = "run_all"
    },
}

local meta = FindMetaTable("Player")

function meta:GetMood()
    return self:GetNetVar("mood") or MOOD_NONE
end

if SERVER then
    function meta:SetMood(int)
        int = int or 0
        self:SetNetVar("mood", int)
    end

    function PLUGIN:PlayerLoadedCharacter(client, character)
        client:SetMood(MOOD_NONE)
    end
end

local COMMAND = {}
COMMAND.description = "Set your own idle"
COMMAND.arguments = {ix.type.number}
COMMAND.adminOnly = false

function COMMAND:OnRun(client, mood)
    mood = math.Clamp(mood, 0, MOOD_COWER)
    client:SetMood(mood)
end

ix.command.Add("Mood", COMMAND)

local tblWorkaround = {
    ["ix_keys"] = true,
    ["ix_hands"] = true,
    ["ix_stunstick"] = true
}

function PLUGIN:CalcMainActivity(client, velocity)
    local length = velocity:Length2DSqr()
    local clientInfo = client:GetTable()
    local mood = client:GetMood()
    local isCCA = client:GetCharacter() and client:GetCharacter():GetFaction() == FACTION_CCA
    local holdingStunstick = IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "ix_stunstick"

    if client and IsValid(client) and client:IsPlayer() then
        local moodAnimTable = (isCCA and holdingStunstick) and PLUGIN.MoodAnimTableCCA or PLUGIN.MoodAnimTable
        if not client:IsWepRaised() and not client:Crouching() and IsValid(client:GetActiveWeapon()) and tblWorkaround[client:GetActiveWeapon():GetClass()] and not client:InVehicle() and mood > 0 and not self.MoodBadMovetypes[client:GetMoveType()] and not client.m_bJumping and client:IsOnGround() then
            if length < 0.25 then
                clientInfo.CalcSeqOverride = moodAnimTable[mood] and client:LookupSequence(moodAnimTable[mood][0]) or clientInfo.CalcSeqOverride
            elseif length > 0.25 and length < 22500 then
                clientInfo.CalcSeqOverride = moodAnimTable[mood] and client:LookupSequence(moodAnimTable[mood][1]) or clientInfo.CalcSeqOverride
            elseif length > 22500 then
                client.CalcSeqOverride = moodAnimTable[mood] and client:LookupSequence(moodAnimTable[mood][2]) or clientInfo.CalcSeqOverride
            end
        end
    end
end

if SERVER then
    local cooldown = 1 -- Adjust the cooldown duration here (in seconds)
    local cooldowns = {}

    function PLUGIN:PlayerButtonDown(client, button)
        local char = client:GetCharacter()
        local isCCA = char and char:GetFaction() == FACTION_CCA
        local holdingStunstick = IsValid(client:GetActiveWeapon()) and client:GetActiveWeapon():GetClass() == "ix_stunstick"

        if button == MOUSE_MIDDLE and IsValid(client:GetActiveWeapon()) and tblWorkaround[client:GetActiveWeapon():GetClass()] then
            if isCCA and holdingStunstick then
                -- CCA changing mood with stunstick
                local currentMood = client:GetMood()
                local nextMood = MOOD_NONE

                -- Cycle through CCA moods
                if currentMood == MOOD_NONE then
                    nextMood = MOOD_HOLDING
                elseif currentMood == MOOD_HOLDING then
                    nextMood = MOOD_CROSSED
                elseif currentMood == MOOD_CROSSED then
                    nextMood = MOOD_NONE
                end

                if not cooldowns[client] or CurTime() >= cooldowns[client] then
                    cooldowns[client] = CurTime() + cooldown
                    client:SetMood(nextMood)
                    timer.Simple(0.15, function() client:ChatPrint("You have changed your idle to " .. PLUGIN.CPMoodTextTable[nextMood] .. ".") end)
                end
            elseif not isCCA then
                -- Regular player changing mood
                local currentMood = client:GetMood()
                local nextMood = (currentMood + 1) % (MOOD_MODEST + 1) -- Cycles through non-CCA moods

                if not cooldowns[client] or CurTime() >= cooldowns[client] then
                    cooldowns[client] = CurTime() + cooldown
                    client:SetMood(nextMood)
                    timer.Simple(0.15, function() client:ChatPrint("You have changed your idle to " .. PLUGIN.MoodTextTable[nextMood] .. ".") end)
                end
            end
        end
    end
end