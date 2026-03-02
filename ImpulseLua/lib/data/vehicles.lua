--[[
    Impulse Lua - Vehicle Data
    Port of vehicles.h
]]

local Vehicles = {
    boats = {
        "DINGHY", "DINGHY2", "DINGHY3", "DINGHY4", "JETMAX", "MARQUIS", "PREDATOR", "SEASHARK",
        "SEASHARK2", "SEASHARK3", "SPEEDER", "SPEEDER2", "SQUALO", "SUBMERSIBLE", "SUBMERSIBLE2",
        "SUNTRAP", "TORO", "TORO2", "TROPIC", "TROPIC2", "TUG"
    },
    commercial = {
        "BENSON", "BIFF", "HAULER", "MULE", "MULE2", "MULE3", "PACKER", "PHANTOM", "POUNDER",
        "STOCKADE", "STOCKADE3", "HAULER2", "PHANTOM3", "MULE4", "POUNDER2", "TERBYTE", "PBUS2",
        "CERBERUS", "CERBERUS2", "CERBERUS3"
    },
    compacts = {
        "BLISTA", "BRIOSO", "DILETTANTE", "DILETTANTE2", "ISSI2", "PANTO", "PRAIRIE", "RHAPSODY",
        "ISSI3", "ISSI4", "ISSI5", "ISSI6"
    },
    coupes = {
        "COGCABRIO", "EXEMPLAR", "F620", "FELON", "FELON2", "JACKAL", "ORACLE", "ORACLE2",
        "SENTINEL", "SENTINEL2", "WINDSOR", "WINDSOR2", "ZION", "ZION2"
    },
    cycles = {
        "BMX", "CRUISER", "FIXTER", "SCORCHER", "TRIBIKE", "TRIBIKE2", "TRIBIKE3"
    },
    emergency = {
        "AMBULANCE", "FBI", "FBI2", "FIRETRUK", "LGUARD", "PBUS", "PRANGER", "POLICE",
        "POLICE2", "POLICE3", "POLICE4", "POLICEB", "POLICEOLD1", "POLICEOLD2", "POLICET",
        "SHERIFF", "SHERIFF2", "RIOT", "RIOT2"
    },
    helicopters = {
        "ANNIHILATOR", "BLIMP", "BLIMP2", "BUZZARD", "BUZZARD2", "CARGOBOB", "CARGOBOB2",
        "CARGOBOB3", "CARGOBOB4", "FROGGER", "FROGGER2", "MAVERICK", "POLMAV", "SAVAGE",
        "SKYLIFT", "SUPERVOLITO", "SUPERVOLITO2", "SWIFT", "SWIFT2", "VALKYRIE", "VALKYRIE2",
        "VOLATUS", "HAVOK", "HUNTER", "AKULA", "SEASPARROW"
    },
    industrial = {
        "BULLDOZER", "CUTTER", "DUMP", "FLATBED", "GUARDIAN", "HANDLER", "MIXER", "MIXER2",
        "RUBBLE", "TIPTRUCK", "TIPTRUCK2"
    },
    military = {
        "BARRACKS", "BARRACKS2", "BARRACKS3", "CRUSADER", "RHINO", "APC", "HALFTRACK",
        "TRAILERSMALL2", "VIGILANTE", "BARRAGE", "CHERNOBOG", "KHANJALI", "THRUSTER",
        "SCARAB", "SCARAB2", "SCARAB3"
    },
    motorcycles = {
        "AKUMA", "AVARUS", "BAGGER", "BATI", "BATI2", "BF400", "CARBONRS", "CHIMERA",
        "CLIFFHANGER", "DAEMON", "DAEMON2", "DEFILER", "DOUBLE", "ENDURO", "ESSKEY",
        "FAGGIO", "FAGGIO2", "FAGGIO3", "GARGOYLE", "HAKUCHOU", "HAKUCHOU2", "HEXER",
        "INNOVATION", "LECTRO", "MANCHEZ", "NEMESIS", "NIGHTBLADE", "PCJ", "RATBIKE",
        "RUFFIAN", "SANCHEZ", "SANCHEZ2", "SANCTUS", "SHOTARO", "SOVEREIGN", "THRUST",
        "VADER", "VINDICATOR", "VORTEX", "WOLFSBANE", "ZOMBIEA", "ZOMBIEB", "DIABLOUS",
        "DIABLOUS2", "FCR", "FCR2", "OPPRESSOR", "OPPRESSOR2", "DEATHBIKE", "DEATHBIKE2", "DEATHBIKE3"
    },
    muscle = {
        "BLADE", "BUCCANEER", "BUCCANEER2", "CHINO", "CHINO2", "COQUETTE3", "DOMINATOR",
        "DOMINATOR2", "DUKES", "DUKES2", "GAUNTLET", "GAUNTLET2", "FACTION", "FACTION2",
        "FACTION3", "HOTKNIFE", "LURCHER", "MOONBEAM", "MOONBEAM2", "NIGHTSHADE", "PHOENIX",
        "PICADOR", "RATLOADER", "RATLOADER2", "RUINER", "RUINER2", "RUINER3", "SABREGT",
        "SABREGT2", "SLAMVAN", "SLAMVAN2", "SLAMVAN3", "STALION", "STALION2", "TAMPA",
        "VIGERO", "VIRGO", "VIRGO2", "VIRGO3", "VOODOO", "VOODOO2", "TAMPA3", "HUSTLER",
        "HERMES", "YOSEMITE", "DOMINATOR3", "ELLIE", "IMPALER", "IMPALER2", "IMPALER3",
        "IMPALER4", "DEVIANT", "VAMOS", "CLIQUE", "TULIP", "DOMINATOR4", "DOMINATOR5",
        "DOMINATOR6", "SLAMVAN4", "SLAMVAN5", "SLAMVAN6"
    },
    offroad = {
        "BFINJECTION", "BIFTA", "BLAZER", "BLAZER2", "BLAZER3", "BLAZER4", "BODHI2", "BRAWLER",
        "DLOADER", "DUBSTA3", "DUNE", "DUNE2", "INSURGENT", "INSURGENT2", "KALAHARI",
        "MARSHALL", "MESA3", "MONSTER", "RANCHERXL", "RANCHERXL2", "REBEL", "REBEL2",
        "SANDKING", "SANDKING2", "TECHNICAL", "TROPHYTRUCK", "TROPHYTRUCK2", "TECHNICAL2",
        "DUNE4", "DUNE5", "BLAZER5", "DUNE3", "INSURGENT3", "NIGHTSHARK", "TECHNICAL3",
        "KAMACHO", "RIATA", "CARACARA", "FREECRAWLER", "MENACER", "MONSTER3", "MONSTER4",
        "MONSTER5", "RCBANDITO", "BRUISER", "BRUISER2", "BRUISER3", "BRUTUS", "BRUTUS2",
        "BRUTUS3"
    },
    planes = {
        "BESRA", "CARGOPLANE", "CUBAN800", "DODO", "DUSTER", "HYDRA", "JET", "LAZER",
        "LUXOR", "LUXOR2", "MAMMATUS", "MILJET", "NIMBUS", "SHAMAL", "STUNT", "TITAN",
        "VELUM", "VELUM2", "VESTRA", "ALPHAZ1", "BOMBUSHKA", "HOWARD", "MICROLIGHT",
        "MOGUL", "MOLOTOK", "NOKOTA", "PYRO", "ROGUE", "SEABREEZE", "STARLING", "TULA",
        "VOLATOL", "BLIMP3", "STRIKEFORCE"
    },
    sedans = {
        "ASEA", "ASEA2", "ASTEROPE", "COG55", "COG552", "COGNOSCENTI", "COGNOSCENTI2",
        "EMPEROR", "EMPEROR2", "EMPEROR3", "FUGITIVE", "GLENDALE", "INGOT", "INTRUDER",
        "LIMO2", "PREMIER", "PRIMO", "PRIMO2", "REGINA", "ROMERO", "SCHAFTER2", "SCHAFTER5",
        "SCHAFTER6", "STANIER", "STRATUM", "STRETCH", "SUPERD", "SURGE", "TAILGATER",
        "WARRENER", "WASHINGTON", "STAFFORD"
    },
    service = {
        "AIRBUS", "BRICKADE", "BUS", "COACH", "RALLYTRUCK", "RENTALBUS", "TAXI", "TOURBUS",
        "TRASH", "TRASH2", "WASTELANDER"
    },
    sports = {
        "ALPHA", "BANSHEE", "BANSHEE2", "BESTIAGTS", "BLISTA2", "BLISTA3", "BUFFALO",
        "BUFFALO2", "BUFFALO3", "CARBONIZZARE", "COMET2", "COQUETTE", "ELEGY", "ELEGY2",
        "FELTZER2", "FUROREGT", "FUSILADE", "FUTO", "JESTER", "JESTER2", "KHAMELION",
        "KURUMA", "KURUMA2", "LYNX", "MASSACRO", "MASSACRO2", "NINEF", "NINEF2", "OMNIS",
        "PENUMBRA", "RAPIDGT", "RAPIDGT2", "RAPTOR", "SCHAFTER3", "SCHAFTER4", "SCHWARZER",
        "SEVEN70", "SULTAN", "SURANO", "SPECTER", "SPECTER2", "TAMPA2", "TROPOS", "VERLIERER2",
        "RUINER2", "RUSTON", "COMET4", "COMET5", "NEON", "PARIAH", "RAIDEN", "REVOLTER",
        "STREITER", "SENTINEL3", "FLASHGT", "GB200", "ZR380", "ZR3802", "ZR3803",
        "SCHLAGEN", "ITALIGTO"
    },
    sportsclassic = {
        "BTYPE", "BTYPE2", "BTYPE3", "CASCO", "COQUETTE2", "FELTZER3", "JB700", "MAMBA",
        "MANANA", "MONROE", "PEYOTE", "PIGALLE", "STINGER", "STINGERGT", "TORNADO",
        "TORNADO2", "TORNADO3", "TORNADO4", "TORNADO5", "TORNADO6", "ZTYPE", "INFERNUS2",
        "TURISMO2", "ARDENT", "CHEETAH2", "TORERO", "RAPIDGT3", "RETINUE", "DELUXO",
        "STROMBERG", "GT500", "SAVESTRA", "VISERIS", "Z190", "CHEBUREK", "FAGALOA",
        "HOTRING", "JESTER3", "MICHELLI", "SWINGER"
    },
    super = {
        "adder", "bullet", "cheetah", "entityxf", "fmj", "sheava", "infernus", "nero",
        "nero2", "osiris", "le7b", "italigtb", "italigtb2", "pfister811", "prototipo",
        "reaper", "sultanrs", "t20", "tempesta", "turismor", "tyrus", "vacca", "voltic",
        "zentorno", "voltic2", "penetrator", "gp1", "vagner", "xa21", "vigilante",
        "cyclone", "autarch", "sc1", "entity2", "taipan", "tezeract", "tyrant",
        "scramjet", "deveste"
    },
    suv = {
        "BALLER", "BALLER2", "BALLER3", "BALLER4", "BALLER5", "BALLER6", "BJXL",
        "CAVALCADE", "CAVALCADE2", "CONTENDER", "DUBSTA", "DUBSTA2", "FQ2", "GRANGER",
        "GRESLEY", "HABANERO", "HUNTLEY", "LANDSTALKER", "MESA", "MESA2", "PATRIOT",
        "RADI", "ROCOTO", "SEMINOLE", "SERRANO", "XLS", "XLS2", "PATRIOT2", "TOROS"
    },
    trailer = {
        "ARMYTANKER", "ARMYTRAILER", "ARMYTRAILER2", "BALETRAILER", "BOATTRAILER",
        "DOCKTRAILER", "FREIGHTTRAILER", "GRAINTRAILER", "PROPTRAILER", "RAKETRAILER",
        "TANKER", "TANKER2", "TR2", "TR3", "TR4", "TRAILERLOGS", "TRAILERS", "TRAILERS2",
        "TRAILERS3", "TRAILERSMALL", "TRFLAT", "TVTRAILER"
    },
    trains = {
        "CABLECAR", "FREIGHT", "FREIGHTCAR", "FREIGHTCONT1", "FREIGHTCONT2",
        "FREIGHTGRAIN", "METROTRAIN", "TANKERCAR"
    },
    utility = {
        "AIRTUG", "CADDY", "CADDY2", "DOCKTUG", "FORKLIFT", "MOWER", "SADLER", "SADLER2",
        "SCRAP", "TOWTRUCK", "TOWTRUCK2", "TRACTOR", "TRACTOR2", "TRACTOR3", "UTILLITRUCK",
        "UTILLITRUCK2", "UTILLITRUCK3", "CADDY3", "TRAILERLARGE", "TRAILERS4", "PHANTOM2"
    },
    van = {
        "BISON", "BISON2", "BISON3", "BOBCATXL", "BOXVILLE", "BOXVILLE2", "BOXVILLE3",
        "BOXVILLE4", "BURRITO", "BURRITO2", "BURRITO3", "BURRITO4", "BURRITO5", "CAMPER",
        "GBURRITO", "GBURRITO2", "JOURNEY", "MINIVAN", "MINIVAN2", "PARADISE", "PONY",
        "PONY2", "RUMPO", "RUMPO2", "RUMPO3", "SPEEDO", "SPEEDO2", "SURFER", "SURFER2",
        "TACO", "YOUGA", "YOUGA2", "SPEEDO4"
    },
    dlcbb = { "bifta", "kalahari", "paradise", "speeder" },
    dlcvdm = { "btype3" },
    dlcb = { "alpha", "jester", "turismor", "vestra" },
    dlchl = { "thrust", "zentorno", "massacro", "huntley" },
    dlcnah = { "pigalle", "blade", "rhapsody", "warrener", "glendale", "panto", "dubsta3" },
    dlcids = { "sovereign", "monster" },
    dlcfs = { "besra", "miljet", "swift", "coquette2" },
    dlclts = { "hakuchou", "innovation", "furoregt" },
    dlcfs14 = { "slamvan", "ratloader2", "massacro2", "jester2" },
    dlch = {
        "enduro", "guardian", "kuruma", "kuruma2", "casco", "velum2", "hydra", "insurgent",
        "insurgent2", "valkyrie", "mule3", "technical", "boxville4", "gburrito2", "savage",
        "lectro", "trash2", "slamvan2", "tanker2", "barracks3", "dinghy3"
    },
    dlciggp1 = { "osiris", "virgo", "windsor", "feltzer3", "luxor2", "swift2" },
    dlciggp2 = { "brawler", "chino", "coquette3", "t20", "toro", "vindicator" },
    dlcfme = {
        "submersible2", "dukes", "dukes2", "buffalo3", "dominator2", "dodo", "marshall",
        "blimp2", "gauntlet2", "stalion", "stalion2", "blista2", "blista3"
    },
    dlchs = { "btype2", "lurcher" },
    dlceaoc = {
        "supervolito", "supervolito2", "limo2", "schafter4", "schafter6", "schafter3",
        "schafter5", "nightshade", "mamba", "verlierer2", "cognoscenti", "cognoscenti2",
        "cog55", "cog552", "baller3", "baller5", "baller4", "baller6", "dinghy4",
        "seashark3", "speeder2", "dinghy4", "toro2", "cargobob4", "valkyrie2"
    },
    dlcfs15 = { "tampa" },
    dlcj16 = { "banshee2", "sultanrs" },
    dlcbmv = { "btype3" },
    dlclcc = {
        "faction", "faction2", "moonbeam", "moonbeam2", "primo2", "chino2",
        "buccaneer2", "voodoo"
    },
    dlclrof = {
        "faction3", "minivan2", "sabregt2", "slamvan3", "tornado5", "virgo2", "virgo3"
    },
    dlcfaf = {
        "xls", "xls2", "rumpo3", "nimbus", "tug", "volatus", "windsor2", "bestiagts",
        "brickade", "reaper", "fmj", "seven70", "prototipo", "pfister811"
    },
    dlccs = {
        "le7b", "sheava", "brioso", "tropos", "omnis", "tyrus", "trophytruck2",
        "trophytruck", "gargoyle", "tampa2", "rallytruck", "lynx", "contender", "cliffhanger"
    },
    dlcbu = {
        "avarus", "manchez", "chimera", "blazer4", "faggio3", "faggio2", "defiler",
        "hakuchou2", "nightblade", "ratbike", "wolfsbane", "zombiea", "zombieb",
        "raptor", "youga2", "tornado6", "sanctus", "shotaro", "esskey", "vortex", "daemon2"
    },
    dlcie = {
        "elegy", "dune5", "dune4", "boxville5", "voltic2", "ruiner3", "ruiner2",
        "phantom2", "technical2", "wastelander", "blazer5", "penetrator", "tempesta",
        "diablous", "diablous2", "specter", "specter2", "fcr", "fcr2", "comet3",
        "italigtb", "italigtb2", "nero", "nero2"
    },
    dlcsvc = { "gp1", "turismo2", "ruston", "infernus2" },
    dlcgr = {
        "apc", "ardent", "caddy3", "cheetah2", "dune3", "halftrack", "hauler2",
        "insurgent3", "nightshark", "oppressor", "phantom3", "tampa3", "technical3",
        "torero", "trailerlarge", "trailers4", "trailersmall2", "vagner", "xa21"
    },
    dlcsr = {
        "alphaz1", "cyclone", "bombushka", "havok", "howard", "hunter", "microlight",
        "mogul", "molotok", "nokota", "pyro", "rapidgt3", "retinue", "rogue",
        "seabreeze", "starling", "tula", "vigilante", "visione"
    },
    dlcddh = {
        "AKULA", "AUTARCH", "AVENGER", "AVENGER2", "BARRAGE", "CHERNOBOG", "COMET4",
        "COMET5", "DELUXO", "GT500", "HERMES", "HUSTLER", "KAMACHO", "KHANJALI", "NEON",
        "PARIAH", "RAIDEN", "REVOLTER", "RIATA", "RIOT2", "SAVESTRA", "SC1", "SENTINEL3",
        "STREITER", "STROMBERG", "THRUSTER", "VISERIS", "VOLATOL", "YOSEMITE", "Z190"
    },
    dlcsss = {
        "caracara", "cheburek", "dominator3", "ellie", "entity2", "fagaloa", "flashgt",
        "gb200", "hotring", "jester3", "michelli", "seasparrow", "Taipan", "tezeract",
        "tyrant", "issi3"
    },
    dlcaa = {
        "BLIMP3", "FREECRAWLER", "MENACER", "MULE4", "OPPRESSOR2", "PATRIOT2", "PBUS2",
        "POUNDER2", "SCRAMJET", "SPEEDO4", "STAFFORD", "STRIKEFORCE", "SWINGER", "TERBYTE"
    },
    dlcaw = {
        "BRUISER", "BRUISER2", "BRUISER3", "BRUTUS", "BRUTUS2", "BRUTUS3", "CERBERUS",
        "CERBERUS2", "CERBERUS3", "CLIQUE", "DEATHBIKE", "DEATHBIKE2", "DEATHBIKE3",
        "DEVESTE", "DEVIANT", "DOMINATOR4", "DOMINATOR5", "DOMINATOR6", "IMPALER",
        "IMPALER2", "IMPALER3", "IMPALER4", "IMPERATOR", "IMPERATOR2", "IMPERATOR3",
        "ISSI3", "ISSI4", "ISSI5", "ISSI6", "ITALIGTO", "RCBANDITO", "SCARAB", "SCARAB2",
        "SCARAB3", "SCHLAGEN", "SLAMVAN4", "SLAMVAN5", "SLAMVAN6", "TOROS", "TULIP",
        "VAMOS", "ZR380", "ZR3802", "ZR3803", "MONSTER3", "MONSTER4", "MONSTER5"
    },
    dlccasino = {
        "CARACARA2", "DRAFTER", "DYNASTY", "EMERUS", "GAUNTLET3", "GAUNTLET4", "HELLION",
        "ISSI7", "JUGULAR", "KRIEGER", "LOCUST", "NEBULA", "NEO", "NOVAK", "PARAGON",
        "PARAGON2", "PEYOTE2", "RROCKET", "S80", "THRAX", "ZION3", "ZORRUSSO"
    },
    dlcchopshop = { "aleutian", "asterope2", "baller8", "benson2", "boattrailer2", "boattrailer3", "boxville6", "cavalcade3", "dominator9", "dorado", "drifteuros", "driftfr36", "driftfuto", "driftjester", "driftremus", "drifttampa", "driftyosemite", "driftzr350", "fr36", "freight2", "impaler5", "impaler6", "Phantom4", "polgauntlet", "police5", "terminus", "towtruck3", "towtruck4", "trailers5", "turismo3", "tvtrailer2", "vigero3", "vivanite" },
    dlcsam = { "avenger3", "avenger4", "brigham", "buffalo5", "clique2", "conada2", "coureur", "gauntlet6", "inductor", "inductor2", "l35", "monstrociti", "raiju", "ratel", "speedo5", "stingertt", "streamer216" },
    dlcdw = { "boor", "brickade2", "broadway", "cargoplane2", "entity3", "eudora", "everon2", "issi8", "journey2", "manchez3", "panthere", "powersurge", "r300", "surfer3", "tahoma", "tulip2", "virtue" },
    dlcce = { "brioso3", "conada", "corsita", "draugur", "greenwood", "kanjosj", "lm87", "omnisegt", "postlude", "rhinehart", "ruiner4", "sentinel4", "sm722", "tenf", "tenf2", "torero2", "vigero2", "weevil2" },
    dlccontract = { "astron", "baller7", "buffalo4", "champion", "cinquemila", "comet7", "deity", "granger2", "ignus", "iwagen", "jubilee", "mule5", "patriot3", "reever", "shinobi", "youga4", "zeno" },
    dlcstuners = { "calico", "comet6", "cypher", "dominator7", "dominator8", "Euros", "freightcar2", "futo2", "growler", "jester4", "previon", "remus", "rt3000", "sultan3", "tailgater2", "vectre", "warrener2", "zr350" },
    dlccph = { "alkonost", "annihilator2", "avisa", "brioso2", "dinghy5", "italirsx", "kosatka", "longfin", "manchez2", "patrolboat", "seasparrow2", "seasparrow3", "slamtruck", "squaddie", "toreador", "verus", "vetir", "veto", "veto2", "weevil", "winky" },
    dlcsss2 = { "club", "coquette4", "dukes3", "gauntlet5", "glendale2", "landstalker2", "manana2", "openwheel1", "openwheel2", "penumbra2", "peyote3", "seminole2", "tigon", "yosemite3", "youga3" },
    dlcdch = { "asbo", "everon", "formula", "formula2", "furia", "imorgon", "jb7002", "kanjo", "komoda", "minitank", "outlaw", "rebla", "retinue2", "Stryder", "Sugoi", "sultan2", "vagrant", "vstr", "yosemite2", "zhaba" }
}

return Vehicles
