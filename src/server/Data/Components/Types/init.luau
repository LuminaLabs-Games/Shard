local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaServer = require(ReplicatedStorage.Libraries.Replica.ReplicaServer)

local Types = {}

export type Profile = {
	Data: { [string]: any },
	LastSavedData: { [string]: any },
	FirstSessionTime: number,
	SessionLoadCount: number,
	Session: { PlaceId: number, JobId: string }?,
	RobloxMetaData: any,
	UserIds: { number },
	KeyInfo: DataStoreKeyInfo,
	OnSave: { Connect: (self: any, listener: () -> ()) -> { Disconnect: (self: any) -> () } },
	OnLastSave: {
		Connect: (
			self: any,
			listener: (reason: "Manual" | "External" | "Shutdown") -> ()
		) -> { Disconnect: (self: any) -> () },
	},
	OnSessionEnd: { Connect: (self: any, listener: () -> ()) -> { Disconnect: (self: any) -> () } },
	OnAfterSave: {
		Connect: (self: any, listener: (last_saved_data: { [string]: any }) -> ()) -> (
			{ Disconnect: (self: any) -> () }
		),
	},
	ProfileStore: any,
	Key: string,
	IsActive: (self: any) -> boolean,
	Reconcile: (self: any) -> (),
	EndSession: (self: any) -> (),
	AddUserId: (self: any, user_id: number) -> (),
	RemoveUserId: (self: any, user_id: number) -> (),
	MessageHandler: (self: any, fn: (message: any, processed: () -> ()) -> ()) -> (),
	Save: (self: any) -> (),
	SetAsync: (self: any) -> (),
}

export type Replica = typeof(ReplicaServer.Replica)

export type PlayerProfile = {
	_player: Player,
	_profile: Profile,
	_replica: Replica,
	-- Define PlayerProfile methods/types here:

	-- Internal Public API
	Set: (self: PlayerProfile, path: string | { string }, value: any) -> any,
	Get: (self: PlayerProfile, path: string | { string }) -> any,
	Increment: (self: PlayerProfile, currencyPath: string | { string }, amount: number) -> any,
	Decrement: (self: PlayerProfile, currencyPath: string | { string }, amount: number) -> any,
	CanAfford: (self: PlayerProfile, currencyPath: string | { string }, cost: number) -> boolean,
	GetPlayer: (self: PlayerProfile) -> Player,
	GetProfile: (self: PlayerProfile) -> Profile,
    GetReplica: (self: PlayerProfile) -> Replica,
	IsActive: (self: PlayerProfile) -> boolean,
}

export type Data = {
	initialize: (self: Data) -> (),
	GetProfileAsync: (self: Data, player: Player) -> PlayerProfile,
	GetPlayerStore: (self: Data) -> any,
	GetPlayerKey: (self: Data, player: Player) -> string,
	GetKeyFromUserId: (self: Data, userId: number) -> string,
}

return Types
