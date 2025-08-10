Config = Config or {}
Config.FarmPlants = {}

---------------------------------------------
-- pland seed settings
---------------------------------------------
Config.ForwardDistance   = 2.0
Config.PromptGroupName   = 'Plant Seedling'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Plant'
Config.PromptRotateLeft  = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'

---------------------------------
-- npc settings
---------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true

---------------------------------
-- general settings
---------------------------------
Config.GrowAnywhere      = true -- toggle between planting anywhere or farming fields
Config.RestrictTownPlanting = true -- toggle if you allow planting in towns (default is true)
Config.DeadPlantTime     = 60 * 60 * 72 -- time until plant is dead and removed from db - e.g. 60 * 60 * 24 for 1 day / 60 * 60 * 48 for 2 days / 60 * 60 * 72 for 3 days
---------------------------------
Config.StartingThirst    = 30 -- starting plant thirst percentage
Config.ThirstIncrease    = 100 -- amount of thirst increased when water is used
Config.ThirstDecrease    = 1 -- amount of thirst decreases per cycle
---------------------------------
Config.StartingHunger    = 30 -- starting plant hunger percentage
Config.HungerIncrease    = 100 -- amount of hunger increased when fertilizer is used
Config.HungerDecrease    = 1 -- amount of hunger decreases per cycle
---------------------------------
Config.GrowthIncrease    = 1 -- amount growth increases per cycle
Config.GrowthBoostMin    = 1 -- min amount of growth increases per cycle (with fertilizer)
Config.GrowthBoostMax    = 3 -- min amount of growth increases per cycle (with fertilizer)
---------------------------------
Config.StartDegrade      = 25 -- thirst below number when plant degrades
Config.QualityDegrade    = 5 -- amount of degarde of quality per cycle if below thrist limit
Config.MaxPlantCount     = 100 -- maximum plants player can have at any one time
Config.CollectWaterTime  = 5000 -- time set to collect water (msec)
Config.CollectFertilizerTime = 5000 -- time set to collect fertilizer (msec)
Config.FarmingCronJob    = '*/1 * * * *' -- cronjob time runs every 1 mins
Config.EnableServerNotify = false -- toggle this to true if you want to see server notifications

---------------------------------
-- weather settings
---------------------------------
Config.ThirstRaining = 5 -- amount increases if raining per cycle
Config.ThirstShower  = 3 -- amount increases if raining per cycle
Config.ThirstDrizzle = 2 -- amount increases if raining per cycle

---------------------------------
-- farm plants
---------------------------------
Config.FarmItems = {
    {
        planttype = 'corn',
        item = 'corn',
        label = 'Corn',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'sugarcane',
        item = 'sugarcane',
        label = 'Sugarcane',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'cotton',
        item = 'cotton',
        label = 'Cotton',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'carrot',
        item = 'carrot',
        label = 'Carrot',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'potato',
        item = 'potato',
        label = 'Potato',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'tomato',
        item = 'tomato',
        label = 'Tomato',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'wheat',
        item = 'wheat',
        label = 'Wheat',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 6,
    },
    {
        planttype = 'weed',
        item = 'weed',
        label = 'Weed',
        -- reward settings
        poorRewardMin = 1,
        poorRewardMax = 2,
        goodRewardMin = 3,
        goodRewardMax = 4,
        exellentRewardMin = 5,
        exellentRewardMax = 8,
    },
}

---------------------------------
-- water props
---------------------------------
Config.WaterProps = {
    `p_wellpumpnbx01x`,
    `p_watertrough01x`,
    `p_watertroughsml01x`,
    `p_watertrough01x_new`,
    `p_watertrough02x`,
    `p_watertrough03x`,
}

---------------------------------
-- fertilizer props
---------------------------------
Config.FertilizerProps = {
    `p_horsepoop02x`,
    `p_horsepoop03x`,
    `new_p_horsepoop02x_static`,
    `p_poop01x`,
    `p_poop02x`,
    `p_poopile01x`,
    `p_sheeppoop01`,
    `p_sheeppoop02x`,
    `p_sheeppoop03x`,
    `p_wolfpoop01x`,
    `p_wolfpoop02x`,
    `p_wolfpoop03x`,
    `s_horsepoop01x`,
    `s_horsepoop02x`,
    `s_horsepoop03x`,
    `mp007_p_mp_horsepoop03x`,
}

---------------------------------
-- farm zone settings
---------------------------------
Config.FarmingZone = { 
    [1] = {
        zones = { -- example
            vector2(2703.1979980469, -792.98846435547),
            vector2(2648.6962890625, -818.03649902344),
            vector2(2639.88671875, -800.06427001953),
            vector2(2645.8039550781, -791.18969726563),
            vector2(2636.5283203125, -769.87414550781),
            vector2(2629.2639160156, -772.19573974609),
            vector2(2621.0795898438, -753.72912597656),
            vector2(2641.546875, -744.18621826172),
            vector2(2665.6091308594, -744.76910400391),
            vector2(2683.7849121094, -755.41778564453),
            vector2(2691.8337402344, -765.82135009766)
        },
        name = "stdenis1",
        minZ = 42.205417633057,
        maxZ = 42.399078369141,
        fieldcoords = vector3(2669.50, -776.80, 42.40),
        showblip = true
    },
}

---------------------------------
-- vegmod settings
---------------------------------
Config.DevMode = false
--Veg Modifiers Flags
local Debris = 1
local Grass = 2
local Bush = 4
local Weed = 8
local Flower = 16
local Sapling = 32
local Tree = 64
local Rock = 128
local LongGrass = 256
local AllFlags = Debris + Grass + Bush + Weed + Flower + Sapling + Tree + Rock + LongGrass

-- Veg Modifier Types
local VMT_Cull = 1
local VMT_Flatten = 2
local VMT_FlattenDeepSurface = 4
local VMT_Explode = 8
local VMT_Push = 16
local VMT_Decal = 32
local AllModifiers = VMT_Cull + VMT_Flatten + VMT_FlattenDeepSurface + VMT_Explode + VMT_Push + VMT_Decal

Config.VegZones = {
    { -- stdenis farming zone
        coords = vector3(2669.50, -776.80, 42.40),
        radius = 50.0, -- Radius
        distance = 100.0, -- View Distance
        vegmod = { flag = AllFlags, type = AllModifiers }
    },
}
