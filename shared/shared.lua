Config = {}

-- Pump Settings
Config.PumpItem = 'waterpump'
Config.PumpModel = 'p_waterpump01x'
Config.PlacementDistance = 3.0
Config.InteractionDistance = 2.0
Config.MaxPumpsPerPlayer = 3
Config.SavePumps = true
Config.PumpLifetime = 168 -- Hours (0 = permanent)
Config.SpawnDistance = 100.0 -- Distance to spawn/despawn pumps

-- Water Filling Settings
Config.EmptyBottleItem = 'emptybottle'
Config.WaterItem = 'water'
Config.WaterPerFill = 1
Config.RequireEmptyBottle = true

-- Animation Settings
Config.Anim = {
    -- Fill bottle / Pickup animation
    dict = 'amb_work@world_human_box_pickup@1@male_a@stand_exit_withprop',
    name = 'exit_front',
    duration = 2300,
    -- Placing animation
    placingDict = 'amb_work@world_human_box_pickup@1@male_a@stand_exit_withprop',
    placingName = 'exit_front',
    placingDuration = 4000
   
}

-- Prompt Settings
Config.PromptGroupName = "Water Pump Placement"
Config.PromptCancelName = "Cancel"
Config.PromptPlaceName = "Place Pump"
Config.PromptRotateLeft = "Rotate Left"
Config.PromptRotateRight = "Rotate Right"
Config.PromptPitchUp = "Pitch Up"
Config.PromptPitchDown = "Pitch Down"
Config.PromptRollLeft = "Roll Left"
Config.PromptRollRight = "Roll Right"

-- Pump Target Prompts
Config.PromptFillBottle = "Fill Bottle"
Config.PromptPickupPump = "Pick Up Pump"

-- Prop for holding during animation (optional)
Config.UsePropDuringAnim = true
Config.AnimProp = 'p_bottlebroken03x' -- Bottle prop model