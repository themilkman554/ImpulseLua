--[[
    Impulse Lua - Vehicle Info Component
    Displays vehicle information for a selected model
    Port of vehicleComponent.h from Impulse C++
]]

local UIComponent = require("Impulse/ImpulseLua/lib/ui/component")
local Renderer = require("Impulse/ImpulseLua/lib/renderer")

local VehicleImages = {
    [0x4C80EB0E] = { dict = "candc_default", name = "airbus" },
    [0xCEEA3F4B] = { dict = "candc_default", name = "barracks" },
    [0x1A79847A] = { dict = "candc_default", name = "boxville4" },
    [0xD577C962] = { dict = "candc_default", name = "bus" },
    [0x2F03547B] = { dict = "candc_default", name = "buzzard" },
    [0xFCFCB68B] = { dict = "candc_default", name = "cargobob" },
    [0x84718D34] = { dict = "candc_default", name = "coach" },
    [0x132D5A1A] = { dict = "candc_default", name = "crusader" },
    [0xB6410173] = { dict = "candc_default", name = "dubsta3" },
    [0xEC8F7094] = { dict = "candc_default", name = "dukes" },
    [0x810369E2] = { dict = "candc_default", name = "dump" },
    [0x39D6E83F] = { dict = "candc_default", name = "hydra" },
    [0x9114EADA] = { dict = "candc_default", name = "insurgent" },
    [0x7B7E56F0] = { dict = "candc_default", name = "insurgent2" },
    [0xF8D48E7A] = { dict = "candc_default", name = "journey" },
    [0x49863E9C] = { dict = "candc_default", name = "marshall" },
    [0x36848602] = { dict = "candc_default", name = "mesa" },
    [0x84F42E51] = { dict = "candc_default", name = "mesa3" },
    [0xCD93A7DB] = { dict = "candc_default", name = "monster" },
    [0x35ED670B] = { dict = "candc_default", name = "mule" },
    [0x85A5B471] = { dict = "candc_default", name = "mule3" },
    [0x885F3671] = { dict = "candc_default", name = "pbus" },
    [0xBE819C63] = { dict = "candc_default", name = "rentbus" },
    [0x2EA68690] = { dict = "candc_default", name = "rhino" },
    [0xFB133A17] = { dict = "candc_default", name = "savage" },
    [0x83051506] = { dict = "candc_default", name = "technical" },
    [0xA09E15FD] = { dict = "candc_default", name = "valkyrie" },
    [0x1E5E54EA] = { dict = "dock_default", name = "dinghy3" },
    [0x33581161] = { dict = "dock_default", name = "jetmax" },
    [0xC1CE1183] = { dict = "dock_default", name = "marquis" },
    [0xC2974024] = { dict = "dock_default", name = "seashark" },
    [0x0DC60D2B] = { dict = "dock_default", name = "speeder" },
    [0x17DF5EC2] = { dict = "dock_default", name = "squalo" },
    [0xC07107EE] = { dict = "dock_default", name = "sub2" },
    [0xEF2295C9] = { dict = "dock_default", name = "suntrap" },
    [0x1149422F] = { dict = "dock_default", name = "tropic" },
    [0x31F0B376] = { dict = "elt_default", name = "annihl" },
    [0xD9927FE3] = { dict = "elt_default", name = "cuban800" },
    [0xCA495705] = { dict = "elt_default", name = "dodo" },
    [0x39D6779E] = { dict = "elt_default", name = "duster" },
    [0x2C634FBD] = { dict = "elt_default", name = "frogger" },
    [0x250B0C5E] = { dict = "elt_default", name = "luxor" },
    [0x97E55D11] = { dict = "elt_default", name = "mammatus" },
    [0x9D0450CA] = { dict = "elt_default", name = "maverick" },
    [0xB79C1BF5] = { dict = "elt_default", name = "shamal" },
    [0x81794C70] = { dict = "elt_default", name = "stunt" },
    [0x761E2AD3] = { dict = "elt_default", name = "titan" },
    [0x9C429B6A] = { dict = "elt_default", name = "velum" },
    [0x403820E8] = { dict = "elt_default", name = "velum2" },
    [0x4FF77E37] = { dict = "elt_dlc_business", name = "vestra" },
    [0xB79F589E] = { dict = "elt_dlc_luxe", name = "luxor2" },
    [0x4019CB4C] = { dict = "elt_dlc_luxe", name = "swift2" },
    [0x6CBD1D6D] = { dict = "elt_dlc_pilot", name = "besra" },
    [0x09D80F93] = { dict = "elt_dlc_pilot", name = "miljet" },
    [0xEBC24DF2] = { dict = "elt_dlc_pilot", name = "swift" },
    [0xB779A091] = { dict = "lgm_default", name = "adder" },
    [0xC1E908D2] = { dict = "lgm_default", name = "banshee" },
    [0x9AE6DDA1] = { dict = "lgm_default", name = "bullet" },
    [0x7B8AB45F] = { dict = "lgm_default", name = "carboniz" },
    [0x00ABB0C0] = { dict = "lgm_default", name = "carbon" },
    [0xB1D95DA0] = { dict = "lgm_default", name = "cheetah" },
    [0x13B57D8A] = { dict = "lgm_default", name = "cogcabri" },
    [0xC1AE4D16] = { dict = "lgm_default", name = "comet2" },
    [0x067BC037] = { dict = "lgm_default", name = "coquette" },
    [0xDE3D9D22] = { dict = "lgm_default", name = "elegy2" },
    [0xB2FE5CF9] = { dict = "lgm_default", name = "entityxf" },
    [0xFFB15B5E] = { dict = "lgm_default", name = "exemplar" },
    [0x8911B9F5] = { dict = "lgm_default", name = "feltzer" },
    [0x0239E390] = { dict = "lgm_default", name = "hotknife" },
    [0x3EAB5555] = { dict = "lgm_default", name = "jb700" },
    [0x206D1B68] = { dict = "lgm_default", name = "khamel" },
    [0xE62B361B] = { dict = "lgm_default", name = "monroe" },
    [0xDA288376] = { dict = "sssa_dlc_heist", name = "nemesis" },
    [0x3D8FA25C] = { dict = "lgm_default", name = "ninef" },
    [0xA8E38B01] = { dict = "lgm_default", name = "ninef2" },
    [0x8CB29A14] = { dict = "lgm_default", name = "rapidgt" },
    [0x679450AF] = { dict = "lgm_default", name = "rapidgt2" },
    [0x5C23AF9B] = { dict = "lgm_default", name = "stinger" },
    [0x82E499FA] = { dict = "lgm_default", name = "stingerg" },
    [0x9F4B77BE] = { dict = "lgm_default", name = "voltic_tless" },
    [0x2D3BD401] = { dict = "lgm_default", name = "ztype" },
    [0x2DB8D1AA] = { dict = "lgm_dlc_business", name = "alpha" },
    [0xB2A716A3] = { dict = "lgm_dlc_business", name = "jester" },
    [0x185484E1] = { dict = "lgm_dlc_business", name = "turismor" },
    [0x3C4E2113] = { dict = "lgm_dlc_pilot", name = "coquette2" },
    [0x1D06D681] = { dict = "lgm_dlc_business2", name = "huntley" },
    [0xF77ADE32] = { dict = "lgm_dlc_business2", name = "massacro" },
    [0x6D6F8F43] = { dict = "lgm_dlc_business2", name = "thrust" },
    [0xAC5DF515] = { dict = "lgm_dlc_business2", name = "zentorno" },
    [0xBF1691E0] = { dict = "lgm_dlc_lts_creator", name = "furore" },
    [0xA29D6D10] = { dict = "lgm_dlc_luxe", name = "feltzer3" },
    [0x767164D6] = { dict = "lgm_dlc_luxe", name = "osiris" },
    [0xE2504942] = { dict = "lgm_dlc_luxe", name = "virgo" },
    [0x5E4327C8] = { dict = "lgm_dlc_luxe", name = "windsor" },
    [0xA7CE1BC5] = { dict = "lgm_dlc_luxe", name = "brawler" },
    [0xAF599F01] = { dict = "lgm_dlc_luxe", name = "vindicator" },
    [0x14D69010] = { dict = "lgm_dlc_luxe", name = "chino" },
    [0x2EC385FE] = { dict = "lgm_dlc_luxe", name = "coquette3" },
    [0x6322B39A] = { dict = "lgm_dlc_luxe", name = "t20" },
    [0x3FD5AA2F] = { dict = "dock_default", name = "toro" },
    [0x43779C54] = { dict = "pandm_default", name = "bmx" },
    [0x1ABA13B5] = { dict = "pandm_default", name = "cruiser" },
    [0xF4E1AA15] = { dict = "pandm_default", name = "scorcher" },
    [0x4339CD69] = { dict = "pandm_default", name = "tribike" },
    [0xB67597EC] = { dict = "pandm_default", name = "tribike2" },
    [0xE823FB48] = { dict = "pandm_default", name = "tribike3" },
    [0x63ABADE7] = { dict = "sssa_default", name = "akuma" },
    [0xCFCA3668] = { dict = "sssa_default", name = "baller2" },
    [0xF9300CC5] = { dict = "sssa_default", name = "bati" },
    [0xCADD5D2D] = { dict = "sssa_default", name = "bati2" },
    [0x432AA566] = { dict = "sssa_default", name = "bfinject" },
    [0xEB298297] = { dict = "sssa_default", name = "bifta" },
    [0xFEFD644F] = { dict = "sssa_default", name = "bison" },
    [0x8125BCF9] = { dict = "sssa_default", name = "blazer" },
    [0xAA699BB6] = { dict = "sssa_default", name = "bodhi2" },
    [0x779F23AA] = { dict = "sssa_default", name = "cavcade" },
    [0xBC993509] = { dict = "sssa_default", name = "dilettan" },
    [0x9C669788] = { dict = "sssa_default", name = "double" },
    [0x9CF21E0F] = { dict = "sssa_default", name = "dune" },
    [0x0350D1AB] = { dict = "sssa_default", name = "faggio" },
    [0xE8A8BDA8] = { dict = "sssa_default", name = "felon" },
    [0xFAAD85EE] = { dict = "sssa_default", name = "felon2" },
    [0x71CB2FFB] = { dict = "sssa_default", name = "fugitive" },
    [0x94B395C5] = { dict = "sssa_default", name = "gauntlet" },
    [0x11F76C14] = { dict = "sssa_default", name = "hexer" },
    [0x18F25AC7] = { dict = "sssa_default", name = "infernus" },
    [0xB9CB3B69] = { dict = "sssa_default", name = "issi2" },
    [0x05852838] = { dict = "sssa_default", name = "kalahari" },
    [0x506434F6] = { dict = "sssa_default", name = "oracle" },
    [0x58B3979C] = { dict = "sssa_default", name = "paradise" },
    [0xC9CEAF06] = { dict = "sssa_default", name = "pcj" },
    [0xB802DD46] = { dict = "sssa_default", name = "rebel" },
    [0x7F5C91F1] = { dict = "sssa_default", name = "rocoto" },
    [0xCABD11E8] = { dict = "sssa_default", name = "ruffian" },
    [0xDC434E51] = { dict = "sssa_default", name = "sadler" },
    [0x2EF89E46] = { dict = "sssa_default", name = "sanchez" },
    [0xA960B13E] = { dict = "sssa_default", name = "sanchez2" },
    [0xB9210FD0] = { dict = "sssa_default", name = "sandking" },
    [0x3AF8C345] = { dict = "sssa_default", name = "sandkin2" },
    [0xD37B7976] = { dict = "sssa_default", name = "schwarze" },
    [0x8B13F083] = { dict = "sssa_default", name = "stretch" },
    [0x42F2ED16] = { dict = "lgm_default", name = "superd" },
    [0x16E478C1] = { dict = "lgm_default", name = "surano_convertable" },
    [0x142E0DC3] = { dict = "lgm_default", name = "vacca" },
    [0xF79A00F7] = { dict = "sssa_default", name = "vader" },
    [0xCEC6B9B7] = { dict = "sssa_default", name = "vigero" },
    [0xBD1B39C3] = { dict = "sssa_default", name = "zion" },
    [0xB8E2AE18] = { dict = "sssa_default", name = "zion2" },
    [0x94204D89] = { dict = "sssa_dlc_business", name = "asea" },
    [0x8E9254FB] = { dict = "sssa_dlc_business", name = "astrope" },
    [0x3FC5D440] = { dict = "sssa_dlc_business", name = "bobcatxl" },
    [0xD0EB2BE5] = { dict = "sssa_dlc_business", name = "cavcade2" },
    [0xB3206692] = { dict = "sssa_dlc_business", name = "ingot" },
    [0x34DD8AA1] = { dict = "sssa_dlc_business", name = "intruder" },
    [0xED7EADA4] = { dict = "sssa_dlc_business", name = "minivan" },
    [0x8FB66F9B] = { dict = "sssa_dlc_business", name = "premier" },
    [0x9D96B45B] = { dict = "sssa_dlc_business", name = "radi" },
    [0x6210CBB0] = { dict = "sssa_dlc_business", name = "rancherx" },
    [0xA7EDE74D] = { dict = "sssa_dlc_business", name = "stanier" },
    [0x66B4FC45] = { dict = "sssa_dlc_business", name = "stratum" },
    [0x69F06B57] = { dict = "sssa_dlc_business", name = "washingt" },
    [0x04CE68AC] = { dict = "sssa_dlc_business2", name = "dominato" },
    [0xDCBCBE48] = { dict = "sssa_dlc_business2", name = "f620" },
    [0x1DC0BA53] = { dict = "sssa_dlc_business2", name = "fusilade" },
    [0xE9805550] = { dict = "sssa_dlc_business2", name = "penumbra" },
    [0x50732C82] = { dict = "sssa_dlc_business2", name = "sentinel" },
    [0xBE0E6126] = { dict = "sssa_dlc_christmas_2", name = "jester2" },
    [0xDA5819A3] = { dict = "sssa_dlc_christmas_2", name = "massacro2" },
    [0xDCE1D9F7] = { dict = "sssa_dlc_christmas_2", name = "rloader2" },
    [0x2B7F9DE3] = { dict = "sssa_dlc_christmas_2", name = "slamvan" },
    [0x6882FA73] = { dict = "sssa_dlc_heist", name = "enduro" },
    [0x11AA0E14] = { dict = "sssa_dlc_heist", name = "gburrito2" },
    [0xA3FC0F4D] = { dict = "sssa_dlc_heist", name = "gresley" },
    [0xDAC67112] = { dict = "sssa_dlc_heist", name = "jackal" },
    [0xAE2BFE94] = { dict = "sssa_dlc_heist", name = "kuruma" },
    [0x187D938D] = { dict = "sssa_dlc_heist", name = "kuruma2" },
    [0x4BA4E8DC] = { dict = "sssa_dlc_heist", name = "landstalker" },
    [0x4543B74D] = { dict = "sssa_dlc_heist", name = "rumpo" },
    [0xB52B5113] = { dict = "sssa_dlc_heist", name = "schafter2" },
    [0x48CECED3] = { dict = "sssa_dlc_heist", name = "seminole" },
    [0x8F0E3594] = { dict = "sssa_dlc_heist", name = "surge" },
    [0xB820ED5E] = { dict = "sssa_dlc_hipster", name = "blade" },
    [0xB44F0582] = { dict = "sssa_dlc_hipster", name = "blazer3" },
    [0xEDD516C6] = { dict = "sssa_dlc_hipster", name = "buffalo" },
    [0x2BEC3CBE] = { dict = "sssa_dlc_hipster", name = "buffalo2" },
    [0x047A6BC1] = { dict = "sssa_dlc_hipster", name = "glendale" },
    [0xE644E480] = { dict = "sssa_dlc_hipster", name = "panto" },
    [0x59E0FBF3] = { dict = "sssa_dlc_hipster", name = "picador" },
    [0x404B6381] = { dict = "sssa_dlc_hipster", name = "pigalle" },
    [0xBB6B404F] = { dict = "sssa_dlc_hipster", name = "primo" },
    [0x8612B64B] = { dict = "sssa_dlc_hipster", name = "rebel2" },
    [0xFF22D208] = { dict = "sssa_dlc_hipster", name = "regina" },
    [0x322CF98F] = { dict = "sssa_dlc_hipster", name = "rhapsody" },
    [0x29B0DA97] = { dict = "sssa_dlc_hipster", name = "surfer" },
    [0xC3DDFDCE] = { dict = "sssa_dlc_hipster", name = "tailgater" },
    [0x51D83328] = { dict = "sssa_dlc_hipster", name = "warrener" },
    [0x03E5F6B8] = { dict = "sssa_dlc_hipster", name = "youga" },
    [0x2C509634] = { dict = "sssa_dlc_independence", name = "sovereign" },
    [0x4B6C568A] = { dict = "sssa_dlc_lts_creator", name = "hakuchou" },
    [0xF683EACA] = { dict = "sssa_dlc_lts_creator", name = "innovation" },
    [0x3DEE5EDA] = { dict = "sssa_dlc_mp_to_sp", name = "blista2" },
    [0xE2C013E] = { dict = "sssa_dlc_mp_to_sp", name = "buffalo3" },
    [0xC96B73D9] = { dict = "sssa_dlc_mp_to_sp", name = "dominator2" },
    [0x14D22159] = { dict = "sssa_dlc_mp_to_sp", name = "gauntlet2" },
    [0x72A4C31E] = { dict = "sssa_dlc_mp_to_sp", name = "stallion" },
    [0xE80F67EE] = { dict = "sssa_dlc_mp_to_sp", name = "stalion2" },
    [0xD83C13CE] = { dict = "sssa_dlc_valentines", name = "rloader" },
    [0x06FF6914] = { dict = "lgm_dlc_valentines", name = "roosevelt" },
    [0x3822BDFE] = { dict = "lgm_dlc_heist", name = "casco" },
    [0x26321E67] = { dict = "lgm_dlc_heist", name = "lectro" },
    [0xC397F748] = { dict = "lsc_default", name = "buccaneer2_b" },
    [0xD756460C] = { dict = "lsc_default", name = "buccaneer2" },
    [0xAED64A63] = { dict = "lsc_default", name = "chino2_b" },
    [0x14D69010] = { dict = "lsc_default", name = "chino2" },
    [0x81A9CDDF] = { dict = "lsc_default", name = "faction2_a" },
    [0x95466BDB] = { dict = "lsc_default", name = "faction2_b" },
    [0x1F52A43F] = { dict = "lsc_default", name = "moonbeam2_a" },
    [0x710A2B9B] = { dict = "lsc_default", name = "moonbeam2_b" },
    [0xBB6B404F] = { dict = "lsc_default", name = "primo2_a" },
    [0x86618EDA] = { dict = "lsc_default", name = "primo2_b" },
    [0x1F3766E3] = { dict = "lsc_default", name = "voodoo_a" },
    [0x779B4F2D] = { dict = "lsc_default", name = "voodoo_b" },
    [0xCE6B35A4] = { dict = "sssa_dlc_halloween", name = "btype2" },
    [0x7B47A6A7] = { dict = "sssa_dlc_halloween", name = "lurcher" },
    [0x2A54C47D] = { dict = "elt_dlc_apartments", name = "svolito" },
    [0x9C5E5644] = { dict = "elt_dlc_apartments", name = "svolito2" },
    [0xF92AEC4D] = { dict = "candc_apartments", name = "limo2" },
    [0x6FF0F727] = { dict = "lgm_dlc_apartments", name = "baller3" },
    [0x25CBE2E2] = { dict = "lgm_dlc_apartments", name = "baller4" },
    [0x360A438E] = { dict = "lgm_dlc_apartments", name = "cog55" },
    [0x86FE0B60] = { dict = "lgm_dlc_apartments", name = "cognosc" },
    [0xDBF2D57A] = { dict = "lgm_dlc_apartments", name = "cognosc" },
    [0x9CFFFC56] = { dict = "lgm_dlc_apartments", name = "mamba" },
    [0x8C2BD0DC] = { dict = "lgm_dlc_apartments", name = "niteshad" },
    [0xA774B5A6] = { dict = "lgm_dlc_apartments", name = "schafter3" },
    [0x58CF185C] = { dict = "lgm_dlc_apartments", name = "schafter4" },
    [0x41B77FA4] = { dict = "lgm_dlc_apartments", name = "verlier" },
    [0x39F9C898] = { dict = "sssa_dlc_christmas_3", name = "tampa" },
    [0x25C5AF13] = { dict = "lsc_jan2016", name = "banshee2" },
    [0xEE6024BC] = { dict = "lsc_jan2016", name = "sultan2" },
    [0xDC19D101] = { dict = "lgm_dlc_valentines2", name = "roosevelt2" },
    [0x866BCE26] = { dict = "lsc_lowrider2", name = "faction3_b" },
    [0xBCDE91F0] = { dict = "lsc_lowrider2", name = "minivan2_b" },
    [0x9B909C94] = { dict = "lsc_lowrider2", name = "sabregt2_a" },
    [0x0D4EA603] = { dict = "lsc_lowrider2", name = "sabregt2_b" },
    [0x42BC5E19] = { dict = "lsc_lowrider2", name = "slamvan3_b" },
    [0x1BB290BC] = { dict = "lsc_lowrider2", name = "tornado5_a" },
    [0x94DA98EF] = { dict = "lsc_lowrider2", name = "tornado5_b" },
    [0xCA62927A] = { dict = "lsc_lowrider2", name = "virgo2_b" },
    [0x4BFCF28B] = { dict = "lgm_dlc_executive1", name = "bestiagts" },
    [0x5502626C] = { dict = "lgm_dlc_executive1", name = "fmj" },
    [0x92EF6E04] = { dict = "lgm_dlc_executive1", name = "pfister811" },
    [0x7E8F677F] = { dict = "lgm_dlc_executive1", name = "prototipo" },
    [0x0DF381E5] = { dict = "lgm_dlc_executive1", name = "reaper" },
    [0x97398A4B] = { dict = "lgm_dlc_executive1", name = "seven70" },
    [0x8CF5CAE1] = { dict = "lgm_dlc_executive1", name = "windsor2" },
    [0x47BBCF2E] = { dict = "lgm_dlc_executive1", name = "xls" },
    [0xE6401328] = { dict = "lgm_dlc_executive1", name = "xls" },
    [0x57F682AF] = { dict = "sssa_dlc_executive_1", name = "rumpo3" },
    [0xEDC6F847] = { dict = "candc_executive1", name = "brickade" },
    [0x60A7EA10] = { dict = "candc_executive1", name = "cargobob2" },
    [0xB2CF7250] = { dict = "elt_dlc_executive1", name = "nimbus" },
    [0x920016F1] = { dict = "elt_dlc_executive1", name = "volatus" },
    [0x82CAC433] = { dict = "dock_dlc_executive1", name = "tug" },
    [0xB6846A55] = { dict = "lgm_dlc_stunt", name = "le7b" },
    [0x1CBDC10B] = { dict = "lgm_dlc_stunt", name = "lynx" },
    [0x30D3F6D8] = { dict = "lgm_dlc_stunt", name = "sheava" },
    [0x7B406EFB] = { dict = "lgm_dlc_stunt", name = "tyrus" },
    [0x05283265] = { dict = "sssa_dlc_stunt", name = "bf400" },
    [0x5C55CB39] = { dict = "sssa_dlc_stunt", name = "brioso" },
    [0x17420102] = { dict = "sssa_dlc_stunt", name = "cliffhanger" },
    [0x28B67ACA] = { dict = "sssa_dlc_stunt", name = "contender" },
    [0x2C2C2324] = { dict = "sssa_dlc_stunt", name = "gargoyle" },
    [0xD1AD4937] = { dict = "sssa_dlc_stunt", name = "omnis" },
    [0x829A3C44] = { dict = "sssa_dlc_stunt", name = "rallytruck" },
    [0xC0240885] = { dict = "sssa_dlc_stunt", name = "tampa2" },
    [0x5728D321] = { dict = "sssa_dlc_stunt", name = "trophy" },
    [0x3335A165] = { dict = "sssa_dlc_stunt", name = "trophy2" },
    [0x707E63A4] = { dict = "sssa_dlc_stunt", name = "tropos" },
    [0xF0C2A91F] = { dict = "lgm_dlc_biker", name = "hakuchou2" },
    [0xD7C56D39] = { dict = "lgm_dlc_biker", name = "raptor" },
    [0xE7D2A16E] = { dict = "lgm_dlc_biker", name = "shotaro" },
    [0x81E38F7F] = { dict = "sssa_dlc_biker", name = "avarus" },
    [0x806B9CC3] = { dict = "sssa_dlc_biker", name = "bagger" },
    [0xE5BA6858] = { dict = "sssa_dlc_biker", name = "blazer4" },
    [0x00675ED7] = { dict = "sssa_dlc_biker", name = "chimera" },
    [0xAC4E93C9] = { dict = "sssa_dlc_biker", name = "daemon2" },
    [0x30FF0190] = { dict = "sssa_dlc_biker", name = "defiler" },
    [0x794CB30C] = { dict = "sssa_dlc_biker", name = "esskey" },
    [0xB328B188] = { dict = "sssa_dlc_biker", name = "faggio3" },
    [0x7F384994] = { dict = "sssa_dlc_biker", name = "faggion" },
    [0xA5325278] = { dict = "sssa_dlc_biker", name = "manchez" },
    [0xA0438767] = { dict = "sssa_dlc_biker", name = "nightblade" },
    [0x6FACDF31] = { dict = "sssa_dlc_biker", name = "ratbike" },
    [0x58E316C7] = { dict = "sssa_dlc_biker", name = "sanctus" },
    [0xA31CB573] = { dict = "sssa_dlc_biker", name = "tornado6" },
    [0xDBA9DBFC] = { dict = "sssa_dlc_biker", name = "vortex" },
    [0xDB20A373] = { dict = "sssa_dlc_biker", name = "wolfsbane" },
    [0x3D29CD2B] = { dict = "sssa_dlc_biker", name = "youga2" },
    [0xC3D7C72B] = { dict = "sssa_dlc_biker", name = "zombiea" },
    [0xDE05FB87] = { dict = "sssa_dlc_biker", name = "zombieb" },
    [0xA1355F67] = { dict = "candc_importexport", name = "blazer5" },
    [0x28AD20E1] = { dict = "candc_importexport", name = "boxville5" },
    [0xED62BFA9] = { dict = "candc_importexport", name = "dune5" },
    [0x9DAE1398] = { dict = "candc_importexport", name = "phantom2" },
    [0x381E10BD] = { dict = "candc_importexport", name = "ruiner2" },
    [0x4662BCBB] = { dict = "candc_importexport", name = "technical2" },
    [0x3AF76F4A] = { dict = "candc_importexport", name = "voltic2" },
    [0x8E08EC82] = { dict = "candc_importexport", name = "wastlndr" },
    [0x9734F3EA] = { dict = "lgm_dlc_importexport", name = "penetrator" },
    [0x1044926F] = { dict = "lgm_dlc_importexport", name = "tempesta" },
    [0x877358AD] = { dict = "lsc_dlc_import_export", name = "comet3_b" },
    [0xF1B44F44] = { dict = "lsc_dlc_import_export", name = "diablous2_a" },
    [0x6ABDF65E] = { dict = "lsc_dlc_import_export", name = "diablous2_b" },
    [0x0BBA2261] = { dict = "lsc_dlc_import_export", name = "elegy_b" },
    [0x25676EAF] = { dict = "lsc_dlc_import_export", name = "fcr2_a" },
    [0xD2D5E00E] = { dict = "lsc_dlc_import_export", name = "fcr2_b" },
    [0x85E8E76B] = { dict = "lsc_dlc_import_export", name = "italigtb2_a" },
    [0xE33A477B] = { dict = "lsc_dlc_import_export", name = "italigtb2_b" },
    [0x3DA47243] = { dict = "lsc_dlc_import_export", name = "nero2_a" },
    [0x4131F378] = { dict = "lsc_dlc_import_export", name = "nero2_b" },
    [0x706E2B40] = { dict = "lsc_dlc_import_export", name = "specter2_a" },
    [0x400F5147] = { dict = "lsc_dlc_import_export", name = "specter2_b" },
    [0x4992196C] = { dict = "lgm_dlc_specialraces", name = "gp1" },
    [0xAC33179C] = { dict = "lgm_dlc_specialraces", name = "infernus2" },
    [0x2AE524A8] = { dict = "lgm_dlc_specialraces", name = "ruston" },
    [0xC575DF11] = { dict = "lgm_dlc_specialraces", name = "turismo2" },
    [0x2189D250] = { dict = "candc_gunrunning", name = "apc" },
    [0x097E5533] = { dict = "candc_gunrunning", name = "ardent" },
    [0xD227BDBB] = { dict = "foreclosures_bunker", name = "transportation_1" },
    [0x0D4E5F4D] = { dict = "lgm_dlc_gunrunning", name = "cheetah2" },
    [0x711D4738] = { dict = "candc_gunrunning", name = "dune3" },
    [0xFE141DA6] = { dict = "candc_gunrunning", name = "halftrack" },
    [0x171C92C4] = { dict = "candc_truck", name = "cab_1" },
    [0x19DD9ED1] = { dict = "candc_gunrunning", name = "nightshark" },
    [0x34B82784] = { dict = "candc_gunrunning", name = "oppressor" },
    [0xB7D9F7F1] = { dict = "candc_gunrunning", name = "tampa3" },
    [0x59A9E570] = { dict = "lgm_dlc_gunrunning", name = "torero" },
    [0x8FD54EBB] = { dict = "candc_gunrunning", name = "trsmall2" },
    [0x7397224C] = { dict = "lgm_dlc_gunrunning", name = "vagner" },
    [0x36B4A8A9] = { dict = "lgm_dlc_gunrunning", name = "xa21" },
    [0xFE0A508C] = { dict = "candc_smuggler", name = "bombushka" },
    [0xFD707EDE] = { dict = "candc_smuggler", name = "hunter" },
    [0xD35698EF] = { dict = "candc_smuggler", name = "mogul" },
    [0x3DC92356] = { dict = "candc_smuggler", name = "nokota" },
    [0xAD6065C0] = { dict = "candc_smuggler", name = "pyro" },
    [0xC5DD6967] = { dict = "candc_smuggler", name = "rogue" },
    [0x9A9EB7DE] = { dict = "candc_smuggler", name = "starling" },
    [0x3E2E4F8A] = { dict = "candc_smuggler", name = "tula" },
    [0xB5EF4C33] = { dict = "candc_smuggler", name = "vigilante" },
    [0x8198AEDC] = { dict = "lgm_dlc_assault", name = "entity2" },
    [0xB4F32118] = { dict = "lgm_dlc_assault", name = "flashgt" },
    [0x71CBEA98] = { dict = "lgm_dlc_assault", name = "gb200" },
    [0xF330CB6A] = { dict = "lgm_dlc_assault", name = "jester3" },
    [0xBC5DC07E] = { dict = "lgm_dlc_assault", name = "taipan" },
    [0x3D7C6410] = { dict = "lgm_dlc_assault", name = "tezeract" },
    [0xE99011C2] = { dict = "lgm_dlc_assault", name = "tyrant" },
    [0x6DBD6C0A] = { dict = "sssa_dlc_smuggler", name = "retinue" },
    [0x52FF9437] = { dict = "lgm_dlc_smuggler", name = "cyclone" },
    [0x7A2EF5E4] = { dict = "lgm_dlc_smuggler", name = "rapidgt3" },
    [0xC4810400] = { dict = "lgm_dlc_smuggler", name = "visione" },
    [0xA52F6866] = { dict = "elt_dlc_smuggler", name = "alphaz1" },
    [0x89BA59F5] = { dict = "elt_dlc_smuggler", name = "havok" },
    [0xC3F25753] = { dict = "elt_dlc_smuggler", name = "howard" },
    [0x96E24857] = { dict = "elt_dlc_smuggler", name = "microlight" },
    [0xE8983F9F] = { dict = "elt_dlc_smuggler", name = "seabreeze" },
    [0x5D56F01B] = { dict = "candc_smuggler", name = "molotok" },
    [0x46699F47] = { dict = "candc_xmas2017", name = "akula" },
    [0xF34DFB25] = { dict = "candc_xmas2017", name = "barrage" },
    [0x81BD2ED0] = { dict = "candc_chopper", name = "banner_4" },
    [0x18606535] = { dict = "candc_chopper", name = "banner_0" },
    [0xD6BC7523] = { dict = "candc_xmas2017", name = "chernobog" },
    [0x586765FB] = { dict = "candc_xmas2017", name = "deluxo" },
    [0xAA6F980A] = { dict = "candc_xmas2017", name = "khanjali" },
    [0x9B16A3B4] = { dict = "candc_xmas2017", name = "riot2" },
    [0x34DBA661] = { dict = "candc_xmas2017", name = "stromberg" },
    [0x58CDAF30] = { dict = "candc_xmas2017", name = "thruster" },
    [0x1AAD0DED] = { dict = "candc_xmas2017", name = "volatol" },
    [0xED552C74] = { dict = "lgm_dlc_xmas2017", name = "autarch" },
    [0x5D1903F9] = { dict = "lgm_dlc_xmas2017", name = "comet4" },
    [0x276D98A3] = { dict = "lgm_dlc_xmas2017", name = "comet5" },
    [0x8408F33A] = { dict = "lgm_dlc_xmas2017", name = "gt500" },
    [0x23CA25F2] = { dict = "lgm_dlc_xmas2017", name = "hustler" },
    [0x91CA96EE] = { dict = "lgm_dlc_xmas2017", name = "neon" },
    [0x33B98FE2] = { dict = "lgm_dlc_xmas2017", name = "pariah" },
    [0xA4D99B7D] = { dict = "lgm_dlc_xmas2017", name = "raiden" },
    [0xE78CC3D9] = { dict = "lgm_dlc_xmas2017", name = "revolter" },
    [0x35DED0DD] = { dict = "lgm_dlc_xmas2017", name = "savestra" },
    [0x5097F589] = { dict = "lgm_dlc_xmas2017", name = "sc1" },
    [0x67D2B389] = { dict = "lgm_dlc_xmas2017", name = "streiter" },
    [0xE8A8BA94] = { dict = "lgm_dlc_xmas2017", name = "viseris" },
    [0x3201DD49] = { dict = "lgm_dlc_xmas2017", name = "z190" },
    [0x00E83C17] = { dict = "sssa_dlc_xmas2017", name = "hermes" },
    [0xF8C2E0E7] = { dict = "sssa_dlc_xmas2017", name = "kamacho" },
    [0xA4A4E453] = { dict = "sssa_dlc_xmas2017", name = "riata" },
    [0x41D149AA] = { dict = "sssa_dlc_xmas2017", name = "sentinel3" },
    [0x67D2B389] = { dict = "sssa_dlc_xmas2017", name = "streiter" },
    [0x6F946279] = { dict = "sssa_dlc_xmas2017", name = "yosemite" },
    [0x4ABEBF23] = { dict = "candc_assault", name = "caracara" },
    [0xD4AE63D9] = { dict = "elt_dlc_assault", name = "sparrow" },
    [0xC514AAE0] = { dict = "sssa_dlc_assault", name = "cheburek" },
    [0xC52C6B93] = { dict = "sssa_dlc_assault", name = "dominator3" },
    [0xB472D2B5] = { dict = "sssa_dlc_assault", name = "ellie" },
    [0x6068AD86] = { dict = "sssa_dlc_assault", name = "fagaloa" },
    [0x378236E1] = { dict = "sssa_dlc_assault", name = "issi3" },
    [0x3E5BD8D9] = { dict = "sssa_dlc_assault", name = "michelli" },
    [0x42836BE5] = { dict = "sssa_dlc_assault", name = "hotring" },
    [0x2b26f456] = { dict = "sssa_dlc_mp_to_sp", name = "dukes" },
    [0xdcbc1c3b] = { dict = "sssa_dlc_mp_to_sp", name = "blista2" },
    [0x14d69010] = { dict = "lsc_default", name = "chino2_a" },
    [0x50D4D19F] = { dict = "candc_default", name = "insurgent" },
    [0xA90ED5C] = { dict = "candc_truck", name = "cab_0" },
    [0x8D4B7A8A] = { dict = "candc_default", name = "technical" },
    [0x612f4b6] = { dict = "sssa_dlc_stunt", name = "trophy" },
    [0xd876dbe2] = { dict = "sssa_dlc_stunt", name = "trophy2" },
    [0x33b47f96] = { dict = "dock_default", name = "dinghy3" },
    [0xed762d49] = { dict = "dock_default", name = "seashark" },
    [0x1a144f2a] = { dict = "dock_default", name = "speeder" },
    [0x362cac6d] = { dict = "dock_default", name = "toro" },
    [0x5bfa5c4b] = { dict = "candc_default", name = "valkyrie" },
    [0x78bc1a3c] = { dict = "candc_default", name = "cargobob" },
    [0x2592b5cf] = { dict = "candc_default", name = "barracks" },
    [0x31adbbfc] = { dict = "sssa_dlc_christmas_2", name = "slamvan" },
    [0x825a9f4c] = { dict = "sssa_dlc_heist", name = "guardian" },
    [0xEDA4ED97] = { dict = "elt_dlc_battle", name = "blimp3" },
    [0xFCC2F483] = { dict = "lgm_dlc_battle", name = "freecrawler" },
    [0x79DD18AE] = { dict = "candc_battle", name = "menacer" },
    [0x73F4110E] = { dict = "candc_battle", name = "mule4" },
    [0x7B54A9D3] = { dict = "candc_battle", name = "oppressor2" },
    [0xE6E967F8] = { dict = "sssa_dlc_battle", name = "patriot2" },
    [0x149BD32A] = { dict = "sssa_dlc_battle", name = "pbus2" },
    [0x6290F15B] = { dict = "candc_battle", name = "pounder2" },
    [0xD9F0503D] = { dict = "candc_battle", name = "scramjet" },
    [0x1324E960] = { dict = "lgm_dlc_battle", name = "stafford" },
    [0x64DE07A1] = { dict = "candc_battle", name = "strikeforce" },
    [0x1DD4C0FF] = { dict = "lgm_dlc_battle", name = "swinger" },
    [0x897AFC65] = { dict = "candc_hacker", name = "banner0" },
    [0x0] = { dict = "sssa_dlc_arena", name = "blista3" },
    [0xEEF345EC] = { dict = "sssa_dlc_arena", name = "rcbandito" },
    [0x56D42971] = { dict = "sssa_dlc_arena", name = "tulip" },
    [0xA29F78B0] = { dict = "lgm_dlc_arena", name = "clique" },
    [0x5EE005DA] = { dict = "lgm_dlc_arena", name = "deveste" },
    [0x4C3FFF49] = { dict = "lgm_dlc_arena", name = "deviant" },
    [0xEC3E3404] = { dict = "lgm_dlc_arena", name = "italigto" },
    [0xE1C03AB0] = { dict = "lgm_dlc_arena", name = "schlagen" },
    [0xBA5334AC] = { dict = "lgm_dlc_arena", name = "toros" },
    [0x27D79225] = { dict = "mba_vehicles", name = "bruiser_c_1" },
    [0x9B065C9E] = { dict = "mba_vehicles", name = "bruiser_c_2" },
    [0x8644331A] = { dict = "mba_vehicles", name = "bruiser_c_3" },
    [0x7F81A829] = { dict = "mba_vehicles", name = "brutus1" },
    [0x8F49AE28] = { dict = "mba_vehicles", name = "brutus2" },
    [0x798682A2] = { dict = "mba_vehicles", name = "brutus3" },
    [0xD039510B] = { dict = "mba_vehicles", name = "cerberus1" },
    [0x287FA449] = { dict = "mba_vehicles", name = "cerberus2" },
    [0x71D3B6F0] = { dict = "mba_vehicles", name = "cerberus3" },
    [0xFE5F0722] = { dict = "mba_vehicles", name = "deathbike_c_1" },
    [0x93F09558] = { dict = "mba_vehicles", name = "deathbike_c_2" },
    [0xAE12C99C] = { dict = "mba_vehicles", name = "deathbike_c_3" },
    [0xD6FB0F30] = { dict = "mba_vehicles", name = "dominato_c_1" },
    [0xAE0A3D4F] = { dict = "mba_vehicles", name = "dominato_c_2" },
    [0xB2E046FB] = { dict = "mba_vehicles", name = "dominato_c_3" },
    [0x0] = { dict = "mba_vehicles", name = "gargoyle" },
    [0x83070B62] = { dict = "mba_vehicles", name = "impaler_b" },
    [0x3C26BD0C] = { dict = "mba_vehicles", name = "impaler_c_1" },
    [0x8D45DF49] = { dict = "mba_vehicles", name = "impaler_c_2" },
    [0x9804F4C7] = { dict = "mba_vehicles", name = "impaler_c_3" },
    [0x1A861243] = { dict = "mba_vehicles", name = "imperator1" },
    [0x619C1B82] = { dict = "mba_vehicles", name = "imperator2" },
    [0xD2F77E37] = { dict = "mba_vehicles", name = "imperator3" },
    [0x730CE01F] = { dict = "mba_vehicles", name = "issi3_b" },
    [0x256E92BA] = { dict = "mba_vehicles", name = "issi3_c_1" },
    [0x5BA0FF1E] = { dict = "mba_vehicles", name = "issi3_c_2" },
    [0x49E25BA1] = { dict = "mba_vehicles", name = "issi3_c_3" },
    [0x669EB40A] = { dict = "mba_vehicles", name = "monster_c_1" },
    [0x32174AFC] = { dict = "mba_vehicles", name = "monster_c_2" },
    [0xD556917C] = { dict = "mba_vehicles", name = "monster_c_3" },
    [0xBBA2A2F7] = { dict = "mba_vehicles", name = "scarab1" },
    [0x5BEB3CE0] = { dict = "mba_vehicles", name = "scarab2" },
    [0xDD71BFEB] = { dict = "mba_vehicles", name = "scarab3" },
    [0x8526E2F5] = { dict = "mba_vehicles", name = "slamvan_c_1" },
    [0x163F8520] = { dict = "mba_vehicles", name = "slamvan_c_2" },
    [0x67D52852] = { dict = "mba_vehicles", name = "slamvan_c_3" },
    [0x20314B42] = { dict = "mba_vehicles", name = "zr3801" },
    [0xBE11EFC6] = { dict = "mba_vehicles", name = "zr3802" },
    [0xA7DCC35C] = { dict = "mba_vehicles", name = "zr3803" },
    [0xCEB28249] = { dict = "candc_importexport", name = "dune5" },
    [0x1C09CF5E] = { dict = "lgm_dlc_apartments", name = "baller3" },
    [0x27B4E6B0] = { dict = "lgm_dlc_apartments", name = "baller4" },
    [0x86FE0B60] = { dict = "lgm_dlc_apartments", name = "cognosc" },
    [0xCB0E7CD9] = { dict = "lgm_dlc_apartments", name = "schafter4" },
    [0x72934BE4] = { dict = "lgm_dlc_apartments", name = "schafter4" },
    [0xAF966F3C] = { dict = "sssa_dlc_vinewood", name = "CARACARA2" },
    [0x28EAB80F] = { dict = "lgm_dlc_vinewood", name = "DRAFTER" },
    [0x127E90D5] = { dict = "sssa_dlc_vinewood", name = "DYNASTY" },
    [0x4EE74355] = { dict = "lgm_dlc_vinewood", name = "EMERUS" },
    [0x2B0C4DCD] = { dict = "sssa_dlc_vinewood", name = "GAUNTLET3" },
    [0x734C5E50] = { dict = "sssa_dlc_vinewood", name = "GAUNTLET4" },
    [0xEA6A047F] = { dict = "sssa_dlc_vinewood", name = "HELLION" },
    [0x6E8DA4F7] = { dict = "sssa_dlc_vinewood", name = "ISSI7" },
    [0xF38C4245] = { dict = "lgm_dlc_vinewood", name = "JUGULAR" },
    [0xD86A0247] = { dict = "lgm_dlc_vinewood", name = "KRIEGER" },
    [0xC7E55211] = { dict = "lgm_dlc_vinewood", name = "LOCUST" },
    [0xCB642637] = { dict = "sssa_dlc_vinewood", name = "NEBULA" },
    [0x9F6ED5A2] = { dict = "lgm_dlc_vinewood", name = "NEO" },
    [0x92F5024E] = { dict = "lgm_dlc_vinewood", name = "NOVAK" },
    [0xE550775B] = { dict = "lgm_dlc_vinewood", name = "PARAGON" },
    [0x546D8EEE] = { dict = "lgm_dlc_vinewood", name = "PARAGON" },
    [0x9472CD24] = { dict = "sssa_dlc_vinewood", name = "PEYOTE2" },
    [0x36A167E0] = { dict = "lgm_dlc_vinewood", name = "RROCKET" },
    [0xECA6B6A3] = { dict = "lgm_dlc_vinewood", name = "S80" },
    [0x3E3D1F59] = { dict = "lgm_dlc_vinewood", name = "THRAX" },
    [0x6F039A67] = { dict = "sssa_dlc_vinewood", name = "ZION3" },
    [0xD757D97D] = { dict = "lgm_dlc_vinewood", name = "ZORRUSSO" },
}

---@class UIVehicleComponent : UIComponent
local UIVehicleComponent = setmetatable({}, { __index = UIComponent })
UIVehicleComponent.__index = UIVehicleComponent

function UIVehicleComponent.new()
    local self = setmetatable(UIComponent.new(), UIVehicleComponent)
    self.model = 0
    return self
end

--- Set the vehicle model to display
---@param model number|string Model hash or name
function UIVehicleComponent:SetModel(model)
    if type(model) == "string" then
        self.model = MISC.GET_HASH_KEY(model)
    else
        self.model = model
    end
end

-- Helper: Get label text
local function GetLabelText(label)
    local text = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(label)
    if not text or text == "NULL" or text == "" then return label end
    return text
end

-- Helper: Vehicle Classes (unchanged)
local VehicleClasses = {
    [0] = "Compacts", [1] = "Sedans", [2] = "SUVs", [3] = "Coupes", [4] = "Muscle",
    [5] = "Sports Classics", [6] = "Sports", [7] = "Super", [8] = "Motorcycles",
    [9] = "Off-road", [10] = "Industrial", [11] = "Utility", [12] = "Vans",
    [13] = "Cycles", [14] = "Boats", [15] = "Helicopters", [16] = "Planes",
    [17] = "Service", [18] = "Emergency", [19] = "Military", [20] = "Commercial",
    [21] = "Trains"
}

--- Render the component
function UIVehicleComponent:Render()
    if not self.model or self.model == 0 then return end
    
    local targetX = Renderer.Layout.posX + Renderer.Layout.width / 2 + self.parent.size.w / 2 + 0.01
    
    -- Resize Window to fit 2 data rows
    self.parent.size.w = 0.190
    self.parent.size.h = 0.225 
    
    -- ... (Parent Pos Code) ...

    -- Update Parent Window Position
    if Renderer.Layout.vehicleInfoPos then
        self.parent.position.x = Renderer.Layout.vehicleInfoPos.x
        self.parent.position.y = Renderer.Layout.vehicleInfoPos.y
    else
        self.parent.position.x = targetX
        self.parent.position.y = Renderer.Layout.posY + (self.parent.size.h / 2) - 0.06
    end
    
    local model = self.model
    local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
    local label = GetLabelText(name)
    -- Force upper case for title to match screenshot "DOMINATOR"
    self.parent.name = string.upper(label)
    
    local contentX, contentY = self:GetContentPosition()
    
    -- Draw Helper (unchanged)
    local function drawInfo(xOffsetFactor, widthFactor, yOffset, name, value)
         local offset = 0.0025
         local xPos = contentX + xOffsetFactor
         local yPos = contentY + 0.022 * yOffset - 0.003
         local width = widthFactor
         local textColor = {r=255,g=255,b=255,a=255}
         local wrapMin = xPos + offset
         local wrapMax = xPos + width - offset
         Renderer.DrawString(name, xPos + offset, yPos, 4, 0.35, textColor, false, 1, wrapMin, wrapMax)
         Renderer.DrawString(value, xPos + offset, yPos, 4, 0.35, textColor, false, 2, wrapMin, wrapMax)
    end
    
    local separatorOffset = -0.015 -- Move line to left
    
    local function drawMiddleLine(yOffset)
        local yPos = contentY + 0.022 * yOffset + 0.015
        local xPos = self.parent.position.x + separatorOffset
        Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth * 2, 0.022, Renderer.Colors.Outline)
        Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth, 0.022, {r=0,g=0,b=0,a=255})
    end
    
    local function drawMiddleLineTop(yOffset)
        local yPos = contentY + 0.022 * yOffset + 0.015 - 0.022 / 2
        local xPos = self.parent.position.x + separatorOffset
        Renderer.DrawRect(xPos, yPos, Renderer.Layout.lineWidth * 2, Renderer.Layout.lineWidth * 2, Renderer.Colors.Outline)
    end
    
    -- Draw Image logic
    -- C++ Position logic: m_parent->m_position.y - (0.221f - 0.165f) / 2
    -- (0.221 - 0.165) / 2 = 0.056 / 2 = 0.028
    local imgCenterY = self.parent.position.y - 0.028
    local imgH = 0.165
    
    local imgData = VehicleImages[model]
    if imgData then
        -- Use direct DrawSprite with normalized coordinates (matching C++ logic and avoiding resolution crash)
        Renderer.DrawSprite({dict=imgData.dict, name=imgData.name}, self.parent.position.x, imgCenterY, 0.187, 0.165, 0, {r=255,g=255,b=255,a=255})
    else
        -- No Preview Image
        Renderer.DrawSprite({dict="Bookmarks", name="NoVehiclePreview"}, self.parent.position.x, imgCenterY, 0.187, 0.165, 0, {r=255,g=255,b=255,a=255})
    end
    
    -- Stats Data
    local makeName = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(model)
    local make = GetLabelText(makeName)
    if make == "NULL" or make == "" then make = "Unknown" end
    
    local maxSpeed = VEHICLE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(model) * 2.236936
    local speedStr = string.format("%.0fMPH", maxSpeed)
    
    local accel = VEHICLE.GET_VEHICLE_MODEL_ACCELERATION(model)
    local brake = VEHICLE.GET_VEHICLE_MODEL_MAX_BRAKING(model)
    local traction = VEHICLE.GET_VEHICLE_MODEL_MAX_TRACTION(model)
    
    local classId = VEHICLE.GET_VEHICLE_CLASS_FROM_NAME(model)
    local className = VehicleClasses[classId] or "Unknown"
    local classStr = string.format("%s | ID: %d", className, classId)
    
    local seats = VEHICLE.GET_VEHICLE_MODEL_NUMBER_OF_SEATS(model)
    
    -- Calculate column widths based on shift
    local fullWidth = 0.187
    local half = fullWidth / 2
    local col1Width = half + separatorOffset
    local col2Width = half - separatorOffset
    
    -- Row 6: Make | Name
    drawInfo(0, col1Width, 6, "Make", make)
    drawInfo(col1Width, col2Width - 0.005, 6, "Name", label)
    drawMiddleLineTop(6)
    drawMiddleLine(6)
    
    -- Row 7: Max Speed | Seats
    drawInfo(0, col1Width, 7, "Max Speed", speedStr)
    drawInfo(col1Width, col2Width - 0.005, 7, "Seats", tostring(seats))
    drawMiddleLine(7)
end

function UIVehicleComponent:DrawScaleform()
    if not self.model or self.model == 0 then return end
    
    local scaleform = GRAPHICS.REQUEST_SCALEFORM_MOVIE("mp_car_stats_01")
    if not GRAPHICS.HAS_SCALEFORM_MOVIE_LOADED(scaleform) then
        return
    end
    
    local model = self.model
    local name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
    local label = GetLabelText(name)
    local makeName = VEHICLE.GET_MAKE_NAME_FROM_VEHICLE_MODEL(model)
    local make = GetLabelText(makeName)
    
    GRAPHICS.BEGIN_SCALEFORM_MOVIE_METHOD(scaleform, "SET_VEHICLE_INFOR_AND_STATS")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(label)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING(make)
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("MPCarHUD")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("fathom")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("Top Speed")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("Acceleration")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("Braking")
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_PLAYER_NAME_STRING("Traction")
    
    local speed = VEHICLE.GET_VEHICLE_MODEL_ESTIMATED_MAX_SPEED(model) * 1.5
    local accel = VEHICLE.GET_VEHICLE_MODEL_ACCELERATION(model) * 2.5 * 100
    local brake = VEHICLE.GET_VEHICLE_MODEL_MAX_BRAKING(model) / 4.0 * 100
    local traction = VEHICLE.GET_VEHICLE_MODEL_MAX_TRACTION(model) / 3.0 * 100
    
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(math.floor(math.min(math.max(speed, 0), 100)))
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(math.floor(math.min(math.max(accel, 0), 100)))
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(math.floor(math.min(math.max(brake, 0), 100)))
    GRAPHICS.SCALEFORM_MOVIE_METHOD_ADD_PARAM_INT(math.floor(math.min(math.max(traction, 0), 100)))
    
    GRAPHICS.END_SCALEFORM_MOVIE_METHOD()
    
    GRAPHICS.DRAW_SCALEFORM_MOVIE(scaleform, self.parent.position.x, self.parent.position.y - 0.15, 1.0, 1.0, 255, 255, 255, 255, 0)
    
    GRAPHICS.SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(scaleform)
end

return UIVehicleComponent
