/***********************************************************************************************************************************
 *
 *	WMFileListingDataSource.m
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
#import <AppKit/AppKit.h>

#import "aux.h"
#import "NSString+Additions.h"
#import "NSArray+Additions.h"
#import "WMFileListingDataSource.h"

#define WMListingCache	@"WMListingCache"
#define WMPathCache	@"WMPathCache"

@interface WMFileListingDataSource (Private)

+ (NSArray *) _listOfFilesToExcludeFromPath: (NSString *) path;
+ (NSArray *) _filterFileListing: (NSArray *) listing atPath: (NSString *) path;
- (void) _clearCacheLine;
- (NSArray *) _loadPathListingIntoCache: (NSString *) path;
- (void) _finishInitializing;

@end

@implementation WMFileListingDataSource (Private)

+ (NSArray *) _listOfFilesToExcludeFromPath: (NSString *) path
{
	register NSString	* listOfFilesToExclude = nil;
	register NSArray	* result = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	listOfFilesToExclude = [NSString stringWithContentsOfFile: [NSString stringWithFormat: @"%@/.hidden", path]];
	criteria = ( listOfFilesToExclude != nil && [listOfFilesToExclude length] != 0 );
	selector = Choose ( criteria, @selector ( componentsSeparatedByString: ), @selector ( nop ));
	method = objc_msg_lookup ( listOfFilesToExclude, selector );
	result = method ( listOfFilesToExclude, selector, @"\n" );
	//NSLog ( @"Contents of .hidden: %@.", result );

	return result;
};

+ (NSArray *) _filterFileListing: (NSArray *) listing atPath: (NSString *) path
{
	register NSMutableArray	* result = nil;
	register NSUserDefaults	* defaults = nil;
	register NSDictionary	* domain = nil;
	register NSNumber	* entry = nil;
	register void		* target = NULL;
	register BOOL		criteria = NO;

	defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	domain = [defaults persistentDomainForName: NSGlobalDomain];
	entry = [domain objectForKey: @"GSFileBrowserHideDotFiles"];
	criteria = [entry boolValue];
	target = Choose ( criteria, && hide, && leave );
	goto * target;
/*
 * If the UNIX expert setting was enabled in the preferences application, then we obtain a new listing filtering out the so-called
 * "dot-files" and then check for a '.hidden' file in the path specified in the parameter, which should correspond to the directory
 * holding the files given in the listing, and also remove those listed in it.
 */
hide:	//NSLog ( @"GSFileBrowserHideDotFiles set, hiding dot files and those listed in .hidden." );
	result = [NSMutableArray arrayWithArray: [listing filteredArrayUsingSelector: @selector ( isNotDotFile )]];
	[result removeObjectsInArray: [WMFileListingDataSource _listOfFilesToExcludeFromPath: path]];
	//NSLog ( @"Filtered files: %@.", result );
	goto out;
leave:	//NSLog ( @"GSFileBrowserHideDotFiles not set." );
	result = (NSMutableArray *) listing;

out:	return result;
};

- (void) _clearCacheLine
{
	register NSString	* key = nil;

	key = [listingCacheAger firstObject];
	[listingCache removeObjectForKey: key];
	[listingCacheAger removeObjectAtIndex: 0];
};

- (NSArray *) _loadPathListingIntoCache: (NSString *) path
{
	register NSArray	* result = nil;
	register NSFileManager	* fileManager = nil;
	register void		* target = NULL;
	register NSInteger	capacity = -1;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;

	fileManager = [NSFileManager defaultManager];
	result = [fileManager directoryContentsAtPath: path];
	criteria = ( result != nil );
	target = Choose ( criteria, && in, && out );
	goto * target;
in:	[NSString setCurrentPath: path];
	result = [result sortedArrayUsingSelector: @selector ( fileTypeCompare: )];
	capacity = [[NSUserDefaults standardUserDefaults] integerForKey: WMListingCacheLimitKey];
	criteria = ( [listingCache count] == capacity );
	selector = Choose ( criteria, @selector ( _clearCacheLine ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );
	[listingCacheAger addObject: path];
	[listingCache setObject: result forKey: path];

out:	return result;
};

- (void) _finishInitializing
{
	register int	capacity = -1;

	capacity = [[NSUserDefaults standardUserDefaults] integerForKey: WMListingCacheLimitKey];
	capacity = Choose ( capacity == 0 , 256, capacity );
	[[NSUserDefaults standardUserDefaults] setInteger: capacity forKey: WMListingCacheLimitKey];
	listingCache = [NSMutableDictionary dictionaryWithCapacity: capacity];
	typeCache = [NSMutableDictionary dictionaryWithCapacity: capacity];
	listingCacheAger = [NSMutableArray arrayWithCapacity: capacity];
	typeCacheAger = [NSMutableArray arrayWithCapacity: capacity];
	[listingCache retain];
	[typeCache retain];
	[listingCacheAger retain];
	[typeCacheAger retain];
};

@end

@implementation WMFileListingDataSource

static WMFileListingDataSource	* _sharedFileListingDataSourceInstance = nil;

+ (WMFileListingDataSource *) defaultFileListingDataSource
{
	register WMFileListingDataSource	* result = nil;

	if ( _sharedFileListingDataSourceInstance == nil ) {
		_sharedFileListingDataSourceInstance = [WMFileListingDataSource new];
	}

	result = _sharedFileListingDataSourceInstance;

	return result;
};

- (NSArray *) fileListingForPath: (NSString *) path
{
	register NSArray	* result = nil,
				* intermediate = nil;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	register BOOL		criteria = NO;
/*
 * 1. Check the listing cache for the path. If found, return that.
 *
 * 2. If not found, load listing it from disk.
 *
 * 3. If the cache is full, look for the oldest entry in the path cache and evict it.
 *
 * 4. Insert new entry into the listing cache and the path cache.
 */
	result = [listingCache objectForKey: path];
	criteria = ( result == nil );
	selector = Choose ( criteria, @selector ( _loadPathListingIntoCache: ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	intermediate = method ( self, selector, path );
	criteria = ( intermediate != nil );
	result = Choose ( criteria, intermediate, result );
/*
 * If filtering was enabled in the defaults, apply it here, AFTER the listing was read from the cached (and potentially added to it
 * beforehand). This allows getting the full listing from the cache if filtering changes later on in the session and avoids having
 * to add some kind of tracking data to potentially evict results that become invalidated, potentially defeting the purpose of the
 * cache. It also has the benefit of keeping the code simple.
 */
	result = [WMFileListingDataSource _filterFileListing: result atPath: path];

	return result;
};

- (WMFileType) _calculateTypeOfFile: (NSString *) path
{
	register NSFileManager	* fileManager = nil;
	register NSNumber	* container = nil;
	//register long		type = -1;
	register WMFileType	result = WMInvalidFile;
	BOOL			isDirectory = NO,
				actuallyExists = NO,
				isExecutable = NO,
				criteria = NO;

	fileManager = [NSFileManager defaultManager];
	actuallyExists = [fileManager fileExistsAtPath: path isDirectory: & isDirectory];
	isExecutable = [fileManager isExecutableFileAtPath: path];
	//NSLog ( @"Checking file at path %@, with extension %@.", path, [path pathExtension] );
/*
 * Check if it's a standard bundle type known to us already.
 */
	criteria = ( actuallyExists && isDirectory );
	result = (int) ( criteria && [[path pathExtension] compare: @"bundle"] == NSOrderedSame ) * WMBundle;
	result += (int) ( criteria && [[path pathExtension] compare: @"font"] == NSOrderedSame ) * WMFontBundle;
	result += (int) ( criteria && [[path pathExtension] compare: @"nfont"] == NSOrderedSame ) * WMFontBundle;
	result += (int) ( criteria && [[path pathExtension] compare: @"nssound"] == NSOrderedSame ) * WMSoundBundle;
	result += (int) ( criteria && [[path pathExtension] compare: @"service"] == NSOrderedSame ) * WMServiceBundle;
	result += (int) ( criteria && [[path pathExtension] compare: @"app"] == NSOrderedSame ) * WMAppBundle;
	//NSLog ( @"Result so far (known bundle types check): %d.", result );
/*
 * Check if it's a document bundle (i.e. one handled by some application).
 */
	criteria = ( result == WMInvalidFile && criteria && [[path pathExtension] compare: @""] != NSOrderedSame );
	result += (int) ( criteria && [[NSWorkspace sharedWorkspace] isFilePackageAtPath: path] ) * WMDocumentBundle;
	//NSLog ( @"Result so far (document bundle check): %d.", result );
/*
 * Check if it's the home holder, a neighbor, or just a regular directory.
 */
	criteria = ( result == WMInvalidFile && actuallyExists && isDirectory );
	result += (int) ( criteria && [path compare: NSHomeDirectory ()] == NSOrderedSame ) * WMHomeFolder;
	result += (int) ( criteria && [path compare: NSHomeDirectory ()] != NSOrderedSame ) * WMDirectory;
	//NSLog ( @"Result so far (regular or home directory check): %d.", result );
/*
 * Check if it's a known font file.
 */
	criteria = ( actuallyExists && ! isDirectory && ! isExecutable );
	result += (int) ( criteria && [[path pathExtension] compare: @"afm"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"pfb"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"pfm"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"ttf"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"otf"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"pf2"] == NSOrderedSame ) * WMFont;
	result += (int) ( criteria && [[path pathExtension] compare: @"pcf"] == NSOrderedSame ) * WMFont;
	//NSLog ( @"Result so far (font file check): %d.", result );
/*
 * Check if it's a known sound file.
 */
	result += (int) ( criteria && [[path pathExtension] compare: @"wav"] == NSOrderedSame ) * WMSound;
	result += (int) ( criteria && [[path pathExtension] compare: @"voc"] == NSOrderedSame ) * WMSound;
	result += (int) ( criteria && [[path pathExtension] compare: @"au"] == NSOrderedSame ) * WMSound;
	result += (int) ( criteria && [[path pathExtension] compare: @"snd"] == NSOrderedSame ) * WMSound;
	//NSLog ( @"Result so far (sound file check): %d.", result );
/*
 * Check if it's a known image file.
 */
	result += (int) ( criteria && [[path pathExtension] compare: @"tiff"] == NSOrderedSame ) * WMImage;
	result += (int) ( criteria && [[path pathExtension] compare: @"png"] == NSOrderedSame ) * WMImage;
	result += (int) ( criteria && [[path pathExtension] compare: @"gif"] == NSOrderedSame ) * WMImage;
	result += (int) ( criteria && [[path pathExtension] compare: @"jpg"] == NSOrderedSame ) * WMImage;
	result += (int) ( criteria && [[path pathExtension] compare: @"eps"] == NSOrderedSame ) * WMImage;
	//NSLog ( @"Result so far (image file check): %d.", result );
/* 
 * Ceck if it's handled by some application
 */
	criteria = ( actuallyExists && ! isDirectory && ! isExecutable && result == WMInvalidFile );
	result += (int) ( criteria && [[NSWorkspace sharedWorkspace] infoForExtension: [path pathExtension]] != nil ) * WMDocument;
	//NSLog ( @"Result so far (known document check): %d.", result );
/*
 * Check to see if it's a tool (an executable, non-directory file).
 */
	result += (int) ( actuallyExists && ! isDirectory && isExecutable ) * WMTool;
	//NSLog ( @"Result so far (tool check): %d.", result );
/*
 * Check if it's a regular file.
 */
	/*type = (long) ( result == WMBundle ) * (long) ( @"generic bundle (.bundle)" );
	type += (long) ( result == WMFontBundle ) * (long) ( @"font bundle (.font, .nfont)" );
	type += (long) ( result == WMSoundBundle ) * (long) ( @"sound bundle (.nssound)" );
	type += (long) ( result == WMServiceBundle ) * (long) ( @"service bundle (.service)" );
	type += (long) ( result == WMAppBundle ) * (long) ( @"application bundle (.app)" );
	type += (long) ( result == WMDocumentBundle ) * (long) ( @"document bundle (.rtfd, etc)" );
	type += (long) ( result == WMHomeFolder ) * (long) ( @"user's home folder" );
	type += (long) ( result == WMDirectory ) * (long) ( @"directory" );
	type += (long) ( result == WMInvalidFile ) * (long) ( @"undeterminate type" );
	type += (long) ( result == WMFont ) * (long) ( @"font file (.afm, .pfb, .pfm, .ttf, .otf, .pf2, .pcf)" );
	type += (long) ( result == WMSound ) * (long) ( @"font file (.wav, .voc, .au, .snd)" );
	type += (long) ( result == WMImage ) * (long) ( @"image file (.tiff, .png, .gif, .jpg, .eps)" );
	type += (long) ( result == WMDocument ) * (long) ( @"single-file document" );
	type += (long) ( result == WMTool ) * (long) ( @"binary file (tool)" );
	type += (long) ( result == WMFile ) * (long) ( @"regular file" );
	type += (long) ( result == WMFile ) * (long) ( @"unknown type" );
	NSLog ( @"File %@'s type is %@ (%d).", [path lastPathComponent], (NSString *) ( type ), result );*/
	container = [NSNumber numberWithInteger: result];
	[typeCache setObject: container forKey: path];
	[typeCacheAger addObject: path];

	return result;
};

- (WMFileType) typeOfFile: (NSString *) path
{
	register NSNumber	* container = nil;
	register WMFileType	result = WMInvalidFile;
	register SEL		selector = NULL;
	register IMP		method = NULL;
	BOOL			criteria = NO;
/*
 * Check if the type for the given path is in the type cache and, if so, just return that. If not figure it out and stick it in the
 * cache.
 */
	container = [typeCache objectForKey: path];
	criteria = ( container == nil );
	selector = Choose ( criteria, @selector ( _calculateTypeOfFile: ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	result = Choose ( criteria, ((WMFileType) method ( self, selector, path )), ( [container integerValue] ));

	return result;
};

- (NSImage *) iconForFile: (NSString *) path ofType: (WMFileType) type
{
	register NSImage	* result = nil;
	register int		which = -1;

	switch ( type ) {
		case WMInvalidFile:	result = [NSImage imageNamed: WMInvalidFileImage];
					//NSLog ( @"Cannot determine Selected file's type." );
					break;
		case WMDirectory:	result = [NSImage imageNamed: WMDirectoryImage];
					//NSLog ( @"Selected file is a directory." );
					break;
		case WMHomeFolder:	result = [NSImage imageNamed: WMHomeFolderImage];
					//NSLog ( @"Selected file is the user's home directory." );
					break;
		case WMNeighborFolder:	result = [NSImage imageNamed: WMNeighborFolderImage];
					break;
		case WMBundle:		result = [NSImage imageNamed: WMDirectoryImage];
					break;
		case WMFont:
		case WMFontBundle:	result = [NSImage imageNamed: WMFontBundleImage];
					break;
		case WMSoundBundle:	result = [NSImage imageNamed: WMSoundBundleImage];
					break;
		case WMServiceBundle:	result = [NSImage imageNamed: WMServiceBundleImage];
					break;
		case WMTool:		result = [NSImage imageNamed: WMToolImage];
					break;
		case WMDocument:
		case WMImage:
		case WMDocumentBundle:
		case WMAppBundle:
		case WMFile:		result = [[NSWorkspace sharedWorkspace] iconForFile: path];
					break;
		case WMSound:		which = (int) ( [[path pathExtension] compare: @"wav"] == NSOrderedSame ) * 2;
					which += (int) ( [[path pathExtension] compare: @"voc"] == NSOrderedSame ) * 3;
					which += (int) ( [[path pathExtension] compare: @"snd"] == NSOrderedSame ) * 4;
					which += (int) ( [[path pathExtension] compare: @"au"] == NSOrderedSame ) * 5;

					switch ( which ) {
						case 2: result = [NSImage imageNamed: WMWavSoundImage];
							//NSLog ( @"Using icon %@.", WMWavSoundImage );
							break;
						case 3: result = [NSImage imageNamed: WMVocSoundImage];
							//NSLog ( @"Using icon %@.", WMVocSoundImage );
							break;
						case 4:	result = [NSImage imageNamed: WMSndSoundImage];
							//NSLog ( @"Using icon %@.", WMSndSoundImage );
							break;
						case 5:	result = [NSImage imageNamed: WMAuSoundImage];
							//NSLog ( @"Using icon %@.", WMAuSoundImage );
					}
	}

	return result;
};

- (BOOL) isDirectory: (NSString *) path
{
	register WMFileType	type = WMInvalidFile;
	register BOOL		result = NO;

	type = [self typeOfFile: path];
	result = ( type == WMDirectory || type == WMHomeFolder );

	return result;
};

- (void) reloadPath: (NSString *) path
{
	//register NSArray	* listing = nil;

	[listingCache removeObjectForKey: path];
	[listingCacheAger removeObject: path];
	/*listing =*/ [self fileListingForPath: path];
	//NSLog ( @"File listing for path %@: %@.", path, listing );
};
/*
 * NSObject overrides
 */
- (void) _finishInitializing
{
	register int	capacity = -1;

	capacity = [[NSUserDefaults standardUserDefaults] integerForKey: WMListingCacheLimitKey];
	capacity = Choose ( capacity == 0 , 256, capacity );
	[[NSUserDefaults standardUserDefaults] setInteger: capacity forKey: WMListingCacheLimitKey];
	listingCache = [NSMutableDictionary dictionaryWithCapacity: capacity];
	typeCache = [NSMutableDictionary dictionaryWithCapacity: capacity];
	listingCacheAger = [NSMutableArray arrayWithCapacity: capacity];
	typeCacheAger = [NSMutableArray arrayWithCapacity: capacity];
	[listingCache retain];
	[typeCache retain];
	[listingCacheAger retain];
	[typeCacheAger retain];
};

- (WMFileListingDataSource *) init
{
	register SEL	selector = NULL;
	register IMP	method = NULL;
	register BOOL	criteria = NO;

	self = [super init];
	criteria = ( self != nil );
	selector = Choose ( criteria, @selector ( _finishInitializing ), @selector ( nop ));
	method = objc_msg_lookup ( self, selector );
	method ( self, selector );

	return self;
};

- (void) dealloc
{
	[listingCache removeAllObjects];
	[listingCache release];
	[typeCache release];
	[typeCache removeAllObjects];
	[listingCacheAger release];
	[listingCacheAger removeAllObjects];
	[typeCacheAger release];
	[typeCacheAger removeAllObjects];
	[super dealloc];
};

@end
