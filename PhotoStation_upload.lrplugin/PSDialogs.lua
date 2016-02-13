--[[----------------------------------------------------------------------------

PSUploadExportDialogSections.lua
Export dialog customization for Lightroom PhotoStation Upload
Copyright(c) 2015, Martin Messmer

This file is part of PhotoStation Upload - Lightroom plugin.

PhotoStation Upload is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PhotoStation Upload is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PhotoStation Upload.  If not, see <http://www.gnu.org/licenses/>.

This code is derived from the Lr SDK FTP Upload sample code. Copyright: see below
--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]

-- Lightroom SDK
local LrBinding		= import 'LrBinding'
local LrView 		= import 'LrView'
local LrPathUtils 	= import 'LrPathUtils'
local LrFileUtils	= import 'LrFileUtils'
local LrShell 		= import 'LrShell'

require "PSUtilities"

local bind 				= LrView.bind
local share 			= LrView.share
local negativeOfKey 	= LrBinding.negativeOfKey
local conditionalItem 	= LrView.conditionalItem


--============================================================================--

PSDialogs = {}

--============================ validate functions ===========================================================

-------------------------------------------------------------------------------
-- validatePort: check if a string is numeric
function PSDialogs.validatePort( view, value )
	local message = nil
	
	if string.match(value, '(%d+)') ~= value then 
		message = LOC "$$$/PSUpload/ExportDialog/Messages/PortNotNumeric=Port must be numeric value."
		return false, value
	end
	
	return true, value
end

-------------------------------------------------------------------------------
-- validateDirectory: check if a given path points to a local directory
function PSDialogs.validateDirectory( view, path )
	local message = nil
	
	if LrFileUtils.exists(path) ~= 'directory' then 
		message = LOC "$$$/PSUpload/ExportDialog/Messages/SrcDirNoExist=Local path is not an existing directory."
		return false, path
	end
	
	return true, LrPathUtils.standardizePath(path)
end

-------------------------------------------------------------------------------
-- validateProgram: check if a given path points to a local program
function PSDialogs.validateProgram( view, path )
	if LrFileUtils.exists(path) ~= 'file'
	or getProgExt() and string.lower(LrPathUtils.extension( path )) ~= getProgExt() then
		return false, path
	end

	return true, LrPathUtils.standardizePath(path)	
end

-------------------------------------------------------------------------------
-- validatePSUploadProgPath:
--	check if a given path points to the root directory of the Synology PhotoStation Uploader tool 
--		we require the following converters that ship with the Uploader:
--			- ImageMagick/convert(.exe)
--			- ffmpeg/ffpmeg(.exe)
--			- ffpmpeg/qt-faststart(.exe)
function PSDialogs.validatePSUploadProgPath(view, path)
	local convertprog = 'convert'
	local ffmpegprog = 'ffmpeg'
	local qtfstartprog = 'qt-faststart'

	if getProgExt() then
		local progExt = getProgExt()
		convertprog = LrPathUtils.addExtension(convertprog, progExt)
		ffmpegprog = LrPathUtils.addExtension(ffmpegprog, progExt)
		qtfstartprog = LrPathUtils.addExtension(qtfstartprog, progExt)
	end
	
	if LrFileUtils.exists(path) ~= 'directory' 
	or not LrFileUtils.exists(LrPathUtils.child(LrPathUtils.child(path, 'ImageMagick'), convertprog))
	or not LrFileUtils.exists(LrPathUtils.child(LrPathUtils.child(path, 'ffmpeg'), ffmpegprog)) 
	or not LrFileUtils.exists(LrPathUtils.child(LrPathUtils.child(path, 'ffmpeg'), qtfstartprog)) then
		return false, path
	end

	return true, LrPathUtils.standardizePath(path)
end


--============================ views ===================================================================

-------------------------------------------------------------------------------
-- psUploaderProgView(f, propertyTable)
function PSDialogs.psUploaderProgView(f, propertyTable)
	return
        f:group_box {
			title	= 'Synology PhotoStation Uploader',
			fill_horizontal = 1,
			
    		f:row {
    			f:static_text {
    				title 			= LOC "$$$/PSUpload/PluginDialog/PSUPLOADTT=Enter the install path of 'Synology PhotoStation Uploader', if you want to generate thumbs locally or upload videos.\n" 
    			},
    		},
    
    		f:row {
    			f:static_text {
    				title 			= LOC "$$$/PSUpload/PluginDialog/PSUPLOAD=Synology PS Uploader:",
    				alignment 		= 'right',
    				width 			= share 'labelWidth',
    			},
    
    			f:edit_field {
    				truncation 		= 'middle',
    				immediate 		= true,
    				fill_horizontal = 0.8,
    				value 			= bind 'PSUploaderPath',
    				validate 		= PSDialogs.validatePSUploadProgPath,
    			},
    			
     			f:push_button {
    				title 			= LOC "$$$/PSUpload/PluginDialog/PSUploadDef=Default",
    				tooltip 		= LOC "$$$/PSUpload/PluginDialog/PSUploadDefTT=Set to Default.",
    				alignment 		= 'right',
    				fill_horizontal = 0.1,
    				action 			= function()
    					propertyTable.PSUploaderPath = PSConvert.defaultInstallPath
    				end,
    			},   			

    			f:push_button {
    				title 			= LOC "$$$/PSUpload/PluginDialog/PSUploadSearch=Search",
    				tooltip 		= LOC "$$$/PSUpload/PluginDialog/PSUploadSearchTT=Search Synology PhotoStation Uploader in Explorer/Finder.",
    				alignment 		= 'right',
    				fill_horizontal = 0.1,
    				action 			= function()
    					LrShell.revealInShell(getRootPath())
    				end,
    			},   			
    		},
    	}
end

-------------------------------------------------------------------------------
-- exiftoolProgView(f, propertyTable)
function PSDialogs.exiftoolProgView(f, propertyTable)
	return
        f:group_box {
   			title	= 'Exiftool',
			fill_horizontal = 1,
    			
    		f:row {
    			f:static_text {
    				title			= LOC "$$$/PSUpload/PluginDialog/exiftoolprogTT=Enter the install path of 'exiftool', if you want to use metadata translations (face regions, color labels, ratings).\n" 
    			},
    		},
    
    		f:row {
    			f:static_text {
    				title 			= LOC "$$$/PSUpload/PluginDialog/exiftoolprog=exiftool:",
    				alignment 		= 'right',
    				width 			= share 'labelWidth',
    			},
    
    			f:edit_field {
    				truncation 		= 'middle',
    				immediate 		= true,
    				fill_horizontal = 0.8,
    				value 			= bind 'exiftoolprog',
    				validate 		= PSDialogs.validateProgram,
    			},

    			f:push_button {
    				title 			= LOC "$$$/PSUpload/PluginDialog/exiftoolprogDef=Default",
    				tooltip 		= LOC "$$$/PSUpload/PluginDialog/exiftoolprogDefTT=Set to default.",
    				alignment 		= 'right',
    				fill_horizontal = 0.1,
    				action 			= function()
    					propertyTable.exiftoolprog = PSExiftoolAPI.defaultInstallPath
    				end,
    			},   			

    			f:push_button {
    				title 			= LOC "$$$/PSUpload/PluginDialog/exiftoolprogSearch=Search",
    				tooltip 		= LOC "$$$/PSUpload/PluginDialog/exiftoolprogSearchTT=Search exiftool in Explorer/Finder.",
    				alignment 		= 'right',
    				fill_horizontal = 0.1,
    				action 			= function()
    					LrShell.revealInShell(getRootPath())
    				end,
    			},   			
    		},
    	}
end

-------------------------------------------------------------------------------
-- targetPhotoStationView(f, propertyTable)
function PSDialogs.targetPhotoStationView(f, propertyTable)
	local protocolItems = {
        { title	= 'http',   value 	= 'http' },
		{ title	= 'https',	value 	= 'https' },
	}
	
	local timeoutItems = {
		{ title	= '10s',	value 	= 10 },
		{ title	= '20s',	value 	= 20 },
		{ title	= '30s',	value 	= 30 },
		{ title	= '40s',	value 	= 40 },
		{ title	= '50s',	value 	= 50 },
		{ title	= '60s',	value 	= 60 },
		{ title	= '70s',	value 	= 70 },
		{ title	= '80s',	value 	= 80 },
		{ title	= '90s',	value 	= 90 },
		{ title	= '100s',	value 	= 100 },
	}

	return
        f:group_box {
        	fill_horizontal = 1,
        	title = LOC "$$$/PSUpload/ExportDialog/TargetPS=Target PhotoStation",
        
        	f:row {
        		f:radio_button {
        			title 			= LOC "$$$/PSUpload/ExportDialog/SERVERNAME=Server Address:",
        			alignment 		= 'right',
        			width 			= share 'labelWidth',
        			value 			= bind 'useSecondAddress',
        			checked_value	= false,
        		},
        
        		f:popup_menu {
        			title 			= LOC "$$$/PSUpload/ExportDialog/PROTOCOL=Protocol:",
        			items 			= protocolItems,
        			value 			= bind 'proto',
        			enabled 		= negativeOfKey 'useSecondAddress',
        		},
        
        		f:edit_field {
        			tooltip 		= LOC "$$$/PSUpload/ExportDialog/SERVERNAMETT=Enter the IP address or hostname of the PhotoStation.\n" .. 
        								"Non-standard port may be appended as :port",
        			truncation 		= 'middle',
        			immediate 		= true,
        			fill_horizontal = 1,
        			value 			= bind 'servername',
        			enabled 		= negativeOfKey 'useSecondAddress',
        		},
        
        		f:row {
        			alignment 		= 'right',
        			fill_horizontal = 0.5,
        
        			f:static_text {
        				title 		= LOC "$$$/PSUpload/ExportDialog/ServerTimeout=Timeout:",
        				alignment 	= 'right',
        			},
        
        			f:popup_menu {
        				tooltip 		= LOC "$$$/PSUpload/ExportDialog/ServerTimeoutTT=HTTP(S) connect timeout, recommended value: 10s\n".. 
        									"use higher value (>= 40s), if you experience problems due to disks in standby mode",
        				items 			= timeoutItems,
        				alignment 		= 'left',
        				fill_horizontal = 1,
        				value 			= bind 'serverTimeout',
        				enabled 		= negativeOfKey 'useSecondAddress',
        			},
        		},
        	}, 
        	
        	f:row {
        		f:radio_button {
        			title 			= LOC "$$$/PSUpload/ExportDialog/SERVERNAME2=Second Server Address:",
        			alignment 		= 'right',
        			width 			= share 'labelWidth',
        			value 			= bind 'useSecondAddress',
        			checked_value 	= true,
        		},
        
        		f:popup_menu {
        			title 			= LOC "$$$/PSUpload/ExportDialog/PROTOCOL2=Protocol:",
        			items			= protocolItems,
        			value 			= bind 'proto2',
        			enabled 		= bind 'useSecondAddress',
        		},
        
        		f:edit_field {
        			tooltip 		= LOC "$$$/PSUpload/ExportDialog/SERVERNAME2TT=Enter the secondary IP address or hostname.\n" .. 
        								"Non-standard port may be appended as :port",
        			truncation 		= 'middle',
        			immediate 		= true,
        			fill_horizontal = 1,
        			value 			= bind 'servername2',
        			enabled 		= bind 'useSecondAddress',
        		},
        
        		f:row {
        			alignment 		= 'right',
        			fill_horizontal = 0.5,
        
        			f:static_text {
        				title 		= LOC "$$$/PSUpload/ExportDialog/ServerTimeout=Timeout:",
        				alignment 	= 'right',
        			},
        
        			f:popup_menu {
        				tooltip 		= LOC "$$$/PSUpload/ExportDialog/ServerTimeoutTT=HTTP(S) connect timeout, recommended value: 10s\n" .. 
        										"use higher value (>= 40s), if you experience problems due to disks in standby mode",
        				items 			= timeoutItems,
        				alignment 		= 'left',
        				fill_horizontal = 1,
        				value 			= bind 'serverTimeout2',
        				enabled 		= bind 'useSecondAddress',
        			},
        		},
        	},

			f:separator { fill_horizontal = 1 },

			f:row {
				f:radio_button {
					title 			= LOC "$$$/PSUpload/ExportDialog/StandardPS=Standard PhotoStation",
					alignment 		= 'left',
					width 			= share 'labelWidth',
					value 			= bind 'usePersonalPS',
					checked_value 	= false,
				},

				f:radio_button {
					title 			= LOC "$$$/PSUpload/ExportDialog/PersonalPS=Personal PhotoStation of User:",
					alignment 		= 'left',
					value 			= bind 'usePersonalPS',
					checked_value 	= true,
				},

				f:edit_field {
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/PersonalPSTT=Enter the name of the owner of the Personal PhotoStation you want to upload to.",
					truncation 		= 'middle',
					immediate 		= true,
					fill_horizontal = 1,
					value 			= bind 'personalPSOwner',
					enabled 		= bind 'usePersonalPS',
					visible 		= bind 'usePersonalPS',
				},
			},

			f:row {
				f:static_text {
					title 			= LOC "$$$/PSUpload/ExportDialog/USERNAME=PhotoStation Login:",
					alignment 		= 'right',
					width 			= share 'labelWidth'
				},
	
				f:edit_field {
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/USERNAMETT=Enter the username for PhotoStation access.",
					truncation 		= 'middle',
					immediate 		= true,
					fill_horizontal = 1,
					value 			= bind 'username',
				},

				f:static_text {
					title 			= LOC "$$$/PSUpload/ExportDialog/PASSWORD=Password:",
					alignment 		= 'right',
				},
	
				f:password_field {
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/PASSWORDTT=Enter the password for PhotoStation access.\nLeave this field blank, if you don't want to store the password.\nYou will be prompted for the password later.",
					truncation 		= 'middle',
					immediate 		= true,
					fill_horizontal = 1,
					value 			= bind 'password',
				},
			},
		}
end

-------------------------------------------------------------------------------
-- thumbnailOptionsView(f, propertyTable)
function PSDialogs.thumbnailOptionsView(f, propertyTable)
	local thumbQualityItems = {
		{ title	= '10%',	value 	= 10 },
		{ title	= '20%',	value 	= 20 },
		{ title	= '30%',	value 	= 30 },
		{ title	= '40%',	value 	= 40 },
		{ title	= '50%',	value 	= 50 },
		{ title	= '60%',	value 	= 60 },
		{ title	= '70%',	value 	= 70 },
		{ title	= '80%',	value 	= 80 },
		{ title	= '90%',	value 	= 90 },
		{ title	= '100%',	value 	= 100 },
	}
	
	local thumbSharpnessItems = {
		{ title	= 'None',	value 	= 'None' },
		{ title	= 'Low',	value 	= 'LOW' },
		{ title	= 'Medium',	value 	= 'MED' },
		{ title	= 'High',	value 	= 'HIGH' },
	}
	
	return
		f:group_box {
			title 			= LOC "$$$/PSUpload/ExportDialog/Thumbnails=Thumbnail Options",
			fill_horizontal = 1,

			f:row {
				f:checkbox {
					title 			= LOC "$$$/PSUpload/ExportDialog/thumbGenerate=Do thumbs:",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/thumbGenerateTT=Generate thumbs:\nUnselect only, if you want the diskstation to generate the thumbs\n" .. 
											"or if you export to an unindexed folder and you don't need thumbs.\n" .. 
											"This will speed up photo uploads.",
					fill_horizontal = 1,
					value 			= bind 'thumbGenerate',
				},

				f:checkbox {
					title 			= LOC "$$$/PSUpload/ExportDialog/isPS6=For PS 6",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/isPS6TT=PhotoStation 6: Do not generate and upload Thumb_L",
					fill_horizontal = 1,
					value 			= bind 'isPS6',
					visible 		= bind 'thumbGenerate',
				},

				f:row {
					fill_horizontal = 1,

					f:radio_button {
						title 			= LOC "$$$/PSUpload/ExportDialog/SmallThumbs=Small",
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/SmallThumbsTT=Recommended for output on low-resolution monitors",
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'largeThumbs',
						checked_value 	= false,
						visible 		= bind 'thumbGenerate',
					},

					f:radio_button {
						title 			= LOC "$$$/PSUpload/ExportDialog/LargeThumbs=Large",
						tooltip			= LOC "$$$/PSUpload/ExportDialog/LargeThumbsTT=Recommended for output on Full HD monitors",
						alignment 		= 'right',
						fill_horizontal = 1,
						value 			= bind 'largeThumbs',
						checked_value 	= true,
						visible 		= bind 'thumbGenerate',
					},
				},
				
				f:row {
					alignment 		= 'right',
					fill_horizontal = 1,

					f:static_text {
						title	 	= LOC "$$$/PSUpload/ExportDialog/ThumbQuality=Quality:",
						alignment 	= 'right',
						visible 	= bind 'thumbGenerate',
					},

					f:popup_menu {
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/QualityTT=Thumb conversion quality, recommended value: 80%",
						items 			= thumbQualityItems,
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'thumbQuality',
						visible 		= bind 'thumbGenerate',
					},
				},

				f:row {
					alignment 		= 'right',
					fill_horizontal = 1,

					f:static_text {
						title 		= LOC "$$$/PSUpload/ExportDialog/ThumbSharpness=Sharpening:",
						alignment	= 'right',
						visible 	= bind 'thumbGenerate',
					},

					f:popup_menu {
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/ThumbSharpnessTT=Thumbnail sharpening, recommended value: Medium",
						items 			= thumbSharpnessItems,
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'thumbSharpness',
						visible 		= bind 'thumbGenerate',
					},
				},
			},
		}
end

-------------------------------------------------------------------------------
-- videoOptionsView(f, propertyTable)
function PSDialogs.videoOptionsView(f, propertyTable)
	local highResAddVideoItens	= {
		{ title	= 'None',			value 	= 'None' },
		{ title	= 'Mobile (240p)',	value 	= 'MOBILE' },
		{ title	= 'Low (360p)',		value 	= 'LOW' },
		{ title	= 'Medium (720p)',	value 	= 'MEDIUM' },
	}

	local medResAddVideoItens	= {
		{ title	= 'None',			value 	= 'None' },
		{ title	= 'Mobile (240p)',	value 	= 'MOBILE' },
		{ title	= 'Low (360p)',		value 	= 'LOW' },
	}
	
	local lowResAddVideoItens	= {
		{ title	= 'None',			value 	= 'None' },
		{ title	= 'Mobile (240p)',	value 	= 'MOBILE' },
	}
	
	return
		f:group_box {
			title 			= LOC "$$$/PSUpload/ExportDialog/Videos=Video Upload Options: Additional video resolutions for ...-Res Videos",
			fill_horizontal = 1,

			f:row {
				f:row {
					alignment = 'left',
					fill_horizontal = 1,

					f:static_text {
						title 			= LOC "$$$/PSUpload/ExportDialog/VideoHigh=High:",
						alignment 		= 'right',
					},
					
					f:popup_menu {
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/VideoHighTT=Generate additional video for Hi-Res (1080p) videos",
						items 			= highResAddVideoItens,
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'addVideoHigh',
					},
				},					

				f:row {
					alignment 			= 'right',
					fill_horizontal 	= 1,

					f:static_text {
						title 			= LOC "$$$/PSUpload/ExportDialog/VideoMed=Medium:",
						alignment 		= 'right',
					},
					
					f:popup_menu {
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/VideoMedTT=Generate additional video for Medium-Res (720p) videos",
						items 			= medResAddVideoItens,
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'addVideoMed',
					},
				},					

				f:row {
					alignment 			= 'right',
					fill_horizontal 	= 1,

					f:static_text {
						title 			= LOC "$$$/PSUpload/ExportDialog/VideoLow=Low:",
						alignment 		= 'right',
					},
					
					f:popup_menu {
						tooltip 		= LOC "$$$/PSUpload/ExportDialog/VideoLowTT=Generate additional video for Low-Res (360p) videos",
						items 			= lowResAddVideoItens,
						alignment 		= 'left',
						fill_horizontal = 1,
						value 			= bind 'addVideoLow',
					},
				},					
				
				f:checkbox {
					title 			= LOC "$$$/PSUpload/ExportDialog/hardRotate=Use hard-rotation",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/hardRotateTT=Use hard-rotation for better player compatibility,\nwhen a video is soft-rotated or meta-rotated\n(keywords include: 'Rotate-90', 'Rotate-180' or 'Rotate-270')",
					alignment 		= 'left',
					fill_horizontal = 1,
					value 			= bind 'hardRotate',
				},
			},
		}
end

-------------------------------------------------------------------------------
-- dstRootView(f, propertyTable)
--
function PSDialogs.dstRootView(f, propertyTable, isAskForMissingParams)
	return 
		f:row {
--			fill_horizontal = 1,

			iif(isAskForMissingParams or propertyTable.isCollection,
    			f:static_text {
    				title 		= LOC "$$$/PSUpload/ExportDialog/StoreDstRoot=Target Album:",
    				alignment 	= 'right',
    				width 		= share 'labelWidth'
    			},
				-- else
				f:checkbox {
    				title 		= LOC "$$$/PSUpload/ExportDialog/StoreDstRoot=Target Album:",
    				tooltip 	= LOC "$$$/PSUpload/ExportDialog/StoreDstRootTT=Enter Target Album here or you will be prompted for it when the upload starts.",
    				alignment 	= 'right',
    				width 		= share 'labelWidth',
    				value 		= bind 'storeDstRoot',
    				enabled 	=  negativeOfKey 'isCollection',
				}
			),

			f:edit_field {
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/DstRootTT=Enter the target directory below the diskstation share '/photo' or '/home/photo'\n" .. 
									"(may be different from the Album name shown in PhotoStation)",
				truncation 		= 'middle',
				width_in_chars 	= 16,
				immediate 		= true,
				fill_horizontal = 1,
				value 			= bind 'dstRoot',
				enabled 		= iif(isAskForMissingParams, true, bind 'storeDstRoot'),
				visible 		= iif(isAskForMissingParams, true, bind 'storeDstRoot'),
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/createDstRoot=Create Album, if needed",
				alignment 		= 'left',
				fill_horizontal = 1,
				value 			= bind 'createDstRoot',
				enabled 		= iif(isAskForMissingParams, true, bind 'storeDstRoot'),
				visible 		= iif(isAskForMissingParams, true, bind 'storeDstRoot'),
			},
		}

end

-------------------------------------------------------------------------------
-- targetAlbumView(f, propertyTable)
--
function PSDialogs.targetAlbumView(f, propertyTable)
	return f:view {
		fill_horizontal = 1,

		f:group_box {
			title 			= LOC "$$$/PSUpload/ExportDialog/TargetAlbum=Target Album and Upload Method",
			fill_horizontal = 1,

			PSDialogs.dstRootView(f, propertyTable), 

			f:row {

				f:radio_button {
					title 			= LOC "$$$/PSUpload/ExportDialog/FlatCp=Flat Copy to Target",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/FlatCpTT=All photos/videos will be copied to the Target Album",
					alignment 		= 'right',
					width 			= share 'labelWidth',
					value 			= bind 'copyTree',
					checked_value 	= false,
				},

				f:radio_button {
					title 			= LOC "$$$/PSUpload/ExportDialog/CopyTree=Mirror Tree relative to local Path:",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/CopyTreeTT=All photos/videos will be copied to a mirrored directory below the Target Album",
					alignment 		= 'left',
					value 			= bind 'copyTree',
					checked_value 	= true,
				},

				f:edit_field {
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/CopyTreeTT=Enter the local path that is the root of the directory tree you want to mirror below the Target Album.",
					truncation 		= 'middle',
					immediate 		= true,
					fill_horizontal = 1,
					value 			= bind 'srcRoot',
					validate 		= PSDialogs.validateDirectory,
					enabled 		= bind 'copyTree',
					visible 		= bind 'copyTree',
				},
			},

			f:separator { fill_horizontal = 1 },

			f:row {
				f:checkbox {
					title 			= LOC "$$$/PSUpload/ExportDialog/RAWandJPG=RAW+JPG to same Album",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/RAWandJPGTT=Allow Lr-developed RAW+JPG from camera to be uploaded to same Album.\n" ..
											"Note: All Non-JPEG photos will be renamed in PhotoStation to <photoname>_<OrigExtension>.<OutputExtension>. E.g.:\n" ..
											"IMG-001.RW2 --> IMG-001_RW2.JPG\n" .. 
											"IMG-001.JPG --> IMG-001.JPG",
					alignment 		= 'left',
					fill_horizontal = 1,
					value 			= bind 'RAWandJPG',
				},

				f:checkbox {
					title 			= LOC "$$$/PSUpload/ExportDialog/SortPhotos=Sort Photos",
					tooltip 		= LOC "$$$/PSUpload/ExportDialog/SortPhotosTT=Sort photos in PhotoStation according to sort order of Published Collection.\n" ..
											"Note: Sorting is not possible for dynamic Target Albums (including metadata placeholders)\n",
					alignment 		= 'left',
					fill_horizontal = 1,
					value 			= bind 'sortPhotos',
					enabled 		= negativeOfKey 'copyTree',
				},	
			},
		},
	} 
end	

-------------------------------------------------------------------------------
-- uploadOptionsView(f, propertyTable)
function PSDialogs.uploadOptionsView(f, propertyTable)
	return	f:group_box {
		fill_horizontal = 1,
		title = LOC "$$$/PSUpload/ExportDialog/UploadOpt=Metadata Upload Options /Translations (To PhotoStation)",

		f:row {
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/exifTranslate=Translate Tags:",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/exifTranslateTT=Translate Lightroom tags to PhotoStation tags",
				fill_horizontal = 1,
				value 			= bind 'exifTranslate',
			},
		
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/exifXlatFaceRegions=Faces",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/exifXlatFaceRegionsTT=Translate Lightroom or Picasa Face Regions to PhotoStation Person Tags",
				fill_horizontal = 1,
				value 			= bind 'exifXlatFaceRegions',
				visible 		= bind 'exifTranslate',
			},
		
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/exifXlatLabel=Color Label",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/exifXlatLabelTT=Translate Lightroom color label (red, green, ...) to PhotoStation General Tag '+color'",
				fill_horizontal = 1,
				value 			= bind 'exifXlatLabel',
				visible 		= bind 'exifTranslate',
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/exifXlatRating=Rating",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/exifXlatRatingTT=Translate Lightroom (XMP) rating (*stars*) to PhotoStation General Tag '***'",
				fill_horizontal = 1,
				value 			= bind 'exifXlatRating',
				visible 		= bind 'exifTranslate',
			},
		},
		
		f:row {
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/CommentsUpload=Comments (always uploaded)",
				fill_horizontal = 1,
				value 			= true,
				enabled 		= false,
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/CaptionUpload=Decription (always uploaded)",
				fill_horizontal = 1,
				value 			= true,
				enabled 		= false,
			},

		}, 
		
--		PSDialogs.exiftoolProgView(f, propertyTable),
	}

end

-------------------------------------------------------------------------------
-- downloadOptionsView(f, propertyTable)
function PSDialogs.downloadOptionsView(f, propertyTable)
	return	f:group_box {
		fill_horizontal = 1,
		title = LOC "$$$/PSUpload/ExportDialog/DownloadOpt=Metadata Download Options / Translations  (From PhotoStation)",

		f:row {
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/TagsDownload=Tags",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/TagsDownloadTT=Download tags from PhotoStation",
				fill_horizontal = 1,
				value 			= bind 'tagsDownload',
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/PS2LrNotSupp=Faces (no support)",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/PS2LrNotSuppTT=Download of faces from PhotoStation not supported",
				fill_horizontal = 1,
				value 			= false,
				enabled 		= false,
				visible 		= bind 'tagsDownload',
			},

-- no way to set face regions in Lr
--[[
			f:checkbox {
				fill_horizontal = 1,
				title = LOC "$$$/PSUpload/ExportDialog/PS2LrFaces=Faces",
				tooltip = LOC "$$$/PSUpload/ExportDialog/PS2LrFacesTT=Translate PhotoStation People Tag to Lightroom Faces",
				value = bind 'PS2LrFaces',
				enabled = bind 'exifXlatFaceRegions',
				visible = bind 'tagsDownload',
			},
]]
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/PS2LrLabel=Color Label",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/PS2LrLabelTT=Translate PhotoStation General Tag '+color' to Lightroom color label (red, green, ...)",
				fill_horizontal = 1,
				value 			= bind 'PS2LrLabel',
				enabled 		= bind 'exifXlatLabel',
				visible 		= bind 'tagsDownload',
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/PS2LrRating=Rating",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/PS2LrRatingTT=Translate PhotoStation general tag '***' to Lightroom rating",
				fill_horizontal = 1,
				value 			= bind 'PS2LrRating',
				enabled 		= bind 'exifXlatRating',
				visible 		= bind 'tagsDownload',
			},
		},
		
		f:row {
			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/CommentsDownload=Comments",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/commentsDownloadTT=Download comments from PhotoStation",
				fill_horizontal = 1,
				value 			= bind 'commentsDownload',
			},

			f:checkbox {
				title 			= LOC "$$$/PSUpload/ExportDialog/CaptionDownload=Description",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/CaptionDownloadTT=Download description (caption) from PhotoStation",
				fill_horizontal = 1,
				value 			= bind 'captionDownload',
			},
		},
	}
end

-------------------------------------------------------------------------------
-- publishModeView(f, propertyTable, isAskForMissingParams)
function PSDialogs.publishModeView(f, propertyTable, isAskForMissingParams)
	local publishModeItems = {
		{ title	= 'Ask me later',																value 	= 'Ask' },
		{ title	= 'Normal',																		value 	= 'Publish' },
		{ title	= 'CheckExisting: Set Unpublished to Published if existing in PhotoStation.',	value 	= 'CheckExisting' },
		{ title	= 'CheckMoved: Set Published to Unpublished if moved locally.',					value 	= 'CheckMoved' },
	}
	
	if isAskForMissingParams then
		table.remove(publishModeItems, 1)
	end

    return
		f:row {
			alignment 		= 'left',
			fill_horizontal = 1,

			f:static_text {
				title		= LOC "$$$/PSUpload/CollectionSettings/PublishMode=Publish Mode:",
				alignment 	= 'right',
				width 		= share 'labelWidth',
			},

			f:popup_menu {
				tooltip 		= LOC "$$$/PSUpload/CollectionSettings/PublishModeTT=How to publish",
				items 			= publishModeItems,
				alignment 		= 'left',
--				fill_horizontal = 1,
				value 			= bind 'publishMode',
			},
		}
end

-------------------------------------------------------------------------------
-- loglevelView(f, propertyTable, isAskForMissingParams)
function PSDialogs.loglevelView(f, propertyTable, isAskForMissingParams)
	local loglevelItems = {
		{ title	= 'Ask me later',	value 	= 9999 },
		{ title	= 'Nothing',		value 	= 0 },
		{ title	= 'Errors',			value 	= 1 },
		{ title	= 'Normal',			value 	= 2 },
		{ title	= 'Trace',			value 	= 3 },
		{ title	= 'Debug',			value 	= 4 },
	}
	
	if isAskForMissingParams then
		table.remove(loglevelItems, 1)
	end

	return 
		f:row {
			f:static_text {
				title 			= LOC "$$$/PSUpload/ExportDialog/LOGLEVEL=Loglevel:",
				alignment 		= 'right',
				width			= share 'labelWidth'
			},

			f:popup_menu {
				title 			= LOC "$$$/PSUpload/ExportDialog/LOGLEVEL=Loglevel:",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/LOGLEVELTT=The level of log details",
				items 			= loglevelItems,		
				fill_horizontal = 0, 
				value 			= bind 'logLevel',
			},
			
			f:spacer {
				fill_horizontal = 1,
			},
			
			f:push_button {
				title 			= LOC "$$$/PSUpload/ExportDialog/Logfile=Go to Logfile",
				tooltip 		= LOC "$$$/PSUpload/ExportDialog/LogfileTT=Open PhotoStation Upload Logfile in Explorer/Finder.",
				alignment 		= 'right',
				fill_horizontal = 1,
				action 			= function()
					LrShell.revealInShell(getLogFilename())
				end,
			},
		} 
end