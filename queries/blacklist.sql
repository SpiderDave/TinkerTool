DROP TABLE IF EXISTS blacklist;

CREATE TABLE blacklist (
    category TEXT NOT NULL COLLATE NOCASE,
    id INTEGER NOT NULL,
    PRIMARY KEY (category, id)
);

INSERT INTO blacklist VALUES ('biome', 16); -- Settlement
INSERT INTO blacklist VALUES ('biome', 36); -- Swamp City
INSERT INTO blacklist VALUES ('biome', 37); -- Pirate Outpost
INSERT INTO blacklist VALUES ('biome', 44); -- Crab Land

INSERT INTO blacklist VALUES ('recipe', 265); -- Wasteland Wood Coal recipe
INSERT INTO blacklist VALUES ('recipe', 266); -- Fir Wood Coal recipe
INSERT INTO blacklist VALUES ('recipe', 267); -- Swamp Wood Coal recipe
INSERT INTO blacklist VALUES ('recipe', 268); -- Mushroom Wood Coal recipe

INSERT INTO blacklist VALUES ('recipe', 184); -- ourobook (Quetzalcoatl Spell)
INSERT INTO blacklist VALUES ('recipe', 185); -- serpent_whip (Quetzalcoatl Whip)
INSERT INTO blacklist VALUES ('recipe', 188); -- ourobowros (Quetzalcoatl Bow)
INSERT INTO blacklist VALUES ('recipe', 189); -- staff_ouroboros (Quetzalcoatl Staff)

INSERT INTO blacklist VALUES ('mob', 3); -- Null (flying_eye)
INSERT INTO blacklist VALUES ('mob', 79); -- Etc (dev_mob)
INSERT INTO blacklist VALUES ('mob', 112); -- Swamp Worm
INSERT INTO blacklist VALUES ('mob', 115); -- Crystal Golem
INSERT INTO blacklist VALUES ('mob', 116); -- Crystal Slime
INSERT INTO blacklist VALUES ('mob', 117); -- Crystal Spirit
INSERT INTO blacklist VALUES ('mob', 121); -- Mimic
INSERT INTO blacklist VALUES ('mob', 124); -- Null (trap_spike_runner)
INSERT INTO blacklist VALUES ('mob', 129); -- Sun Lion
INSERT INTO blacklist VALUES ('mob', 131); -- Sentinel
INSERT INTO blacklist VALUES ('mob', 133); -- Gunslinger Pirate
INSERT INTO blacklist VALUES ('mob', 135); -- Swordsman Pirate
INSERT INTO blacklist VALUES ('mob', 137); -- Monkey Pirate
INSERT INTO blacklist VALUES ('mob', 138); -- Pirate Leader
INSERT INTO blacklist VALUES ('mob', 144); -- Bee
INSERT INTO blacklist VALUES ('mob', 157); -- Swordsman Pirate
INSERT INTO blacklist VALUES ('mob', 158); -- Swordsman Pirate
INSERT INTO blacklist VALUES ('mob', 159); -- Young Turtle
INSERT INTO blacklist VALUES ('mob', 192); -- Green Slime (boss_mushroom)
INSERT INTO blacklist VALUES ('mob', 193); -- Mushroom Worker (mushroom_worker_01)
INSERT INTO blacklist VALUES ('mob', 194); -- Mushroom Worker (mushroom_worker_02)
INSERT INTO blacklist VALUES ('mob', 195); -- Mushroom Worker (mushroom_worker_03)

INSERT INTO blacklist VALUES ('item', 165); -- Celerity Ring
INSERT INTO blacklist VALUES ('item', 141); -- Worn Out Boots
INSERT INTO blacklist VALUES ('item', 143); -- Worn Out Shirt
INSERT INTO blacklist VALUES ('item', 235); -- Captain Armor
INSERT INTO blacklist VALUES ('item', 236); -- Captain Boots
INSERT INTO blacklist VALUES ('item', 237); -- Captain Helmet
INSERT INTO blacklist VALUES ('item', 271); -- Jester Armor (npc_jester_armor)
INSERT INTO blacklist VALUES ('item', 272); -- Jester Boots (npc_jester_pants)
INSERT INTO blacklist VALUES ('item', 273); -- Jester Hat (npc_jester_helmet)
INSERT INTO blacklist VALUES ('item', 318); -- Null (dev_item)
INSERT INTO blacklist VALUES ('item', 328); -- Working Table T1 (working_table_tier_one)
INSERT INTO blacklist VALUES ('item', 364); -- Null (magic_scroll_moon)
INSERT INTO blacklist VALUES ('item', 365); -- Null (magic_scroll_sun)
INSERT INTO blacklist VALUES ('item', 379); -- Eye Patch
INSERT INTO blacklist VALUES ('item', 391); -- Sulfur
INSERT INTO blacklist VALUES ('item', 426); -- Coral Wall (wall_coral) - icon looks blood red

INSERT INTO blacklist VALUES ('item', 432); -- Witch Hat (unused black outfit)
INSERT INTO blacklist VALUES ('item', 433); -- Witch Coat (unused black outfit)
INSERT INTO blacklist VALUES ('item', 434); -- Witch Skirt (unused black outfit)

INSERT INTO blacklist VALUES ('item', 437); -- Ghostbuster
INSERT INTO blacklist VALUES ('item', 441); -- Wind Sail
INSERT INTO blacklist VALUES ('item', 443); -- Geode Pendant
INSERT INTO blacklist VALUES ('item', 444); -- Geode
INSERT INTO blacklist VALUES ('item', 445); -- Saltpeter
INSERT INTO blacklist VALUES ('item', 446); -- Black Powder
INSERT INTO blacklist VALUES ('item', 447); -- Detonator Belt
INSERT INTO blacklist VALUES ('item', 448); -- Defuse Kit
INSERT INTO blacklist VALUES ('item', 449); -- Hand Grenade
INSERT INTO blacklist VALUES ('item', 450); -- Prisma Sword
INSERT INTO blacklist VALUES ('item', 451); -- Prisma Staff
INSERT INTO blacklist VALUES ('item', 452); -- Prisma Bow
INSERT INTO blacklist VALUES ('item', 459); -- Prism Crystal
INSERT INTO blacklist VALUES ('item', 460); -- Swamp Atlantis Chest
INSERT INTO blacklist VALUES ('item', 461); -- Swamp Atlantis Bed
INSERT INTO blacklist VALUES ('item', 462); -- Swamp Atlantis Door
INSERT INTO blacklist VALUES ('item', 463); -- Swamp Atlantis Table
INSERT INTO blacklist VALUES ('item', 464); -- Swamp Atlantis Flowerpot
INSERT INTO blacklist VALUES ('item', 534); -- Sun Gun

INSERT INTO blacklist VALUES ('item', 540); -- Sunlight Hammer

INSERT INTO blacklist VALUES ('item', 562); -- Sun Chest
INSERT INTO blacklist VALUES ('item', 563); -- Moon Chest

INSERT INTO blacklist VALUES ('item', 567); -- Lock
INSERT INTO blacklist VALUES ('item', 568); -- Coin Gun
INSERT INTO blacklist VALUES ('item', 569); -- Keyblade
INSERT INTO blacklist VALUES ('item', 581); -- Enhanced Propulsion
INSERT INTO blacklist VALUES ('item', 582); -- Magic Key
INSERT INTO blacklist VALUES ('item', 583); -- Credit Card
INSERT INTO blacklist VALUES ('item', 588); -- Pirate Gun
INSERT INTO blacklist VALUES ('item', 589); -- Hand Hook
INSERT INTO blacklist VALUES ('item', 590); -- Spyglass
INSERT INTO blacklist VALUES ('item', 591); -- Pirate Coin
INSERT INTO blacklist VALUES ('item', 592); -- Orange
INSERT INTO blacklist VALUES ('item', 593); -- Gun Ammo
INSERT INTO blacklist VALUES ('item', 594); -- Serpentinite Ammo
INSERT INTO blacklist VALUES ('item', 595); -- Spectrite Ammo
INSERT INTO blacklist VALUES ('item', 596); -- Coralite Ammo
INSERT INTO blacklist VALUES ('item', 597); -- Falchion
INSERT INTO blacklist VALUES ('item', 598); -- Wooden Bow (parry_shield)
INSERT INTO blacklist VALUES ('item', 604); -- Mirage Scroll
INSERT INTO blacklist VALUES ('item', 670); -- Soul Linker
INSERT INTO blacklist VALUES ('item', 744); -- Bait
INSERT INTO blacklist VALUES ('item', 840); -- Rusty Armor (npc_collection_armor)
INSERT INTO blacklist VALUES ('item', 841); -- Rusty Boots (npc_collection_pants)
INSERT INTO blacklist VALUES ('item', 842); -- Rusty Helmet (npc_collection_helmet)
INSERT INTO blacklist VALUES ('item', 843); -- Rusty Armor (npc_pirate_armor)
INSERT INTO blacklist VALUES ('item', 844); -- Rusty Boots (npc_pirate_pants)
INSERT INTO blacklist VALUES ('item', 845); -- Rusty Helmet (npc_pirate_helmet)
INSERT INTO blacklist VALUES ('item', 874); -- Ghostlands Mirror (ghostlands_mirror_01), alternate mirror, unused maybe
INSERT INTO blacklist VALUES ('item', 876); -- Ghostlands Piano (unobtainable)
INSERT INTO blacklist VALUES ('item', 920); -- Stolen Items
INSERT INTO blacklist VALUES ('item', 981); -- Coral Bench
INSERT INTO blacklist VALUES ('item', 1004); -- Bounty Hunter Eye Patch
INSERT INTO blacklist VALUES ('item', 1005); -- Bounty Hunter Armor
INSERT INTO blacklist VALUES ('item', 1006); -- Bounty Hunter Boots
INSERT INTO blacklist VALUES ('item', 1007); -- Hand Cannon
INSERT INTO blacklist VALUES ('item', 1008); -- Pirate Flag
INSERT INTO blacklist VALUES ('item', 1009); -- Gunner Table
INSERT INTO blacklist VALUES ('item', 1044); -- Angra Manyu
INSERT INTO blacklist VALUES ('item', 1046); -- Long Lance
INSERT INTO blacklist VALUES ('item', 1047); -- Bo
INSERT INTO blacklist VALUES ('item', 1048); -- Blue Lightsaber
INSERT INTO blacklist VALUES ('item', 1049); -- Red Lightsaber
INSERT INTO blacklist VALUES ('item', 1050); -- Tonfa
INSERT INTO blacklist VALUES ('item', 1052); -- Hula-Hoop Blade
INSERT INTO blacklist VALUES ('item', 1053); -- Frying Pan
INSERT INTO blacklist VALUES ('item', 1054); -- Battle Axe
INSERT INTO blacklist VALUES ('item', 1055); -- Whip
INSERT INTO blacklist VALUES ('item', 1058); -- Kusarigama
INSERT INTO blacklist VALUES ('item', 1060); -- Uzi
INSERT INTO blacklist VALUES ('item', 1061); -- Shotgun
INSERT INTO blacklist VALUES ('item', 1062); -- Rocket Launcher
INSERT INTO blacklist VALUES ('item', 1073); -- Blue Wood
INSERT INTO blacklist VALUES ('item', 1074); -- Red Wood
INSERT INTO blacklist VALUES ('item', 1075); -- Yellow Wood
INSERT INTO blacklist VALUES ('item', 1080); -- Crab Statue
INSERT INTO blacklist VALUES ('item', 1083); -- Trash Gun
INSERT INTO blacklist VALUES ('item', 1087); -- Spatula
INSERT INTO blacklist VALUES ('item', 1088); -- Apron
INSERT INTO blacklist VALUES ('item', 1089); -- Kitchen Gloves
INSERT INTO blacklist VALUES ('item', 1090); -- Grill
INSERT INTO blacklist VALUES ('item', 1092); -- Blacksmith Hammer
INSERT INTO blacklist VALUES ('item', 1109); -- Yellow Halberd
INSERT INTO blacklist VALUES ('item', 1208); -- Null (top_bottle)
INSERT INTO blacklist VALUES ('item', 1209); -- Null (top_window)
INSERT INTO blacklist VALUES ('item', 1246); -- Insta House
INSERT INTO blacklist VALUES ('item', 1262); -- Swamp Worm Statue
INSERT INTO blacklist VALUES ('item', 1312); -- Tricolor Flowerpot
INSERT INTO blacklist VALUES ('item', 1318); -- Pirate Monkey Statue
INSERT INTO blacklist VALUES ('item', 1335); -- Wall Light
INSERT INTO blacklist VALUES ('item', 1356); -- Painting (top_chains)
INSERT INTO blacklist VALUES ('item', 1358); -- Painting (top_fishbowl_01)
INSERT INTO blacklist VALUES ('item', 1359); -- Crystal Snowglobe
INSERT INTO blacklist VALUES ('item', 1360); -- Sign (top_wall_plant01)
INSERT INTO blacklist VALUES ('item', 1374); -- Improved Minecart Track
INSERT INTO blacklist VALUES ('item', 1480); -- Swamp Worm's Banner
INSERT INTO blacklist VALUES ('item', 1497); -- Burning Core
INSERT INTO blacklist VALUES ('item', 1574); -- Swamp Worm's Soul
INSERT INTO blacklist VALUES ('item', 1615); -- Statue (statue_mushroom_worker)
INSERT INTO blacklist VALUES ('item', 1619); -- Mushroom Worker's Banner
INSERT INTO blacklist VALUES ('item', 1623); -- Mushroom Worker's Soul
INSERT INTO blacklist VALUES ('item', 1632); -- Ash Wall
INSERT INTO blacklist VALUES ('item', 1633); -- Chili
INSERT INTO blacklist VALUES ('item', 1650); -- Null (pet_broom)
INSERT INTO blacklist VALUES ('item', 1651); -- Scouter (accesory_scouter)
INSERT INTO blacklist VALUES ('item', 1688); -- Red Antenna
INSERT INTO blacklist VALUES ('item', 1689); -- Blue Antenna
INSERT INTO blacklist VALUES ('item', 1690); -- Green Antenna
INSERT INTO blacklist VALUES ('item', 1692); -- Dynamo Key
INSERT INTO blacklist VALUES ('item', 1693); -- Energy Lasso
INSERT INTO blacklist VALUES ('item', 1694); -- Rigged Dice

INSERT INTO blacklist VALUES ('item', 1739); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1740); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1741); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1742); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1743); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1744); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1745); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1746); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1747); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1748); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1749); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1750); -- Sound Platform
INSERT INTO blacklist VALUES ('item', 1751); -- Sound Platform

INSERT INTO blacklist VALUES ('item', 1854); -- Crab Map

INSERT INTO blacklist VALUES ('item', 1893); -- Day Phoenix Egg
INSERT INTO blacklist VALUES ('item', 1894); -- Night Phoenix Egg
INSERT INTO blacklist VALUES ('item', 1900); -- Day Phoenix's Soul
INSERT INTO blacklist VALUES ('item', 1901); -- Night Phoenix's Soul
INSERT INTO blacklist VALUES ('item', 1962); -- Twilight Amulet

INSERT INTO blacklist VALUES ('recipe', 238); -- Ghostbuster (Recipe)
INSERT INTO blacklist VALUES ('recipe', 360); -- dev_recipe

INSERT INTO blacklist VALUES ('summon', 37); -- pet_phoenix


