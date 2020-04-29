/***********************************************************************************************************************************
 *
 *	WMFileListingDataSource.h
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
#import <Foundation/Foundation.h>

#define	WMListingCacheLimitKey		@"WMListingCacheLimit"

#define WMInvalidFileImage		@"UnknownFile"
#define WMDirectoryImage		@"Folder"
#define WMDirectoryOpenImage		@"OpenFolder"
#define WMHomeFolderImage		@"HomeFolder"
#define WMHomeFolderOpenImage		@"OpenHome"
#define WMNeighborFolderImage		@"NeighborFolder"
#define WMBundleImage			@"Folder"
#define WMFontBundleImage		@"FontBundle"
#define WMSoundBundleImage		@"SoundBundle"
#define WMServiceBundleImage		@"ServiceBundle"
#define WMFontImage			@"Font"
#define WMWavSoundImage			@"SoundWav"
#define WMVocSoundImage			@"SoundVoc"
#define WMSndSoundImage			@"SoundSnd"
#define WMAuSoundImage			@"SoundAu"
#define WMToolImage			@"Tool"
#define WMFileImage			@"TextFile"
#define WMMultipleSelectionImage	@"MultipleSelection"

typedef enum {
	WMInvalidFile = 0,	// 00_ Not a file, used for initialisation of variables of this type or to indicate it doesn't exist.
	WMDirectory,		// 01_ Folder.
	WMHomeFolder,		// 02_ The current user's home directory.
	WMNeighborFolder,	// 03_ The home Directory of another user.
	WMBundle,		// 04_ Generic bundles (.bundle directories).
	WMFontBundle,		// 05_ Font bundles (.font and .nfont bundles).
	WMSoundBundle,		// 06_ Backend sound plugin bundles (.nsound bundles).
	WMServiceBundle,	// 07_ Standalone service bundles (.service bundles, located in *Library/Services).
	WMDocumentBundle,	// 08_ app-specific bundles (e.g. rtfd).
	WMAppBundle,		// 09_ Application bundle.
	WMFont,			// 10_ Known font files (afm, pfb, pfm, ttf, otf, etc).)
	WMSound,		// 11_ Known sound files (wav, voc, au, snd, etc).
	WMImage,		// 12_ Known image files (tiff, png, jpg, gif, etc).
	WMDocument,		// 13_ Single file document (i.e. is handled by at least one app).
	WMTool,			// 14_ Regular (i.e. a non-directory) file that is marked as executable.
	WMFile			// 15_ Other files (check apps for them, or generic file).
} WMFileType;

@interface WMFileListingDataSource : NSObject {
	NSMutableDictionary	* listingCache,
				* typeCache;
	NSMutableArray		* listingCacheAger,
				* typeCacheAger;
}

+ (WMFileListingDataSource *) defaultFileListingDataSource;
- (NSArray *) fileListingForPath: (NSString *) path;
- (WMFileType) typeOfFile: (NSString *) path;
- (NSImage *) iconForFile: (NSString *) path ofType: (WMFileType) type;
- (BOOL) isDirectory: (NSString *) path;
- (void) reloadPath: (NSString *) path;

@end
