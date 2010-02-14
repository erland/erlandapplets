
--[[
=head1 NAME

applets.AlarmSavers.AlarmSaversApplet - A screensaver that switches between other screensavers

=head1 DESCRIPTION

Alarm Savers is a applet for Squeezeplay that makes is possible to use any screen saver as your alarm screen saver. 

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. AlarmSaversApplet overrides the
following methods:

=cut
--]]


-- stuff we use
local pairs, ipairs, tostring, tonumber, pcall = pairs, ipairs, tostring, tonumber, pcall

local oo               = require("loop.simple")
local os               = require("os")
local math             = require("math")
local string           = require("jive.utils.string")
local table            = require("jive.utils.table")

local datetime         = require("jive.utils.datetime")

local Applet           = require("jive.Applet")
local System           = require("jive.System")
local Window           = require("jive.ui.Window")
local Group            = require("jive.ui.Group")
local Framework        = require("jive.ui.Framework")
local SimpleMenu       = require("jive.ui.SimpleMenu")
local RadioGroup       = require("jive.ui.RadioGroup")
local RadioButton      = require("jive.ui.RadioButton")
local Timer            = require("jive.ui.Timer")
local Textarea         = require("jive.ui.Textarea")

local appletManager    = appletManager
local jiveMain         = jiveMain
local jnt              = jnt

local WH_FILL           = jive.ui.WH_FILL
local LAYOUT_NORTH      = jive.ui.LAYOUT_NORTH
local LAYOUT_SOUTH      = jive.ui.LAYOUT_SOUTH
local LAYOUT_CENTER     = jive.ui.LAYOUT_CENTER
local LAYOUT_WEST       = jive.ui.LAYOUT_WEST
local LAYOUT_EAST       = jive.ui.LAYOUT_EAST
local LAYOUT_NONE       = jive.ui.LAYOUT_NONE

module(..., Framework.constants)
oo.class(_M, Applet)


----------------------------------------------------------------------------------------
-- Helper Functions
--

-- display
-- the main applet function, the meta arranges for it to be called
-- by the AlarmSaversApplet.
function viewAlarmSaversWindow(self,fallback)
	self.player = appletManager:callService("getCurrentPlayer")

	local ss = self:getSettings()["alarmsaver"]

	if ss then
		local screensaversApplet = appletManager:loadApplet("ScreenSavers") 
		local ssData = screensaversApplet["screensavers"][ss]
		local ssApplet = appletManager:loadApplet(ssData.applet)

		-- We do this with pcall just for safety 
		local status,err = pcall(ssApplet[ssData.method], ssApplet, force, ssData.methodParam)
		log:debug("activating " .. ssData.applet .. " "..tostring(ssData.displayName).." screensaver")
	else
		local alarmSnoozeApplet = appletManager:loadApplet("AlarmSnooze") 
		-- We do this with pcall just for safety 
		local status,err = pcall(alarmSnoozeApplet["_openAlarmWindow"], alarmSnoozeApplet, fallback)
		log:warn("Status: "..tostring(status)..", "..tostring(err))
	end
end

function isSoftPowerOn(self)
        return jiveMain:getSoftPowerState() == "on"
end

function openSettings(self)
	log:debug("Screen Switcher settings")

	if not appletManager:callService("isPatchInstalled","60a51265-1938-4fd7-b703-12d3725870da") then
		local window = Window("text_list", self:string("SCREENSAVER_ALARMSAVERS_SETTINGS"), 'settingstitle')
		local menu = SimpleMenu("menu")

		menu:setHeaderWidget(Textarea("help_text", self:string("SCREENSAVER_ALARMSAVERS_SETTINGS_NOT_PATCHED")))
		window:addWidget(menu)
		self:tieAndShowWindow(window)
		return window
	end
	local window = Window("text_list", self:string("SCREENSAVER_ALARMSAVERS_SETTINGS"), 'settingstitle')
	local alarmsaver = self:getSettings()["alarmsaver"]

	local menu = SimpleMenu("menu")
	menu:setComparator(menu.itemComparatorWeightAlpha)
	local group = RadioGroup()

	window:addWidget(menu)

	local screensaversApplet = appletManager:loadApplet("ScreenSavers")
	local screensavers = screensaversApplet["screensavers"]

	menu:addItem({
		text = self:string("SCREENSAVER_ALARMSAVERS_SETTINGS_NONE"),
		style = 'item_choice',
		check = RadioButton(
			"radio",
			group,
			function()
				self:getSettings()["alarmsaver"] = nil
				self:storeSettings()
			end,
			alarmsaver == nil
		),
		weight = 50,
	})
	for _,screensaver in pairs(screensavers) do
		if screensaver.applet and screensaver.applet ~= 'BlankScreen' then
			menu:addItem({
				text = screensaver.displayName,
				style = 'item_choice',
				check = RadioButton(
					"radio",
					group,
					function()
						self:getSettings()["alarmsaver"] = self:getKey(screensaver.applet,screensaver.method,screensaver.additionalKey)
						self:storeSettings()
					end,
					alarmsaver and alarmsaver == self:getKey(screensaver.applet,screensaver.method,screensaver.additionalKey)
				),
				weight = 100,
			})
		end
	end

	self:tieAndShowWindow(window)
	return window
end

function getKey(self, appletName, method, additionalKey)
        local key = tostring(appletName) .. ":" .. tostring(method)
        if additionalKey then
                key = key .. ":" .. tostring(additionalKey)
        end
        return key
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


