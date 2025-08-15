local PLUGIN = PLUGIN
PLUGIN.name = "Persistent Corpses"
PLUGIN.author = "`impulse"
PLUGIN.description = "Makes player corpses stay on the map after the player has respawned."
PLUGIN.license = [[
Copyright 2018 - 2020 Igor Radovanovic

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
PLUGIN.readme = [[
Makes player corpses stay on the map after the player has respawned. Items can also be set to drop into the ragdoll's inventory
upon death.

## Enabling drops
To allow items to be put into a corpse's inventory when a player dies, you must set the `dropItemsOnDeath` config to `true`,
and then add `ITEM.bDropOnDeath = true` to any item that you want to be placed into the inventory.
]]
PLUGIN.hardCorpseMax = 64
ix.lang.AddTable("english", {
    searchingCorpse = "Searching corpse..."
})

ix.config.Add("persistentCorpses", true, "Whether or not corpses remain on the map after a player dies and respawns.", nil, {
    category = "Persistent Corpses"
})

ix.config.Add("corpseMax", 8, "Maximum number of corpses that are allowed to be spawned.", nil, {
    data = {
        min = 0,
        max = PLUGIN.hardCorpseMax
    },
    category = "Persistent Corpses"
})

ix.config.Add("corpseDecayTime", 60, "How long it takes for a corpse to decay in seconds. Set to 0 to never decay.", nil, {
    data = {
        min = 0,
        max = 1800
    },
    category = "Persistent Corpses"
})

ix.config.Add("corpseSearchTime", 1, "How long it takes to search a corpse.", nil, {
    data = {
        min = 0,
        max = 60
    },
    category = "Persistent Corpses"
})

ix.config.Add("dropItemsOnDeath", false, "Whether or not to drop specific items on death.", nil, {
    category = "Persistent Corpses"
})

if SERVER then
    PLUGIN.corpses = {}
    function PLUGIN:ShouldSpawnClientRagdoll(client) -- disable the regular hl2 ragdolls
        return false
    end

    function PLUGIN:PlayerSpawn(client)
        client:SetLocalVar("ragdoll", nil)
    end

    function PLUGIN:ShouldRemoveRagdollOnDeath(client)
        return false
    end

    function PLUGIN:PlayerInitialSpawn(client)
        self:CleanupCorpses()
    end

    function PLUGIN:CleanupCorpses(maxCorpses)
        maxCorpses = maxCorpses or ix.config.Get("corpseMax", 8)
        local toRemove = {}
        if #self.corpses > maxCorpses then
            for k, v in ipairs(self.corpses) do
                if not IsValid(v) then
                    toRemove[#toRemove + 1] = k
                elseif #self.corpses - #toRemove > maxCorpses then
                    v:Remove()
                    toRemove[#toRemove + 1] = k
                end
            end
        end

        for k, _ in ipairs(toRemove) do
            table.remove(self.corpses, k)
        end
    end

    function PLUGIN:RemoveEquippableItem(client, item)
        if item.Unequip then
            item:Unequip(client)
        elseif item.RemoveOutfit then
            item:RemoveOutfit(client)
        elseif item.RemovePart then
            item:RemovePart(client)
        end
    end

    function PLUGIN:DoPlayerDeath(client, attacker, damageinfo)
        if not ix.config.Get("persistentCorpses", true) then return end
        if hook.Run("ShouldSpawnPlayerCorpse") == false then return end
        local maxCorpses = ix.config.Get("corpseMax", 8)
        if maxCorpses == 0 then return end
        local entity = IsValid(client.ixRagdoll) and client.ixRagdoll or client:CreateServerRagdoll()
        local decayTime = ix.config.Get("corpseDecayTime", 60)
        local uniqueID = "ixCorpseDecay" .. entity:EntIndex()
        entity:RemoveCallOnRemove("fixer")
        entity:CallOnRemove("ixPersistentCorpse", function(ragdoll)
            if ragdoll.ixInventory then ix.storage.Close(ragdoll.ixInventory) end
            if IsValid(client) and not client:Alive() then client:SetLocalVar("ragdoll", nil) end
            local index = table.KeyFromValue(PLUGIN.corpses, ragdoll)
            if index then table.remove(PLUGIN.corpses, index) end
            if timer.Exists(uniqueID) then timer.Remove(uniqueID) end
            if timer.Exists(uniqueID .. "Flies") then timer.Remove(uniqueID .. "Flies") end
        end)

        client.ixRagdoll = nil
        entity.ixPlayer = nil
        self.corpses[#self.corpses + 1] = entity
        if #self.corpses >= maxCorpses then self:CleanupCorpses(maxCorpses) end
        hook.Run("OnPlayerCorpseCreated", client, entity)
        timer.Create(uniqueID .. "Flies", math.random(1, 3), 0, function()
            if IsValid(entity) then -- Set up the fly sounds to play randomly as long as the corpse is there
                local flySounds = {"ambient/creatures/flies1.wav", "ambient/creatures/flies2.wav", "ambient/creatures/flies3.wav", "ambient/creatures/flies4.wav", "ambient/creatures/flies5.wav"}
                entity:EmitSound(flySounds[math.random(#flySounds)], 60, 100)
            else
                timer.Remove(uniqueID .. "Flies")
            end
        end)

        local flies = ents.Create("env_sporeexplosion")
        flies:SetPos(entity:GetPos() + vector_up * 16)
        flies:SetParent(entity)
        flies:SetKeyValue("spawnrate", tostring(5 + entity:GetModelRadius() / 10))
        flies:Spawn()
        flies:Activate()
        flies:Fire("enable", "", 1)
        flies:Fire("kill", "", decayTime)
        local function decayStage(stage) -- Define the stages of decay
            if IsValid(entity) then
                if stage == 1 then
                    entity:SetColor(Color(85, 85, 85)) -- Change to a darker color
                elseif stage == 2 then
                    entity:SetMaterial("models/flesh") -- Change to a more decayed material
                elseif stage == 3 then
                    entity:SetMaterial("models/charple/charple1_sheet") -- Final stage, charred or extremely decayed look
                    entity:SetColor(Color(50, 50, 50)) -- Very dark to indicate extreme decay
                    timer.Remove(uniqueID .. "Flies")
                end
            end
        end

        local stages = 3 -- Set up a timer to manage the decay in stages -- Includes the final non-removal stage
        local stageTime = decayTime / stages
        for i = 1, stages do
            timer.Create(uniqueID .. "DecayStage" .. i, stageTime * i, 1, function() decayStage(i) end)
        end
    end

    function PLUGIN:OnPlayerCorpseCreated(client, entity)
        if not ix.config.Get("dropItemsOnDeath", false) or not client:GetCharacter() then return end
        client:SetLocalVar("ragdoll", entity:EntIndex())
        local character = client:GetCharacter()
        local charInventory = character:GetInventory()
        local width, height = charInventory:GetSize()
        local inventory = ix.inventory.Create(width, height, os.time()) -- create new inventory
        inventory.noSave = true
        if ix.config.Get("dropItemsOnDeath") then
            for _, slot in pairs(charInventory.slots) do
                for _, item in pairs(slot) do
                    if item.bDropOnDeath then
                        if item:GetData("equip") then self:RemoveEquippableItem(client, item) end
                        item:Transfer(inventory:GetID(), item.gridX, item.gridY)
                    end
                end
            end
        end

        entity.ixInventory = inventory
    end

    function PLUGIN:PlayerUse(client, entity)
        if entity:GetClass() == "prop_ragdoll" and entity.ixInventory and not ix.storage.InUse(entity.ixInventory) then
            ix.storage.Open(client, entity.ixInventory, {
                entity = entity,
                name = "Corpse",
                searchText = "@searchingCorpse",
                searchTime = ix.config.Get("corpseSearchTime", 1)
            })
            return false
        end
    end
end