--[[
    Impulse Lua - Animation Menu
    Port of animationMenu.cpp from Impulse C++
    Animations, walkstyles, and scenarios for the player
]]

local Submenu = require("Impulse/ImpulseLua/lib/submenu")
local ToggleOption = require("Impulse/ImpulseLua/lib/options/toggle")
local ButtonOption = require("Impulse/ImpulseLua/lib/options/button")
local ScrollOption = require("Impulse/ImpulseLua/lib/options/scroll")

---@class AnimationMenu : Submenu
local AnimationMenu = setmetatable({}, { __index = Submenu })
AnimationMenu.__index = AnimationMenu

-- State table for animation options
local animState = {
    controllable = false,
    contort = false,
    animationType = 1,
    walkstyleType = 1,
    scenarioType = 1,
}

-- Animation presets: { name, dict, anim }
local animations = {
    { name = "Push-Ups", dict = "amb@world_human_push_ups@male@base", anim = "base" },
    { name = "Sit-Ups", dict = "amb@world_human_sit_ups@male@base", anim = "base" },
    { name = "Celebrate", dict = "rcmfanatic1celebrate", anim = "celebrate" },
    { name = "Electrocution", dict = "ragdoll@human", anim = "electrocute" },
    { name = "Shower", dict = "mp_safehouseshower@male@", anim = "male_shower_idle_b" },
    { name = "Suicide (pill)", dict = "mp_suicide", anim = "pill" },
    { name = "Dog pissing", dict = "creatures@rottweiler@move", anim = "pee_right_idle" },
    { name = "Dog sex", dict = "missfra0_chop_find", anim = "hump_loop_chop" },
    { name = "Celebration", dict = "mini@dartsintro", anim = "darts_outro_03_guy2" },
    { name = "Suicide (Pistol)", dict = "mp_suicide", anim = "pistol" },
    { name = "Stripper dance", dict = "mini@strip_club@private_dance@part1", anim = "priv_dance_p1" },
    { name = "Celebration 2", dict = "mini@golfclubhouse", anim = "clubhouse_leave_win_plyr" },
    { name = "Wave 1", dict = "friends@frj@ig_1", anim = "wave_a" },
    { name = "Wave 2", dict = "friends@frj@ig_1", anim = "wave_b" },
    { name = "Mountain dance", dict = "special_ped@mountain_dancer@base", anim = "base" },
    { name = "Heaven dance", dict = "special_ped@mountain_dancer@monologue_1@monologue_1a", anim = "mtn_dnc_if_you_want_to_get_to_heaven" },
    { name = "Angel dance", dict = "special_ped@mountain_dancer@monologue_2@monologue_2a", anim = "mnt_dnc_angel" },
    { name = "Buttwag dance", dict = "special_ped@mountain_dancer@monologue_3@monologue_3a", anim = "mnt_dnc_buttwag" },
    { name = "Pole dance", dict = "mini@strip_club@pole_dance@pole_dance1", anim = "pd_dance_01" },
    { name = "Pole dance 2", dict = "mini@strip_club@pole_dance@pole_dance2", anim = "pd_dance_02" },
    { name = "Pole dance 3", dict = "mini@strip_club@pole_dance@pole_dance3", anim = "pd_dance_03" },
    { name = "Skrillex dance", dict = "misschinese2_crystalmazemcs1_cs", anim = "dance_loop_tao" },
    { name = "Hood dance", dict = "missfbi3_sniping", anim = "dance_m_default" },
    { name = "Dance verse", dict = "special_ped@mountain_dancer@monologue_4@monologue_4a", anim = "mnt_dnc_verse" },
    { name = "Wave arms", dict = "random@car_thief@victimpoints_ig_3", anim = "arms_waving" },
    { name = "Wave 3", dict = "friends@frj@ig_1", anim = "wave_c" },
    { name = "Wave 4", dict = "friends@frj@ig_1", anim = "wave_d" },
    { name = "Wave 5", dict = "friends@frj@ig_1", anim = "wave_e" },
    { name = "Sex receiver", dict = "rcmpaparazzo_2", anim = "shag_loop_poppy" },
    { name = "Sex giver", dict = "rcmpaparazzo_2", anim = "shag_loop_a" },
}

-- Walkstyle presets: { name, clipset }
local walkstyles = {
    { name = "Generic Male", clipset = "move_m@generic" },
    { name = "Generic Female", clipset = "move_f@generic" },
    { name = "Drunk (Male)", clipset = "move_m@drunk@a" },
    { name = "Slightly Drunk (Male)", clipset = "move_m@drunk@slightlydrunk" },
    { name = "Moderately Drunk (Male)", clipset = "move_m@drunk@moderatedrunk" },
    { name = "Moderately Drunk (Male) 2", clipset = "move_m@drunk@moderatedrunk_head_up" },
    { name = "Very Drunk (Male)", clipset = "move_m@drunk@verydrunk" },
    { name = "Very Drunk (Female)", clipset = "move_f@drunk@verydrunk" },
    { name = "Hiking", clipset = "move_m@hiking" },
}

-- Scenario presets: { name, scenario }
local scenarios = {
    { name = "Freeway Bum", scenario = "WORLD_HUMAN_BUM_FREEWAY" },
    { name = "Grazing Boar", scenario = "WORLD_BOAR_GRAZING" },
    { name = "Yoga", scenario = "WORLD_HUMAN_YOGA" },
    { name = "Bench Press", scenario = "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS" },
    { name = "Party", scenario = "WORLD_HUMAN_PARTYING" },
    { name = "Shine Flashlight", scenario = "WORLD_HUMAN_SECURITY_SHINE_TORCH" },
    { name = "Tourist Map", scenario = "WORLD_HUMAN_TOURIST_MAP" },
    { name = "Binoculars", scenario = "WORLD_HUMAN_BINOCULARS" },
    { name = "Parking Attendant", scenario = "WORLD_HUMAN_CAR_PARK_ATTENDANT" },
    { name = "Drill", scenario = "WORLD_HUMAN_CONST_DRILL" },
    { name = "Leaf Blower", scenario = "WORLD_HUMAN_GARDENER_LEAF_BLOWER" },
    { name = "Hammering", scenario = "WORLD_HUMAN_HAMMERING" },
    { name = "Janitor", scenario = "WORLD_HUMAN_JANITOR" },
    { name = "Fishing", scenario = "WORLD_HUMAN_STAND_FISHING" },
    { name = "Sleeping Bum", scenario = "WORLD_HUMAN_BUM_SLUMPED" },
    { name = "Cheer", scenario = "WORLD_HUMAN_CHEERING" },
    { name = "Drunk", scenario = "WORLD_HUMAN_DRINKING" },
    { name = "Human Statue", scenario = "WORLD_HUMAN_HUMAN_STATUE" },
    { name = "Coffee", scenario = "WORLD_HUMAN_AA_COFFEE" },
    { name = "Smoking", scenario = "WORLD_HUMAN_AA_SMOKE" },
    { name = "Musician", scenario = "WORLD_HUMAN_MUSICIAN" },
    { name = "BBQ", scenario = "PROP_HUMAN_BBQ" },
    { name = "Maid", scenario = "WORLD_HUMAN_MAID_CLEAN" },
    { name = "Welding", scenario = "WORLD_HUMAN_WELDING" },
    { name = "Grazing Cow", scenario = "WORLD_COW_GRAZING" },
    { name = "Coyote Howl", scenario = "WORLD_COYOTE_HOWL" },
    { name = "Coyote Rest", scenario = "WORLD_COYOTE_REST" },
    { name = "Coyote Wander", scenario = "WORLD_COYOTE_WANDER" },
    { name = "Rottweiler Bark", scenario = "WORLD_DOG_BARKING_ROTTWEILER" },
    { name = "Idle Jogger", scenario = "WORLD_HUMAN_JOG_STANDING" },
    { name = "Golf", scenario = "WORLD_HUMAN_GOLF_PLAYER" },
    { name = "Muscle Flex", scenario = "WORLD_HUMAN_MUSCLE_FLEX" },
    { name = "Free Weights", scenario = "WORLD_HUMAN_MUSCLE_FREE_WEIGHTS" },
    { name = "Tennis", scenario = "WORLD_HUMAN_TENNIS_PLAYER" },
}

--[[ ============================================
    MENU CREATION
============================================ ]]

function AnimationMenu.new()
    local self = setmetatable(Submenu.new("Animations"), AnimationMenu)
    return self
end

function AnimationMenu:Init()
    -- Stop all animations
    self:AddOption(ButtonOption.new("Stop all animations")
        :AddFunction(function()
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.PLAYER_PED_ID())
        end)
        :AddTooltip("Stop all running animations")
        :AddHotkey())
    
    -- Controllable toggle
    self:AddOption(ToggleOption.new("Controllable")
        :AddToggleRef(animState, "controllable")
        :AddTooltip("Control your ped while doing an animation")
        :AddHotkey())
    
    -- Contort toggle
    self:AddOption(ToggleOption.new("Contort")
        :AddToggleRef(animState, "contort")
        :AddTooltip("Completely fuck the animation")
        :AddHotkey())
    
    -- Animations scroll (select style - plays on select)
    self:AddOption(ScrollOption.new(ScrollOption.Type.SELECT, "Animations")
        :AddScroll(animations, 1)
        :AddIndexRef(animState, "animationType")
        :AddFunction(function()
            -- Calculate animation flag based on options
            local flag = 9
            if not animState.controllable and not animState.contort then
                flag = 9
            elseif not animState.controllable and animState.contort then
                flag = 257
            elseif animState.controllable and not animState.contort then
                flag = 121
            else
                flag = 377
            end
            
            local anim = animations[animState.animationType]
            local dict = anim.dict
            local animName = anim.anim
            local ped = PLAYER.PLAYER_PED_ID()
            
            -- Queue the animation loading job to run in scripting thread
            Script.QueueJob(function()
                STREAMING.REQUEST_ANIM_DICT(dict)
                local timeout = 0
                while not STREAMING.HAS_ANIM_DICT_LOADED(dict) and timeout < 50 do
                    Script.Yield(10)
                    timeout = timeout + 1
                end
                if STREAMING.HAS_ANIM_DICT_LOADED(dict) then
                    TASK.TASK_PLAY_ANIM(ped, dict, animName, 8.0, -8.0, -1, flag, 0, false, false, false)
                end
            end)
        end)
        :AddTooltip("Play this animation")
        :AddHotkey())
    
    -- Walkstyles scroll (select style - applies on select)
    self:AddOption(ScrollOption.new(ScrollOption.Type.SELECT, "Walkstyles")
        :AddScroll(walkstyles, 1)
        :AddIndexRef(animState, "walkstyleType")
        :AddFunction(function()
            local style = walkstyles[animState.walkstyleType]
            local clipset = style.clipset
            local ped = PLAYER.PLAYER_PED_ID()
            
            -- Queue the walkstyle loading job to run in scripting thread
            Script.QueueJob(function()
                STREAMING.REQUEST_ANIM_SET(clipset)
                local timeout = 0
                while not STREAMING.HAS_ANIM_SET_LOADED(clipset) and timeout < 50 do
                    Script.Yield(10)
                    timeout = timeout + 1
                end
                if STREAMING.HAS_ANIM_SET_LOADED(clipset) then
                    PED.SET_PED_MOVEMENT_CLIPSET(ped, clipset, 1048576000)
                    TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
                end
            end)
        end)
        :AddTooltip("Play this walkstyle")
        :AddHotkey())
    
    -- Scenarios scroll (select style - plays on select)
    self:AddOption(ScrollOption.new(ScrollOption.Type.SELECT, "Scenarios")
        :AddScroll(scenarios, 1)
        :AddIndexRef(animState, "scenarioType")
        :AddFunction(function()
            local ped = PLAYER.PLAYER_PED_ID()
            local scene = scenarios[animState.scenarioType]
            TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
            TASK.TASK_START_SCENARIO_IN_PLACE(ped, scene.scenario, 0, true)
        end)
        :AddTooltip("Play this scenario")
        :AddHotkey())
end

--[[ ============================================
    FEATURE UPDATE LOOP (Not needed for animations now)
============================================ ]]

function AnimationMenu:FeatureUpdate()
    -- Animation loading is now handled directly in callbacks with Script.Yield
end

return AnimationMenu

