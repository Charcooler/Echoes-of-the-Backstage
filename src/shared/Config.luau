--!strict
-- Shared constants used by both server and client.
-- Keep numbers and names here so both of us (and both Claudes) use the same values.

export type Stance = {
	WALK_SPEED: number, -- Humanoid.WalkSpeed while in this stance
	NOISE: number, -- noise level of one footstep (0 = silent)
	STEP_INTERVAL: number, -- seconds between footsteps while moving
}

local STANCES: { [string]: Stance } = {
	Crouch = { WALK_SPEED = 8, NOISE = 0, STEP_INTERVAL = 0.7 },
	Walk = { WALK_SPEED = 16, NOISE = 30, STEP_INTERVAL = 0.5 },
	Sprint = { WALK_SPEED = 26, NOISE = 80, STEP_INTERVAL = 0.3 },
}

local Config = {
	GAME_NAME = "Echoes of the Backstage",
	MAX_PLAYERS = 4,

	STANCES = STANCES,
	-- Noise types a client may report through NoiseEvent.
	NOISE_TYPES = { Footstep = true } :: { [string]: boolean },
	-- Server drops NoiseEvents from a player that arrive faster than this (seconds). Must stay below the shortest STEP_INTERVAL.
	NOISE_EVENT_MIN_INTERVAL = 0.2,
	-- Extra studs/s allowed above a stance's WALK_SPEED before the server bumps the player to a louder stance.
	NOISE_SPEED_TOLERANCE = 3,

	-- The invisible entity (EntityService). It hears a noise when it is within `NOISE` studs of it.
	ENTITY = {
		PATROL_SPEED = 6,
		INVESTIGATE_SPEED = 12,
		HUNT_SPEED = 22, -- below Sprint WALK_SPEED so a sprinting player can outrun it (but keeps it hunting)
		HUNT_NOISE = 60, -- a heard noise at or above this level starts a Hunt instead of an Investigate
		CATCH_RANGE = 4, -- studs
		LINGER_TIME = 3, -- seconds it stands listening where a noise was before patrolling again
		DEBUG_VISIBLE = true, -- shows the entity's body all the time; set false for the real thing (then it only shows when it catches someone)
		-- Rigged body mesh: made with Roblox's AI mesh generator, rigged in Blender (art/stagehand) and imported
		-- with Studio's 3D importer. Its bones live in EntityService/StagehandRig. Set to nil for the primitive body.
		MESH = {
			MESH_ID = "rbxassetid://74315921560822",
			TEXTURE_ID = "rbxassetid://137833493602393",
		} :: { MESH_ID: string, TEXTURE_ID: string }?,
	},
	-- Rounds and objectives (RoundService, ObjectiveService).
	ROUND = {
		REPAIR_TIME = 5, -- seconds a player holds the prompt to fix a fuse box
		REPAIR_NOISE = 25, -- noise level while someone is repairing (heard within 25 studs; 40 made solo play near impossible)
		REPAIR_NOISE_INTERVAL = 1.5, -- seconds between repair noises
		RESULT_TIME = 8, -- seconds the result screen shows before the next round
	},
	-- Throwable bottles (ItemService).
	THROW = {
		RANGE = 45, -- studs
		NOISE = 70, -- loud enough to start a Hunt where it shatters
		COOLDOWN = 1, -- seconds
	},

	-- CollectionService tags the map uses (DemoRoomService now, a Studio-built map later).
	PATROL_POINT_TAG = "EntityPatrolPoint",
	FUSE_BOX_TAG = "FuseBox",
	EXIT_DOOR_TAG = "ExitDoor",
	EXIT_ZONE_TAG = "ExitZone",
	BOTTLE_SPAWN_TAG = "BottleSpawn",
}

return Config
