-- RemoteEvents shared by the server scripts, created once on first require.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local notify = Instance.new("RemoteEvent")
notify.Name = "Notify" -- server -> client pop-up messages
notify.Parent = folder

folder.Parent = ReplicatedStorage

return {
	Notify = notify,
}
