local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaServer = require(ReplicatedStorage.Libraries.Replica.ReplicaServer)

local Types = {}

export type Profile = {
    Data: {[string]: any},
    LastSavedData: {[string]: any},
    FirstSessionTime: number,
    SessionLoadCount: number,
    Session: {PlaceId: number, JobId: string}?,
    RobloxMetaData: {[string]: any},
    UserIds: {number},
    KeyInfo: DataStoreKeyInfo,
    IsActive: () -> boolean,
    EndSession: () -> (),
    AddUserId: (self: any, user_id: number) -> (),
    RemoveUserId: (self: any, user_id: number) -> (),
    MessageHandler: (self: any, fn: (message: any, processed: () -> ()) -> ()) -> (),
    Save: () -> (),
    SetAsync: () -> (),
}

export type Replica = typeof(ReplicaServer.Replica)

export type PlayerProfile = {
    _player: Player,
    _profile: Profile,
    _replica: Replica,
    -- Define PlayerProfile methods/types here:
	
    -- Internal API
    Get: (self: PlayerProfile, keyToGet: string, tableToSearch: {[string]: any}?) -> any,
    Set: (self: PlayerProfile, keyToSet: string, valueToSet: any, tableToSearch: {[string]: any}?, path: {string}?) -> boolean,
    Increment: (self: PlayerProfile, currency: string, amount: number) -> (),
    Decrement: (self: PlayerProfile, currency: string, amount: number) -> (),
    GetPlayer: (self: PlayerProfile) -> Player,
    GetProfile: (self: PlayerProfile) -> Profile,
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