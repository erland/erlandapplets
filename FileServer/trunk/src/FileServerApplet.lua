
--[[
=head1 NAME

applets.FileServer.FileServerApplet - File Server applet

=head1 DESCRIPTION

File Server is an applet that makes it possible to rest certain settings on a Squeezeplay
based devices

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. FileServerApplet overrides the
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
local Framework        = require("jive.ui.Framework")

local lfs              = require("lfs")
local mime             = require("mime")
local math             = require("math")

local appletManager    = appletManager
local jiveMain         = jiveMain
local jnt              = jnt

module(..., Framework.constants)
oo.class(_M, Applet)


----------------------------------------------------------------------------------------
-- Helper Functions
--

function init(self)
	jnt:subscribe(self)
end

function notify_playerCurrent(self,player)
	log:debug("Subscribing on events")
	player:unsubscribe('/slim/fileserver.dir')
	player:subscribe(
		'/slim/fileserver.dir',
		function(chunk)
			local server = chunk.data[2]
			local secret = chunk.data[3]
			if server == System:getMacAddress() and secret == self.secret then
				local handle = chunk.data[4]
				local dir = chunk.data[5]
				local server = player:getSlimServer()
				log:debug("Getting files for "..tostring(dir))
				local subdirs = lfs.dir(dir)
				local result = {}
				local no = 1
				for file in subdirs do
					if file == ".." then
						if dir ~= "/" then
							local parentdir = dir
							parentdir = string.gsub(parentdir,"/[^/]+$","")
							result[no] = { 
								fullpath = parentdir,
								name = file,
								type = lfs.attributes(dir.."/"..file,"mode")
							}
							no = no +1
						end
					elseif file ~= "." then
						local separator = "/"
						if dir == "/" then
							separator = ""
						end
						result[no] = { 
							fullpath = dir..separator..file,
							name = file,
							type = lfs.attributes(dir..separator..file,"mode")
						}
						no = no +1
					end
				end
				server = player:getSlimServer()
				server:userRequest(function(chunk,err)
						if err then
							log:warn(err)
						end
					end,
					player and player:getId(),
					{'fileserver','dirresult',handle,result}
				)
			end
			return EVENT_CONSUME
		end,
		player:getId(),
		{'fileserver.dir'}
	)
	player:unsubscribe('/slim/fileserver.get')
	player:subscribe(
		'/slim/fileserver.get',
		function(chunk)
			local server = chunk.data[2]
			local secret = chunk.data[3]
			if server == System:getMacAddress() and secret == self.secret then
				local handle = chunk.data[4]
				local filename = chunk.data[5]
				if lfs.attributes(filename) then
					log:debug("Getting file: "..tostring(filename))
					local file = io.open(filename,"rb")
					if file then
						local content = file:read("*all")
						local encodedContent = mime.b64(content)
						server = player:getSlimServer()
						server:userRequest(function(chunk,err)
								if err then
									log:debug(err)
								end
							end,
							player and player:getId(),
							{'fileserver','getresult',handle,filename,encodedContent}
						)
					end
				end
			end
			return EVENT_CONSUME
		end,
		player:getId(),
		{'fileserver.get'}
	)
end

function notify_serverConnected(self,server)
	math.randomseed(os.time())
	self.secret = tostring(math.random(1000000))
	server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					server:userRequest(function(chunk,err)
							if err then
								log:warn(err)
							end
						end,
						player and player:getId(),
						{'fileserver','register',System:getMacAddress(),System:getMachine(),self.secret}
					)
				end
		end,
		nil,
		{'can','fileserver','register','?'}
	)
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


