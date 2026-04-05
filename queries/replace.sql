DROP TABLE IF EXISTS replacelist;

CREATE TABLE replacelist (
    category TEXT NOT NULL COLLATE NOCASE,
    id INTEGER NOT NULL,
    name TEXT NOT NULL COLLATE NOCASE,
    PRIMARY KEY (category, id)
);

INSERT INTO replacelist VALUES("mob", "2", "Swamp Thing 1");
INSERT INTO replacelist VALUES("mob", "18", "NPC Base");
INSERT INTO replacelist VALUES("mob", "29", "Merman 1");
INSERT INTO replacelist VALUES("mob", "30", "Merman 2");
INSERT INTO replacelist VALUES("mob", "31", "Merman 3");
INSERT INTO replacelist VALUES("mob", "32", "Swamp Thing 2");
INSERT INTO replacelist VALUES("mob", "33", "Swamp Thing 3");
INSERT INTO replacelist VALUES("mob", "34", "Blood Thing 1");
INSERT INTO replacelist VALUES("mob", "35", "Blood Thing 2");
INSERT INTO replacelist VALUES("mob", "36", "Blood Thing 3");
INSERT INTO replacelist VALUES("mob", "39", "Pirate Skeleton 1");
INSERT INTO replacelist VALUES("mob", "49", "Orc Archer 1");
INSERT INTO replacelist VALUES("mob", "51", "Orc Archer 2");
INSERT INTO replacelist VALUES("mob", "92", "Sarcophagus");
INSERT INTO replacelist VALUES("mob", "93", "Ghoul (Second Part)");
INSERT INTO replacelist VALUES("mob", "95", "Octopus 1");
INSERT INTO replacelist VALUES("mob", "96", "Octopus 2");
INSERT INTO replacelist VALUES("mob", "101", "Fish 1");
INSERT INTO replacelist VALUES("mob", "102", "Fish 2");
INSERT INTO replacelist VALUES("mob", "103", "Fish 3");
INSERT INTO replacelist VALUES("mob", "104", "Fish 4");
INSERT INTO replacelist VALUES("mob", "105", "Fish 5");
INSERT INTO replacelist VALUES("mob", "106", "Fish 6");
INSERT INTO replacelist VALUES("mob", "107", "Fish 7");
INSERT INTO replacelist VALUES("mob", "123", "Spikeball Trap");
INSERT INTO replacelist VALUES("mob", "164", "Merman 4");
INSERT INTO replacelist VALUES("mob", "165", "Merman 5");
INSERT INTO replacelist VALUES("mob", "166", "Merman 6");
INSERT INTO replacelist VALUES("mob", "122", "Baba Yaga House");
INSERT INTO replacelist VALUES("mob", "142", "Pirate Skeleton 2");
INSERT INTO replacelist VALUES("mob", "153", "Tribe 1");
INSERT INTO replacelist VALUES("mob", "154", "Tribe 2");
INSERT INTO replacelist VALUES("mob", "155", "Tribe 3");
INSERT INTO replacelist VALUES("mob", "187", "Crab (Blue)");
INSERT INTO replacelist VALUES("mob", "200", "Thug Penguin 1");
INSERT INTO replacelist VALUES("mob", "201", "Thug Penguin 2");
    
INSERT INTO replacelist VALUES("mob", "203", "Wild Dryad 1");
    
INSERT INTO replacelist VALUES("mob", "211", "Dandelion (mob)");
    
INSERT INTO replacelist VALUES("mob", "214", "Wild Dryad 2");
INSERT INTO replacelist VALUES("mob", "215", "Wild Dryad 3");
    
INSERT INTO replacelist VALUES("item", "290", "Miner Helmet");
    
INSERT INTO replacelist VALUES("item", "358", "Teeth (accessory)");
    
INSERT INTO replacelist VALUES("item", "433", "Witch Coat (unobtainable)");
INSERT INTO replacelist VALUES("item", "434", "Witch Skirt (unobtainable)");
    
INSERT INTO replacelist VALUES("item", "868", "Ghostlands Table 1");
INSERT INTO replacelist VALUES("item", "869", "Ghostlands Table 2");
INSERT INTO replacelist VALUES("item", "870", "Ghostlands Big Table 1");
INSERT INTO replacelist VALUES("item", "871", "Ghostlands Big Table 2");
    
INSERT INTO replacelist VALUES("item", "898", "Tribal Helmet (Set 1)");
INSERT INTO replacelist VALUES("item", "899", "Tribal Armor (Set 1)");
INSERT INTO replacelist VALUES("item", "900", "Tribal Skirt (Set 1)");
INSERT INTO replacelist VALUES("item", "901", "Tribal Helmet (Set 2)");
INSERT INTO replacelist VALUES("item", "902", "Tribal Armor (Set 2)");
INSERT INTO replacelist VALUES("item", "903", "Tribal Skirt (Set 2)");
INSERT INTO replacelist VALUES("item", "904", "Tribal Helmet (Set 3)");
INSERT INTO replacelist VALUES("item", "905", "Tribal Armor (Set 3)");
INSERT INTO replacelist VALUES("item", "906", "Tribal Skirt (Set 3)");
    
INSERT INTO replacelist VALUES("item", "1430", "Merman's Banner 2");
INSERT INTO replacelist VALUES("item", "1452", "Merman's Banner 1");
INSERT INTO replacelist VALUES("item", "1483", "Tribe's Banner 1");
INSERT INTO replacelist VALUES("item", "1484", "Tribe's Banner 2");
INSERT INTO replacelist VALUES("item", "1485", "Tribe's Banner 3");
INSERT INTO replacelist VALUES("item", "1525", "Merman's Soul 2");
INSERT INTO replacelist VALUES("item", "1547", "Merman's Soul 1");
INSERT INTO replacelist VALUES("item", "1578", "Tribe's Soul 1");
INSERT INTO replacelist VALUES("item", "1579", "Tribe's Soul 2");
INSERT INTO replacelist VALUES("item", "1580", "Tribe's Soul 3");

INSERT INTO replacelist VALUES("item", "1726", "Bard's Guitar");
INSERT INTO replacelist VALUES("item", "1787", "Enchantress Helmet");

INSERT INTO replacelist VALUES("item", "1834", "Day Grass Floor 1");
INSERT INTO replacelist VALUES("item", "1835", "Night Grass Floor 1");

INSERT INTO replacelist VALUES("item", "1843", "Day Grass Floor 2");
INSERT INTO replacelist VALUES("item", "1845", "Night Grass Floor 2");
INSERT INTO replacelist VALUES("item", "1951", "Day Flowerpot (Yellow)");
INSERT INTO replacelist VALUES("item", "1992", "Night Flowerpot (Convallaria)");

INSERT INTO replacelist VALUES("npc", "0", "The Guide");
INSERT INTO replacelist VALUES("npc", "1", "The Blacksmith");
INSERT INTO replacelist VALUES("npc", "3", "The Merchant");
INSERT INTO replacelist VALUES("npc", "4", "The Travelling Merchant");
INSERT INTO replacelist VALUES("npc", "5", "The Bard");
INSERT INTO replacelist VALUES("npc", "6", "The Witch");
INSERT INTO replacelist VALUES("npc", "8", "The Miner");
INSERT INTO replacelist VALUES("npc", "9", "The Farmer");
INSERT INTO replacelist VALUES("npc", "10", "The Carpenter");
INSERT INTO replacelist VALUES("npc", "11", "The Skeleton");
INSERT INTO replacelist VALUES("npc", "12", "The Chef");
INSERT INTO replacelist VALUES("npc", "13", "The Fisherman");
INSERT INTO replacelist VALUES("npc", "14", "The Summoner");
INSERT INTO replacelist VALUES("npc", "15", "The Electrician");
INSERT INTO replacelist VALUES("npc", "18", "The Stylist");
INSERT INTO replacelist VALUES("npc", "21", "The Cartographer");
INSERT INTO replacelist VALUES("npc", "26", "The Nurse");
INSERT INTO replacelist VALUES("npc", "27", "The Librarian");
INSERT INTO replacelist VALUES("npc", "28", "The Robot");
INSERT INTO replacelist VALUES("npc", "29", "The Penguin");
INSERT INTO replacelist VALUES("npc", "30", "The Enchantress");



