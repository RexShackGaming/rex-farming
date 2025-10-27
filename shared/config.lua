Config = Config or {}
Config.FarmPlants = {}

---------------------------------------------
-- Plant Seed Placement Settings
---------------------------------------------
Config.ForwardDistance   = 2.0  -- Distance in front of player to place plant
Config.PromptGroupName   = 'Plant Seedling'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Plant'
Config.PromptRotateLeft  = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'

---------------------------------
-- NPC Settings (if applicable)
---------------------------------
Config.DistanceSpawn = 20.0  -- Distance for NPC spawn
Config.FadeIn = true         -- Enable NPC fade in effect

---------------------------------
-- General Farming Settings
---------------------------------
Config.GrowAnywhere      = true  -- Allow planting anywhere (false = only in designated farming zones)
Config.RestrictTownPlanting = true  -- Prevent planting in town zones
Config.DeadPlantTime     = 60 * 60 * 72  -- Time until plant dies and is removed (3 days)
Config.MaxPlantCount     = 100  -- Maximum plants per player
Config.OwnerHarvestOnly  = true  -- Only plant owner can harvest
Config.EnableServerNotify = false  -- Enable server console notifications for debugging

---------------------------------
-- Plant Thirst System
---------------------------------
Config.StartingThirst    = 30   -- Starting plant thirst percentage (0-100)
Config.ThirstIncrease    = 100  -- Thirst gained when watered
Config.ThirstDecrease    = 1    -- Thirst lost per growth cycle
Config.StartDegrade      = 25   -- Thirst level where quality starts degrading

---------------------------------
-- Plant Hunger System
---------------------------------
Config.StartingHunger    = 30   -- Starting plant hunger percentage (0-100)
Config.HungerIncrease    = 100  -- Hunger gained when fertilized
Config.HungerDecrease    = 1    -- Hunger lost per growth cycle

---------------------------------
-- Plant Growth System
---------------------------------
Config.GrowthIncrease    = 1    -- Base growth per cycle
Config.GrowthBoostMin    = 1    -- Min bonus growth with fertilizer
Config.GrowthBoostMax    = 3    -- Max bonus growth with fertilizer

---------------------------------
-- Plant Quality System
---------------------------------
Config.QualityDegrade    = 5    -- Quality lost per cycle when thirst is low

---------------------------------
-- Collection Times (milliseconds)
---------------------------------
Config.CollectWaterTime  = 5000      -- Time to collect water (5 seconds)
Config.CollectFertilizerTime = 5000  -- Time to collect fertilizer (5 seconds)

---------------------------------
-- Cron Job Settings
---------------------------------
Config.FarmingCronJob    = '*/1 * * * *'  -- Growth cycle runs every 1 minute
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
