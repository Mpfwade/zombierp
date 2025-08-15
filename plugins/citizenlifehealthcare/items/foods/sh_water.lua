-- Item Statistics

ITEM.name = "Water Can"
ITEM.description = "A Blue can filled with delicious water."
ITEM.bDropOnDeath = true
ITEM.weight = 0.45

-- Item Configuration
ITEM.model = "models/props_junk/PopCan01a.mdl"
ITEM.skin = 0

-- Item Inventory Size Configuration
ITEM.width = 1
ITEM.height = 1

-- Item Custom Configuration
ITEM.useTime = 0.01
ITEM.useSound = "npc/barnacle/barnacle_gulp2.wav"
ITEM.RestoreHunger = 1

-- On use, make the player forget recognized characters
function ITEM:OnUse(player)
    if SERVER then -- Ensure this logic only runs on the server
        local character = player:GetCharacter()
        if character then
            -- Call the ForgetRecognized method on the character
            character:ForgetRecognized()
            -- Optional: Notify the player they have forgotten everyone.
            player:Notify("You feel a wave of amnesia wash over you. Faces become unfamiliar.")
        end
        
        -- Play the use sound
        player:EmitSound(self.useSound)
    end
    
    return true
end