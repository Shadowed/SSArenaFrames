--[[ $Id: AceTimer-3.0.lua 56244 2007-11-29 12:29:28Z mikk $ ]]
--[[
	Basic assumptions:
	* In a typical system, we do more re-scheduling per second than there are timer pulses per second
	* Regardless of timer implementation, we cannot guarantee timely delivery due to FPS restriction (may be as low as 10)

	This implementation:
		CON: The smallest timer interval is constrained by HZ (currently 1/10s).
		PRO: It will correctly fire any timer faster than HZ over a length of time, e.g. 0.11s interval -> 90 times over 10 seconds
		PRO: In lag bursts, the system simly skips missed timer intervals to decrease load
		CON: Algorithms depending on a timer firing "N times per minute" will fail
		PRO: (Re-)scheduling is O(1) with a VERY small constant. It's a simple table insertion in a hash bucket.
		PRO: ALLOWS scheduling multiple timers with the same funcref/method
		CAUTION: The BUCKETS constant constrains how many timers can be efficiently handled. With too many hash collisions, performance will decrease.
]]

local MAJOR, MINOR = "AceTimer-3.0", 0
local AceTimer, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceTimer then return end -- No upgrade needed

AceTimer.hash = AceTimer.hash or {}         -- Array of [0..BUCKET-1] = linked list of timers (using .next member)
                                            -- Linked list gets around ACE-88 and ACE-90.
AceTimer.selfs = AceTimer.selfs or {}       -- Array of [self]={[handle]=timerobj, [handle2]=timerobj2, ...}
AceTimer.frame = AceTimer.frame or CreateFrame("Frame", "AceTimer30Frame")

local pcall = pcall
local pairs = pairs
local tostring = tostring
local floor = floor
local max = max

-- Simple ONE-SHOT timer cache. Much more efficient than a full compost for our purposes.
local timerCache = nil

--[[
	Timers will not be fired more often than HZ-1 times per second. 
	Keep at intended speed PLUS ONE or we get bitten by floating point rounding errors (n.5 + 0.1 can be n.599999)
	If this is ever LOWERED, all existing timers need to be enforced to have a delay >= 1/HZ on lib upgrade.
	If this number is ever changed, all entries need to be rehashed on lib upgrade.
	]]
local HZ = 11

--[[
	Prime for good distribution
	If this number is ever changed, all entries need to be rehashed on lib upgrade.
]]
local BUCKETS = 131

local hash = AceTimer.hash
for i=1,BUCKETS do
	hash[i] = hash[i] or false	-- make it an integer-indexed array; it's faster than hashes
end

local function safecall(func, ...)
	local success, err = pcall(func, ...)
	if success then return err end
	
	if not err:find("%.lua:%d+:") then err = (debugstack():match("\n(.-: )in.-\n") or "") .. err end
	geterrorhandler()(err)
end


local lastint = floor(GetTime() * HZ)

----------------------------------------------------------------------
-- OnUpdate handler
--
-- traverse buckets, always chasing "now", and fire timers that have expired

local function OnUpdate()
	local now = GetTime()
	local nowint = floor(now * HZ)
	
	-- Have we passed into a new hash bucket?
	if nowint == lastint then return end
	
	local soon = now + 1 -- +1 is safe as long as 1 < HZ < BUCKETS/2
	
	-- Pass through each bucket at most once
	-- Happens on e.g. instance loads, but COULD happen on high local load situations also
	for curint = (max(lastint, nowint - BUCKETS) + 1), nowint do -- loop until we catch up with "now", usually only 1 iteration
		local curbucket = (curint % BUCKETS)+1
		local nexttimer = hash[curbucket]
		hash[curbucket] = false	-- false rather than nil to prevent the array from becoming a hash

		while nexttimer do
			local timer = nexttimer
			nexttimer = timer.next
			local when = timer.when
			
			if when < soon then
				-- Call the timer func, either as a method on given object, or a straight function ref
				local callback = timer.callback
				if type(callback) == "string" then
					safecall(timer.object[callback], timer.object, timer.arg)
				elseif callback then
					safecall(callback, timer.arg)
				else
					-- probably nilled out by CancelTimer
					timer.delay = nil -- don't reschedule it
				end

				local delay = timer.delay	-- NOW make a local copy, can't do it earlier in case the timer cancelled itself in the callback
				
				if not delay then
					-- single-shot timer (or cancelled)
					AceTimer.selfs[timer.object][tostring(timer)] = nil
					timerCache = timer
				else
					-- repeating timer
					local newtime = when + delay
					if newtime < now then -- Keep lag from making us firing a timer unnecessarily. (Note that this still won't catch too-short-delay timers though.)
						newtime = now + delay
					end
					timer.when = newtime
					
					-- add next timer execution to the correct bucket
					local bucket = (floor(newtime * HZ) % BUCKETS) + 1
					timer.next = hash[bucket]
					hash[bucket] = timer
				end
			else -- if when>=soon 
				-- reinsert (yeah, somewhat expensive, but shouldn't be happening too often either due to hash distribution)
				timer.next = hash[curbucket]
				hash[curbucket] = timer
			end -- if when<soon ... else
		end -- while nexttimer do
	end -- for curint=lastint,nowint
	
	lastint = nowint
end

-----------------------------------------------------------------------
-- Reg( callback, delay, arg, repeating )
--
-- callback( function or string ) - direct function ref or method name in our object for the callback
-- delay(int) - delay for the timer
-- arg(variant) - any argument to be passed to the callback function
-- repeating(boolean) - repeating timer, or oneshot
--
-- returns the handle of the timer for later processing (canceling etc)
local function Reg(self, callback, delay, arg, repeating)
	if type(callback) ~= "string" and type(callback) ~= "function" then 
		local error_origin = repeating and "ScheduleRepeatingTimer" or "ScheduleTimer"
		error(MAJOR..": " .. error_origin .. "(callback, delay, arg): 'callback' - function or method name expected.", 3)
	end
	if type(callback) == "string" then
		if type(self)~="table" then
			local error_origin = repeating and "ScheduleRepeatingTimer" or "ScheduleTimer"
			error(MAJOR..": " .. error_origin .. "(\"methodName\", delay, arg): 'self' - must be a table.", 3)
		end
		if type(self[callback]) ~= "function" then 
			local error_origin = repeating and "ScheduleRepeatingTimer" or "ScheduleTimer"
			error(MAJOR..": " .. error_origin .. "(\"methodName\", delay, arg): 'methodName' - method not found on target object.", 3)
		end
	end
	
	if delay < (1 / (HZ - 1)) then
		delay = 1 / (HZ - 1)
	end
	
	-- Create and stuff timer in the correct hash bucket
	local now = GetTime()
	
	local timer = timerCache or {}	-- Get new timer object (from cache if available)
	timerCache = nil
	
	timer.object = self
	timer.callback = callback
	timer.delay = (repeating and delay)
	timer.arg = arg
	timer.when = now + delay

	local bucket = (floor((now+delay)*HZ) % BUCKETS) + 1
	timer.next = hash[bucket]
	hash[bucket] = timer
	
	-- Insert timer in our self->handle->timer registry
	local handle = tostring(timer)
	
	local selftimers = AceTimer.selfs[self]
	if not selftimers then
		selftimers = {}
		AceTimer.selfs[self] = selftimers
	end
	selftimers[handle] = timer
	
	return handle
end


-----------------------------------------------------------------------
-- AceTimer:ScheduleTimer( callback, delay, arg )
-- AceTimer:ScheduleRepeatingTimer( callback, delay, arg )
--
-- callback( function or string ) - direct function ref or method name in our object for the callback
-- delay(int) - delay for the timer
-- arg(variant) - any argument to be passed to the callback function
--
-- returns a handle to the timer, which is used for cancelling it
function AceTimer:ScheduleTimer(callback, delay, arg)
	return Reg(self, callback, delay, arg)
end

function AceTimer:ScheduleRepeatingTimer(callback, delay, arg)
	return Reg(self, callback, delay, arg, true)
end


-----------------------------------------------------------------------
-- AceTimer:CancelTimer(handle)
--
-- handle - Opaque object given by ScheduleTimer
--
-- Cancels a timer with the given handle, registered by the same 'self' as given here
--
-- Returns true if a timer was cancelled

function AceTimer:CancelTimer(handle)
	if type(handle)~="string" then
		error(MAJOR..": CancelTimer(handle): 'handle' - expected a string", 2)	-- for now, anyway
	end
	local selftimers = AceTimer.selfs[self]
	local timer = selftimers and selftimers[handle]
	if timer then
		timer.callback = nil		-- don't run it
		-- The timer object is removed in the OnUpdate loop
	end
	return not not timer
end


-----------------------------------------------------------------------
-- AceTimer:CancelAllTimers()
--
-- Cancels all timers registered to given 'self'
function AceTimer:CancelAllTimers()
	if not(type(self)=="string" or type(self)=="table") then
		error("CancelAllTimers(): 'self' - must be a string or a table",2)
	end
	if self==AceTimer then
		error("CancelAllTimers(): supply a meaningful 'self'", 2)
	end
	
	local selftimers = AceTimer.selfs[self]
	if selftimers then
		for handle in pairs(selftimers) do
			AceTimer.CancelTimer(self, handle)
		end
	end
end


-----------------------------------------------------------------------
-- Embed handling

AceTimer.embeds = AceTimer.embeds or {}

local mixins = {
	"ScheduleTimer", "ScheduleRepeatingTimer", 
	"CancelTimer", "CancelAllTimers"
}

function AceTimer:Embed(object)
	AceTimer.embeds[object] = true
	for _,v in pairs(mixins) do
		object[v] = AceTimer[v]
	end
end

for addon in pairs(AceTimer.embeds) do
	AceTimer:Embed(addon)
end

-----------------------------------------------------------------------
-- Debug tools (expose copies of internals to test suites)
AceTimer.debug = AceTimer.debug or {}
AceTimer.debug.HZ = HZ
AceTimer.debug.BUCKETS = BUCKETS

-----------------------------------------------------------------------
-- Finishing touchups

AceTimer.frame:SetScript("OnUpdate", OnUpdate)

-- In theory, we should hide&show the frame based on there being timers or not.
-- However, this job is fairly expensive, and the chance that there will 
-- actually be zero timers running is diminuitive to say the lest.
