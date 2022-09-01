# ServerLogHelper

## Overview
ServerLogHelper provides improved logging for DCS servers and other helpful server automation.

This project is in an early state, and the structure is fairly ad-hoc/experimental, just to provide the basic functionality to suit the needs of the servers using it. In short, there's a lot of room for polish!

Operates only on multiplayer missions and only on the server.

## Installation
Simply drop the Mods and Scripts folder into the DCS saved games folder on the server machine. So that `<DCS Saved Games>\Mods\Services\ServerLogHelper\Scripts` and `<DCS Saved Games>\Scripts\Hooks` both contain a file called `DCS-ServerLogHelper.lua`.

## Config options
Configured in `<DCS Saved Games>\Config\ServerLogHelper.lua`
* `directory` - location for server logs. HTese are stored per mission run
* `restarts` - specify times to restart the server. Each entry in `restarts` has the entries
    * `weekday` - 1 = Sunday, 2 = Monday etc
    * `hour` - (optional) timezone appears to be UTC, but may vary locally
    * `minute` - (optional)
	
e.g. `["restarts"] = {{weekday = 2},{weekday = 4},{weekday = 6}}` to restart Mon,Wed,Fri at 00:00