####################################################################################################################################
#
#	GNUmakefile
#
#	This file is an part of the Mondo Workspace Manager.
#
#	Copyright (C) 2020 Mondo Megagames.
# 	Author: Jamie Ramone <sancombru@gmail.com>
#	Date: 20-4-2020
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If not, see
# <http://www.gnu.org/licenses/>
#
####################################################################################################################################
GNUSTEP_INSTALLATION_DIR=/aux/lib/GNUstep

include uncommon.make

PACKAGE_NAME = MondoWorkspaceManager
VERSION = 1.0
COMPRESSION_PROGRAM = xz -9
COMPRESSION_EXT = .xz

APP_NAME = WM

WM_RESOURCE_FILES = $(wildcard Resources/*[^~].*)
WM_HEADER_FILES = $(wildcard *.h)
WM_OBJC_FILES = $(wildcard *.m)

SUBPROJECTS = Recycler

#-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
