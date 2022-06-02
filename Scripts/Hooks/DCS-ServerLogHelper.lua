  --Hook to load ServerLogHelper
 local status, result = pcall(function() local dcsSr=require('lfs');dofile(dcsSr.writedir()..[[Mods\Services\ServerLogHelper\Scripts\DCS-ServerLogHelper.lua]]); end,nil) 
 
 if not status then
 	net.log(result)
 end