--By WhimWidget!

local SilverPSwitch = {}

SilverPSwitch.NonaffectedNPCs = {357}
SilverPSwitch.AffectedNPCs = {}
SilverPSwitch.MuncherBlocks = {109,511}

SilverPSwitch.MuncherCoins = {}
SilverPSwitch.GlobalTimer = 0 --This duration lasts outside of the coin
SilverPSwitch.GlobalCollectCount = 0 --This value for accumilating 
SilverPSwitch.SilverToggled = false

return SilverPSwitch