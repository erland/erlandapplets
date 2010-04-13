
--[[
=head1 NAME

applets.SettingsRemover.SettingsRemoverApplet - Partial Reset applet

=head1 DESCRIPTION

Partial Reset is an applet that makes it possible to rest certain settings on a Squeezeplay
based devices

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. SettingsRemoverApplet overrides the
following methods:

=cut
--]]


-- stuff we use
local pairs, ipairs, tostring, tonumber, package = pairs, ipairs, tostring, tonumber, package

local oo               = require("loop.simple")
local os               = require("os")
local io               = require("io")
local string           = require("jive.utils.string")

local System           = require("jive.System")
local Applet           = require("jive.Applet")
local Window           = require("jive.ui.Window")
local Textarea         = require("jive.ui.Textarea")
local Label            = require("jive.ui.Label")
local Icon             = require("jive.ui.Icon")
local Popup            = require("jive.ui.Popup")
local Framework        = require("jive.ui.Framework")
local SimpleMenu       = require("jive.ui.SimpleMenu")
local Task             = require("jive.ui.Task")

local lfs              = require("lfs")

local appletManager    = appletManager
local jiveMain         = jiveMain

module(..., Framework.constants)
oo.class(_M, Applet)


----------------------------------------------------------------------------------------
-- Helper Functions
--

-- display
-- the main applet function
function partialResetMenu(self, menuItem, action)

	log:debug("Partial Reset")
	self.auto = action and action == 'auto'

	self:init()

	if self.window and self.menu then
		self.window:removeWidget(self.menu)
		self.window:hide()
		self.window = nil
	end

	self.window = Window("text_list", tostring(self:string("SETTINGSREMOVER")))

	self.menu = SimpleMenu("menu")

	self.menu:setComparator(SimpleMenu.itemComparatorAlpha)
        self.menu:setHeaderWidget(Textarea("help_text", self:string("SETTINGSREMOVER_WARN")))
	self.window:addWidget(self.menu)

	self.needsReset = false
	if lfs.attributes(System.getUserDir().."/settings") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_APPLET_SETTINGS"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,System.getUserDir().."/settings",nil,nil,self:string("SETTINGSREMOVER_APPLET_SETTINGS_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	if lfs.attributes(System.getUserDir().."/wallpapers") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_WALLPAPERS"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,System.getUserDir().."/wallpapers",nil,nil,self:string("SETTINGSREMOVER_WALLPAPERS_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	if lfs.attributes(System.getUserDir()) then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_SCREENSHOTS"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,System.getUserDir(),nil,"bmp$",self:string("SETTINGSREMOVER_SCREENSHOTS_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	if lfs.attributes("/etc/squeezecenter/prefs") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_SBS_SETTINGS"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,"/etc/squeezecenter/prefs",true,nil,self:string("SETTINGSREMOVER_SBS_SETTINGS_DESC"))
						return EVENT_CONSUME
					end
			})
	end
	
	if lfs.attributes(self.luadir.."share/jive/applets/PatchInstaller.patches") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_PATCH_INSTALLER"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,self.luadir.."share/jive/applets/PatchInstaller.patches",nil,nil,self:string("SETTINGSREMOVER_PATCH_INSTALLER_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	if lfs.attributes(self.luadir.."share/jive/applets/CustomClock/fonts") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_CUSTOMCLOCK_FONTS"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,self.luadir.."share/jive/applets/CustomClock/fonts",nil,nil,self:string("SETTINGSREMOVER_CUSTOMCLOCK_FONTS_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	if lfs.attributes(self.luadir.."share/jive/applets/CustomClock/images") then
		self.menu:addItem({
				text = self:string("SETTINGSREMOVER_CUSTOMCLOCK_IMAGES"),
				callback = function(object, menuItem)
						self:openSettingsDirectory(menuItem,self.luadir.."share/jive/applets/CustomClock/images",nil,nil,self:string("SETTINGSREMOVER_CUSTOMCLOCK_IMAGES_DESC"))
						return EVENT_CONSUME
					end
			})
	end

	self.window:addListener(EVENT_WINDOW_POP, function()
		if self.needsReset then
			self:_reboot()
		end
	end)

	self:tieAndShowWindow(self.window)
	return self.window
end

function openSettingsDirectory(self,parentMenuItem,directory,recursive,filter,description)
	local window = Window("text_list",parentMenuItem.text)
	local menu = SimpleMenu("menu")
	window:addWidget(menu)

	local subdirs = lfs.dir(directory)
	for file in subdirs do
		if not filter or string.find(file,filter) then
			if lfs.attributes(directory.."/"..file,"mode") == "file" then
				menu:addItem(
					{
						text = file,
						sound = "WINDOWSHOW",
						callback = function(event, menuItem)
							self:openRemoveFile(menuItem,directory,file,window,parentMenuItem,recursive,filter,description)
							return EVENT_CONSUME
						end
					}
				)
			elseif lfs.attributes(directory.."/"..file,"mode") == "directory" and file ~= ".." and file ~= "." then
				menu:addItem(
					{
						text = file,
						sound = "WINDOWSHOW",
						callback = function(event, menuItem)
							if recursive then
								self:openSettingsDirectory(menuItem,directory.."/"..file,recursive,description)
							else
								self:openRemoveFile(menuItem,directory,file,window,parentMenuItem,recursive,filter,description)
							end
							return EVENT_CONSUME
						end
					}
				)
			end
		end
	end
        if menu:numItems() == 0 then
		menu:setHeaderWidget(Textarea("help_text", self:string("SETTINGSREMOVER_NONE_FOUND")))
	else
		menu:setHeaderWidget(Textarea("help_text", description))
	end

	self:tieAndShowWindow(window)
	return window
end

function openRemoveFile(self,menuItem,directory,file,parentWindow,parentMenuItem,recursive,filter,description)
	local window = Window("text_list",menuItem.text)
	local menu = SimpleMenu("menu")
	window:addWidget(menu)

	if lfs.attributes(directory.."/"..file,"mode") == "directory" then
	        menu:setHeaderWidget(Textarea("help_text", self:string("SETTINGSREMOVER_REMOVE_DIRECTORY",file)))
	else
	        menu:setHeaderWidget(Textarea("help_text", self:string("SETTINGSREMOVER_REMOVE_FILE",file)))
	end

	menu:addItem(
		{
			text = self:string("SETTINGSREMOVER_REMOVE"),
			sound = "WINDOWSHOW",
			callback = function(event, menuItem)
				log:info("Remove file/directory "..directory.."/"..file)
				os.execute("rm -rf \""..directory.."/"..file.."\"")
				self.needsReset = true
				window:hide()
				parentWindow:hide()
				self:openSettingsDirectory(parentMenuItem,directory,recursive,filter,description)
				return EVENT_CONSUME
			end
		}
	)

	self:tieAndShowWindow(window)
	return window
end

function _reboot(self)
        self.task = Task("patch download", self, function()
		self.animatelabel = Label("text", self:string("RESTART_JIVE"))
		self.animatewindow = Popup("waiting_popup")
	        local icon = Icon("icon_connecting")
		self.animatewindow:addWidget(icon)
		self.animatewindow:addWidget(self.animatelabel)
		self.animatewindow:show()

		if lfs.attributes("/bin/busybox") ~= nil then
		        -- two second delay
		        local t = Framework:getTicks()
		        while (t + 2000) > Framework:getTicks() do
		                Task:yield(true)
		        end
		        log:info("RESTARTING JIVE...")
		        appletManager:callService("reboot")
		else
			self.animatelabel:setValue(self:string("SETTINGSREMOVER_RESTART_APP"))
		        -- two second delay
		        local t = Framework:getTicks()
		        while (t + 5000) > Framework:getTicks() do
		                Task:yield(true)
		        end
		        self.animatewindow:hide()
		end
	end)
        self.task:addTask()
end

function init(self)
	if not self.luadir then
		if lfs.attributes("/usr/share/jive/applets") ~= nil then
			self.luadir = "/usr/"
		else
			-- find the main lua directory
			for dir in package.path:gmatch("([^;]*)%?[^;]*;") do
				local luadir = dir .. "share"
				local mode = lfs.attributes(luadir, "mode")
				if mode == "directory" then
				        self.luadir = dir
				        break
				end
			end
		end

		log:debug("Got lua directory: "..self.luadir)
	end
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


