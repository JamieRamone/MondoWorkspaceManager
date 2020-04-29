/***********************************************************************************************************************************
 *
 *	WM.h
 *
 * This file is an part of the Mondo Workspace Manager.
 *
 *	Copyright (C) 2020 Mondo Megagames.
 * 	Author: Jamie Ramone <sancombru@gmail.com>
 *	Date: 20-4-2020
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program. If not, see
 * <http://www.gnu.org/licenses/>
 *
 **********************************************************************************************************************************/
#define WMDefaultEditorApplication		@"TextEdit"
#define WMDefaultTerminalApplication		@"Terminal"

#define WMIconGridUserPresetsKey		@"IconGridPresets"

#define WMIconGridFirstColumnLeftKey		@"0"
#define WMIconGridFirstColumnTopKey		@"1"
#define WMIconGridSecondColumnLeftKey		@"2"
#define WMIconGridSecondColumnTopKey		@"3"
#define WMIconGridInterlineSpacingKey		@"4"
#define WMIconGridLinesPerNameKey		@"5"
#define WMIconGridNameWidthKey			@"6"

#define WMFileSystemDidChangeNotification	@"WMFileSystemDidChangeNotification"

@interface WM : NSObject {
	NSMutableDictionary	* runningAppsDatabase;
	NSString		* trashDirectory;
}

+ (WM *) workspaceManager;

- (NSString *) trashDirectory;

- (NSDictionary *) iconGridSettings;
- (void) commitIconGridSettings: (NSDictionary *) settings;

- (NSString *) createNewDirectoryAt: (NSString *) path;
- (void) deleteFiles: (NSArray *) files;
- (void) emptyRecycler;
- (void) moveFiles: (NSArray *) files toPath: (NSString *) path;
- (void) copyFiles: (NSArray *) files intoPath: (NSString *) path;
- (void) linkFiles: (NSArray *) files intoPath: (NSString *) path;

- (void) openApplication: (NSString *) application;
- (void) openDocument: (NSString *) document;
- (void) openDocument: (NSString *) document withApplication: (NSString *) application;
- (NSArray *) appsForDocumentType: (NSString *) type;

@end
