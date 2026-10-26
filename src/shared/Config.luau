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
		DEBUG_VISIBLE = true, -- shows the entity as a faint red shape; set false for the real thing
	},
	-- CollectionService tag on parts the entity patrols between.
	PATROL_POINT_TAG = "EntityPatrolPoint",
}

return Config
