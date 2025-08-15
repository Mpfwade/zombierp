ix.util.badges = {
    staff = {Material("icon16/shield.png"), "This player is a staff member.", function(ply)
        return not ply:IsIncognito() and ply:IsAdmin()
    end},
    donator = {Material("icon16/coins.png"), "This player is a donator.", function(ply)
        return ply:IsDonator()
    end},
    dev = {Material("icon16/cog.png"), "This player is a developer.", function(ply)
        return not ply:IsIncognito() and ply:IsDeveloper()
    end},
}

ix.util.modQuickReplies = {
    "Thanks for submitting this report. I'll need some more information about what your problem is to solve this issue.",
    "Unfortunately we can not help with this type of issue. If you have any issues with rule-breakers feel free to send another report.",
    "Unfortunately I can not help with compensation requests. Goto CitizenLife discord to for more help.",
    "We can help you further if you ask in the CitizenLife discord",
    "We have decided to not grant you rogue permission, please do not make another request for at least 1 hour.",
    "You have been granted rogue permission.",
    "Apologies for the delay in responding to this report.",
    "Thank you for your report.",
    "Unfortunately I will have to close this report as it is too old to be dealt with. Feel free to submit a ban request at https://citizenlifeproject.mistforums.com/"
}

ix.util.autoModDict = {
    {
        Terms = {"HELP", "JUST HELP", "HELP ME", "ADMIN HELP", "ADMIN", "COME HERE", "COME", "NEED STAFF", "NEED ADMIN", "ADMIN COME HERE", "ADMIN TO ME", "I NEED A ADMIN", "I NEED ADMIN", "TO ME", "MINGE", "HEY"},
        Specific = true,
        IgnorePunc = true,
        Reply = "Hi! I've noticed your report doesn't contain much detail about the situation. We'd really appricate it if you could provide some more information for us by updating the report! Thanks!"
    },
    {
        Terms = {"CAN I GO ROUGE", "ROUGE PERM", "ROUGE", "ROGUE", "ROGUE PERM", "CAN I GO ROGUE", "ROGUE PERM", "ROUGEPERM", "PERM TO GO ROUGE", "PERM TO GO ROGUE", "ROGUE PERMISSION", "ROUGE PERMISSION"},
        Specific = true,
        IgnorePunc = true,
        Reply = "Hi! I've detected you've submitted a report regarding permission to go rouge, please be aware, that in busy times this report will be low priority for response. Please also be aware that only i3's and i4's can go rouge. JURY units can not go rouge."
    },
    {
        Terms = {"HOW", "DONATE"},
        TermsTogether = true,
        IgnorePunc = true,
        RequestClose = true,
        Reply = "Hi! Thanks for considering to donate! But we do not have a way to donate!"
    },
    {
        Terms = {"HOW", "VIP"},
        TermsTogether = true,
        IgnorePunc = true,
        RequestClose = true,
        Reply = "Hi! Thanks for considering to donate! But we do not have a way to donate!"
    },
}

local PLAYER = FindMetaTable("Player")

local developers = {
    ["76561197963057641"] = true,
}
function PLAYER:IsDeveloper()
    return ( developers[self:SteamID64()] )
end

function PLAYER:IsDonator()
    return ( self:GetUserGroup() == "donator" )
end

function PLAYER:GetReports()
    return self:GetNWInt("ixReports") or ( SERVER and self:GetPData("ixReports", 0) or 0 )
end

if ( SERVER ) then
    util.AddNetworkString("ixColoredMessage")
    function PLAYER:AddChatText(...)
        local package = {...}
        netstream.Start(self, "ixColoredMessage", package)
    end

    function PLAYER:SetReports(value)
        if not ( tonumber(value) ) then return end
        if ( tonumber(value) < 0 ) then return end

        self:SetPData("ixReports", tonumber(value))
        self:SetNWInt("ixReports", tonumber(value))
    end

    function PLAYER:AddReports(value)
        if not ( tonumber(value) ) then return end
        if ( tonumber(value) < 0 ) then return end

        self:SetReports(self:GetReports() + value)
    end
else
    netstream.Hook("ixColoredMessage", function(msg)
        chat.AddText(unpack(msg))
    end)
end

local blacklistNames = {
    ["ooc"] = true,
    ["shared"] = true,
    ["world"] = true,
    ["world prop"] = true,
    ["blocked"] = true,
    ["admin"] = true,
    ["server admin"] = true,
    ["mod"] = true,
    ["game moderator"] = true,
    ["adolf hitler"] = true,
    ["masked person"] = true,
    ["masked player"] = true,
    ["unknown"] = true,
    ["nigger"] = true,
    ["tyrone jenson"] = true,
    ["Fatt Lard"] = true

}

function ix.util.SafeString(str)
    local pattern = "[^0-9a-zA-Z%s]+"
    local clean = tostring(str)
    local first, last = string.find(str, pattern)

    if first != nil and last != nil then
        clean = string.gsub(clean, pattern, "") -- remove bad sequences
    end

    return clean
end


function ix.util.CanUseName(name)
    if name:len() >= 24 then
        return false, "Name too long. (max. 24)" 
    end

    name = name:Trim()
    name = ix.util.SafeString(name)

    if name:len() <= 6 then
        return false, "Name too short. (min. 6)"
    end

    if name == "" then
        return false, "No name was provided."
    end


    local numFound = string.match(name, "%d") -- no numerics

    if numFound then
        return false, "Name contains numbers."
    end
    
    if blacklistNames[name:lower()] then
        return false, "Blacklisted/reserved name."    
    end

    return true, name
end