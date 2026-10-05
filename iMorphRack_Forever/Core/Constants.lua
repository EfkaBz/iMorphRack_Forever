-- iMorph Rack (Forever) : races, emplacements, catégories, commandes d'apparence
local _, ns = ...

ns.ICON = "Interface\\AddOns\\iMorphRack_Forever\\media\\icon"

ns.RACES = {
    { id = 1, name = "Human" },
    { id = 2, name = "Orc" },
    { id = 3, name = "Dwarf" },
    { id = 4, name = "Night Elf" },
    { id = 5, name = "Undead" },
    { id = 6, name = "Tauren" },
    { id = 7, name = "Gnome" },
    { id = 8, name = "Troll" },
}

-- Races ajoutées après Vanilla : iMorph les accepte seulement si le client a les modèles
ns.EXTRA_RACES = {
    { id = 9,  name = "Goblin" },
    { id = 10, name = "Blood Elf" },
    { id = 11, name = "Draenei" },
    { id = 22, name = "Worgen" },
    { id = 24, name = "Pandaren" },
    { id = 27, name = "Nightborne" },
    { id = 28, name = "Highmountain Tauren" },
    { id = 29, name = "Void Elf" },
    { id = 30, name = "Lightforged Draenei" },
    { id = 31, name = "Zandalari Troll" },
    { id = 32, name = "Kul Tiran" },
    { id = 34, name = "Dark Iron Dwarf" },
    { id = 35, name = "Vulpera" },
    { id = 36, name = "Mag'har Orc" },
    { id = 37, name = "Mechagnome" },
    { id = 52, name = "Dracthyr" },
    { id = 84, name = "Earthen" },
    { id = 12, name = "Fel Orc" },
    { id = 13, name = "Naga" },
    { id = 14, name = "Broken" },
    { id = 15, name = "Skeleton" },
    { id = 16, name = "Vrykul" },
    { id = 17, name = "Tuskarr" },
    { id = 18, name = "Forest Troll" },
    { id = 19, name = "Taunka" },
    { id = 20, name = "Northrend Skeleton" },
    { id = 21, name = "Ice Troll" },
}

ns.SLOTS = {
    { id = 1,  name = "Head" },
    { id = 3,  name = "Shoulders" },
    { id = 4,  name = "Shirt" },
    { id = 5,  name = "Chest" },
    { id = 6,  name = "Waist" },
    { id = 7,  name = "Legs" },
    { id = 8,  name = "Feet" },
    { id = 9,  name = "Wrists" },
    { id = 10, name = "Hands" },
    { id = 15, name = "Back" },
    { id = 16, name = "Main hand" },
    { id = 17, name = "Off hand" },
    { id = 18, name = "Ranged" },
    { id = 19, name = "Tabard" },
}

-- Catégories d'objet (classe * 100 + sous-classe)
ns.CATEGORIES = {
    { id = 401, name = "Cloth" }, { id = 402, name = "Leather" }, { id = 403, name = "Mail" },
    { id = 404, name = "Plate" }, { id = 400, name = "Misc. armor" }, { id = 406, name = "Shield" },
    { id = 200, name = "One-handed axe" }, { id = 201, name = "Two-handed axe" },
    { id = 204, name = "One-handed mace" }, { id = 205, name = "Two-handed mace" },
    { id = 207, name = "One-handed sword" }, { id = 208, name = "Two-handed sword" },
    { id = 215, name = "Dagger" }, { id = 213, name = "Fist weapon" }, { id = 206, name = "Polearm" },
    { id = 217, name = "Spear" }, { id = 210, name = "Staff" }, { id = 202, name = "Bow" },
    { id = 218, name = "Crossbow" }, { id = 203, name = "Gun" }, { id = 216, name = "Thrown" },
    { id = 219, name = "Wand" }, { id = 220, name = "Fishing pole" }, { id = 214, name = "Misc. weapon" },
}

-- Commandes cosmétiques (uniquement visuelles, côté client)
ns.APPEARANCE = {
    { cmd = ".morph",    label = "Morph (display ID)" },
    { cmd = ".scale",    label = "Character scale" },
    { cmd = ".mount",    label = "Mount (display ID)" },
    { cmd = ".itemset",  label = "Item set (ID)" },
    { cmd = ".skin",     label = "Skin" },
    { cmd = ".face",     label = "Face" },
    { cmd = ".hair",     label = "Hair style" },
    { cmd = ".haircolor",label = "Hair color" },
    { cmd = ".features", label = "Facial features" },
    { cmd = ".title",    label = "Title (ID)" },
}
