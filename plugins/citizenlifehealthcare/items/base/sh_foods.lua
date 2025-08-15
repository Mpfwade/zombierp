ITEM.name = "Consumable Base"
ITEM.model = Model("models/props_junk/garbage_takeoutcarton001a.mdl")
ITEM.description = "A base for consumables."
ITEM.width = 1
ITEM.height = 1
ITEM.category = "Consumables"
ITEM.noBusiness = true
ITEM.useSound = "npc/barnacle/barnacle_crunch2.wav"
ITEM.useName = "Consume"
ITEM.RestoreHunger = 0
ITEM.RestoreHealth = 0
ITEM.damage = 0
ITEM.spoilTime = 14
ITEM.effectAmount = 0.2
ITEM.effectTime = 1
ITEM.returnItems = {}
function ITEM:GetName()
    if self:GetSpoiled() then
        local spoilText = self.spoilText or "Spoiled"
        return spoilText .. " " .. self.name
    end
    return self.name
end

function ITEM:GetDescription()
    local description = {self.description}
    if not self:GetSpoiled() and self:GetData("spoilTime") then
        local spoilTime = math.floor((self:GetData("spoilTime") - os.time()) / 60)
        local text = " minutes."
        if spoilTime > 60 then
            text = " hours."
            spoilTime = math.floor(spoilTime / 60)
        end

        if spoilTime > 24 then
            text = " days."
            spoilTime = math.floor(spoilTime / 24)
        end

        description[#description + 1] = "\nSpoils in " .. spoilTime .. text
    end
    return table.concat(description, "")
end

function ITEM:GetSpoiled()
    local spoilTime = self:GetData("spoilTime")
    if not spoilTime then return false end
    return os.time() > spoilTime
end

function ITEM:OnInstanced()
    if self.spoil then self:SetData("spoilTime", os.time() + 24 * 60 * 60 * self.spoilTime) end
end

ITEM.functions.Consume = {
    icon = "icon16/user.png",
    name = "Consume",
    OnRun = function(item)
        local ply = item.player
        local character = item.player:GetCharacter()
        local bSpoiled = item:GetSpoiled()
        local actiontext = "Invalid Action"
        local function Vomit(ply, char)
            local ply = item.player
            local char = item.player:GetCharacter()
            if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
            ply:TakeDamage(5, ply, ply)
            char:SetHunger(math.max(0, char:GetHunger() - 30))
            ply:EmitSound("citizensounds/puking.wav")
            ix.chat.Send(ply, "me", "vomits.")
            net.Start("TriggerPukeEffect")
            net.WriteEntity(ply)
            net.Broadcast()
            if not ply:GetNWBool("IsActing") then ply:ForceSequence("d2_coast03_postbattle_idle02_entry", nil, 2, false) end
        end

        if ply.isConsumingConsumeable == true then
            ply:ChatNotify("Too much food, Yuck! Yucky!")
            Vomit(ply, char)
            return false
        end

        if item.useSound then
            if string.find(item.useSound, "drink") or (item.category == "Drinkable") then
                actiontext = "Drinking.."
            else
                actiontext = "Consuming.."
            end
        end

        if item.category == "Drinkable" then
            if istable(item.returnItems) then
                for _, v in ipairs(item.returnItems) do
                    character:GetInventory():Add(v)
                end
            else
                character:GetInventory():Add(item.returnItems)
            end

            ply:AddDrunkEffect(item.effectAmount, item.effectTime)
        end

        if item.name == "Water Can" then
            if not character:GetData("Water", false) then
                character:SetData("Water", true)
                ply:ViewPunch(Angle(math.Rand(-10, 10), math.Rand(-10, 10), math.Rand(-10, 10)))
                timer.Simple(3.5, function() ply:ChatNotify("I feel funny...") end)
                timer.Simple(20, function()
                    ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), 1, 1)
                    character:SetData("Water", false)
                    timer.Simple(1.5, function() ply:ConCommand("say \"Where am I? How did I get here?\"") end)
                end)
            elseif character:GetData("Water", true) then
                return
            end
        end

        local function EatFunction(ply, character, bSpoiled)
            if not (ply:IsValid() and ply:Alive() and character) then return end
            if bSpoiled then -- Direct effects of spoiled food
                ply:TakeDamage(math.random(1, 5), ply, ply)
                return false -- Stop further processing if food is spoiled
            end

            local timerName = "DigestTimer_" .. ply:SteamID() .. "_" .. os.time() .. "_" .. math.random(1000, 9999) -- Generate a unique timer name using the current time and a random number.
            local totalDigestionTime = 85
            local increments = 5
            local hungerIncrement = item.RestoreHunger / increments
            local healthIncrement = item.RestoreHealth / increments
            local incrementTime = totalDigestionTime / increments
            timer.Create(timerName, incrementTime, increments, function()
                if not IsValid(ply) or not ply:Alive() or not character then
                    timer.Remove(timerName)
                    return
                end

                local newHunger = math.min(character:GetHunger() + hungerIncrement, 100)
                character:SetHunger(newHunger)
                if item.RestoreHealth > 0 then ply:SetHealth(math.min(ply:Health() + healthIncrement, ply:GetMaxHealth())) end
            end)

            if item.useSound then
                if istable(item.useSound) then
                    ply:EmitSound(table.Random(item.useSound))
                else
                    timer.Simple(1.2, function() ply:EmitSound(item.useSound) end)
                end
            end

            if item.model and IsValid(ply) then -- Put the consumed food's model in the player's hand
                local rightHandBone = ply:LookupBone("ValveBiped.Bip01_R_Finger02")
                if rightHandBone then
                    local model = ents.Create("prop_physics")
                    if not IsValid(model) then return end
                    model:SetModel(item.model)
                    local offset = Vector(0, 0, 0) -- Adjust this offset to position the model correctly
                    model:SetPos(ply:GetPos() + offset)
                    model:SetAngles(Angle(0, 0, 0)) -- Set the angles to match the item's model
                    model:Spawn()
                    model:SetCollisionGroup(COLLISION_GROUP_WEAPON)
                    model:SetSolid(SOLID_NONE)
                    model:SetOwner(ply)
                    local phys = model:GetPhysicsObject() -- Freeze the prop in place
                    if IsValid(phys) then phys:EnableMotion(false) end
                    model:FollowBone(ply, rightHandBone) -- Attach the model to the right hand bone
                    ply:ConCommand("ix_act_FistRight")
                    ply.ix_foodModel = model
                    ply.isConsumingConsumeable = true
                end
            end

            timer.Simple(1.3, function()
                if IsValid(ply.ix_foodModel) then -- Delete the model after 1 second
                    ply.ix_foodModel:Remove()
                    ply.isConsumingConsumeable = false
                end
            end)
        end

        if item.useTime then
            ply:SetAction(actiontext, item.useTime, function() EatFunction(ply, character, bSpoiled) end)
        else
            EatFunction(ply, character, bSpoiled)
        end
    end
}