
--[[
=head1 NAME

applets.TextClock.TextClockApplet - Clock screensaver which writes the clock with words instead of digits

=head1 DESCRIPTION

Text Clock is a screen saver for Squeezeplay, it shows the clock with words like "Quarter past two" instead of 14:15

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. ScrollBugApplet overrides the
following methods:

=cut
--]]


-- stuff we use
local pairs, ipairs, tostring, tonumber, setmetatable, package, type = pairs, ipairs, tostring, tonumber, setmetatable, package, type

local oo               = require("loop.simple")
local os               = require("os")
local io               = require("io")
local math             = require("math")
local string           = require("jive.utils.string")

local Applet           = require("jive.Applet")
local Window           = require("jive.ui.Window")
local Group            = require("jive.ui.Group")
local Label            = require("jive.ui.Label")
local Font             = require("jive.ui.Font")
local Framework        = require("jive.ui.Framework")
local Timer            = require("jive.ui.Timer")

local System           = require("jive.System")
local DateTime         = require("jive.utils.datetime")

local appletManager    = appletManager
local jiveMain         = jiveMain

local WH_FILL           = jive.ui.WH_FILL
local LAYOUT_NONE       = jive.ui.LAYOUT_NONE

module(..., Framework.constants)
oo.class(_M, Applet)


----------------------------------------------------------------------------------------
-- Helper Functions
--

function openMenu(self)

	log:debug("Open screensaver")
	local player = appletManager:callService("getCurrentPlayer")
	local oldMode = self.mode
	self.mode = mode

        -- Create the main window if it doesn't already exist
	self.timewidget = Group("time",{
		label = Label("time","")
	})
	self.datewidget = Group("date",{
		label = Label("date","")
	})

	self.window = Window("window")
	self.window:setSkin(self:_getClockSkin(jiveMain:getSelectedSkin()))
	self.window:reSkin()
	self.window:setShowFrameworkWidgets(false)

	self.window:addWidget(self.timewidget)
	self.window:addWidget(self.datewidget)

	self.window:addTimer(1000, function() self:_tick() end)

	self:_tick()

	local manager = appletManager:getAppletInstance("ScreenSavers")
	manager:screensaverWindow(self.window)
	-- Show the window
	self.window:show(Window.transitionFadeIn)
end


function closeScreensaver(self)
	if self.window then
		self.window:hide()
		self.window = nil
	end
end

function _tick(self)
	self.timewidget:setWidgetValue("label",self:_getTextTime(self:getSettings()["single"]))
	local date = os.date(DateTime.getDateFormat(),5*math.floor(os.time()/5 + 0.5)+150)
	self.datewidget:setWidgetValue("label",date)
end

function getCustomClockTextTime(self,data,reference,text,sink)
	local text = nil
	if text and text == "multirow" then
		text = self:_getTextTime(false)
	else
		text = self:_getTextTime(true)
	end
	sink(reference,text)
end

function _getTextTime(self,singlerow)
	local time = os.date("*t",5*math.floor(os.time()/5 + 0.5)+150)

	local minute = 5 * math.floor(time.min/5)

	local override = tostring(self:string("SCREENSAVER_TEXTCLOCK_TIME_"..time.hour.."_"..minute))
	if override and override ~= "SCREENSAVER_TEXTCLOCK_TIME_"..time.hour.."_"..minute then
		return override
	end

	local hourCorrection = tostring(self:string("SCREENSAVER_TEXTCLOCK_TIME_"..minute.."_CORR"))
	if not hourCorrection or hourCorrection == "SCREENSAVER_TEXTCLOCK_TIME_"..minute.."_CORR" then
		hourCorrection = 0
	end
	local hour = time.hour + tonumber(hourCorrection)
	hour = tonumber(hour) % 12
	if hour == 0 then
		hour = 12
	end
	local hourString = tostring(self:string("SCREENSAVER_TEXTCLOCK_TIME_"..hour.."H"))
	if not singlerow then
		return tostring(self:string("SCREENSAVER_TEXTCLOCK_MULTIROW_TIME_"..minute,hourString))
	else
		return tostring(self:string("SCREENSAVER_TEXTCLOCK_TIME_"..minute,hourString))
	end
end

function _loadFont(self,font,fontSize)
	log:debug("Loading font: "..font.." of size "..fontSize)
        return Font:load(font, fontSize)
end


function _getClockSkin(self,skin)
	local s = {}
	local width,height = Framework.getScreenSize()

	s.window = {}

	if System:getMachine() == 'squeezeplay' then
		if width == 480 then
			self.model = "fab4"
		elseif width == 320 then
			self.model = "baby"
		else
			self.model = "jive"
		end
	else
		self.model = System:getMachine()
	end

	if self:getSettings()["single"] then	
		if self.model == "baby" then
			dateFontSize = 20
			timeFontSize = 30
			timeSmallFontSize = timeFontSize
			timeheight = timeFontSize * 1.5
		elseif self.model == "fab4" then
			dateFontSize = 35
			timeFontSize = 45
			timeSmallFontSize = timeFontSize
			timeheight = timeFontSize * 1.5
		else 
			dateFontSize = 17
			timeFontSize = 20
			timeSmallFontSize = timeFontSize
			timeheight = timeFontSize * 1.5
		end
	else
		if self.model == "baby" then
			dateFontSize = 20
			timeFontSize = 60
			timeSmallFontSize = 35
			timeheight = timeFontSize * 3.7
		elseif self.model == "fab4" then
			dateFontSize = 35
			timeFontSize = 70
			timeSmallFontSize = 45
			timeheight = timeFontSize * 3.5
		else 
			dateFontSize = 17
			timeFontSize = 45
			timeSmallFontSize = 35
			timeheight = timeFontSize * 3.7
		end
	end
	timePosY = dateFontSize + 10

	s.window["time"] = {
		position = LAYOUT_NONE,
		y = timePosY,
		x = 0,
		zOrder = 4,
	}
	local font = self:_loadFont("fonts/FreeSans.ttf",timeFontSize)
	local smallFont = self:_loadFont("fonts/FreeSans.ttf",timeSmallFontSize)
	
	s.window["time"]["time"] = {
			border = {5,0,5,0},
			font = font,
			line = {
				{
					font = font,
					height = timeFontSize+10,
				},
				{
					font = smallFont,
					height = timeSmallFontSize+10,
				},
				{
					font = font,
					height = timeFontSize+10,
				}
			},
			align = "center",
			w = WH_FILL,
			h = timeheight,
			fg = {0xff, 0xff, 0xff},
		}

	s.window["date"] = {
		position = LAYOUT_NONE,
		y = 5,
		x = 0,
		zOrder = 4,
	}
	font = self:_loadFont("fonts/FreeSans.ttf",dateFontSize)

	s.window["date"]["date"] = {
			border = {5,0,5,0},
			font = font,
			align = "center",
			w = WH_FILL,
			h = dateFontSize+5,
			fg = {0xff, 0xff, 0xff},
		}

	return s
end

--[[

=head1 LICENSE

Copyright 2010, Erland Isaksson (erland_i@hotmail.com)
Copyright 2010, Logitech, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Logitech nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL LOGITECH, INC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
--]]

