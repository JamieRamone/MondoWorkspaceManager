/***********************************************************************************************************************************
 *
 *	NSString+Additions.m
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
#import <Foundation/NSFileManager.h>

#import "NSString+Additions.h"

@implementation NSString(WMAdditions)

static NSString	* _pathForComparison = nil;

+ (void) setCurrentPath: (NSString *) path
{
	_pathForComparison = path;
};

- (NSComparisonResult) fileTypeCompare: (NSString *) string
{
	register NSFileManager		* fileManager = nil;
	register NSComparisonResult	result = NSOrderedSame;
	register BOOL			criteria = NO,
					itExists = NO,
					iExist = NO;
	BOOL				isDirectory = NO,
					amDirectory = NO;
					

	fileManager = [NSFileManager defaultManager];
	itExists = [fileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", _pathForComparison, string] isDirectory: & isDirectory];
	iExist = [fileManager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", _pathForComparison, self] isDirectory: & amDirectory];
/*
 * isFile ( string ) == isFile ( self ) --> (
 *	isDir ( string ) == isDir ( self ) --> compare ( string, self )
 * 	isDir ( string ) != isDir ( self ) --> (
 *		isDir ( string ) && ! isDir ( self ) --> self < string
 *		! isDir ( string ) && isDir ( self ) --> string < self
 *	)
 * )
 * isFile ( string ) != isFile ( self ) --> (
 *	isFile ( string ) && ! isFile ( self ) --> self < string
 *	! isFile ( string ) && isFile ( self ) --> string < self
 * )
 */
	criteria = ( itExists == iExist );

	if ( criteria ) {
		criteria = ( isDirectory == amDirectory );

		if ( criteria ) {
			result = [self compare: string];
		} else {
			criteria = ( isDirectory && ! amDirectory );

			if ( criteria ) {
				result = NSOrderedDescending;
			} else {
				result = NSOrderedAscending;
			}
		}
	} else {
		if ( itExists && ! iExist ) {
			result = NSOrderedDescending;
		} else {
			result = NSOrderedAscending;
		}
	}

	//NSLog ( @"%@ %@ is %@ than %@ %@.", isDirectory ? @"Directory" : @"File", [NSString stringWithFormat: @"%@/%@", _pathForComparison, string], result == NSOrderedAscending ? @"larger" : @"smaller", amDirectory ? @"directory" : @"file", [NSString stringWithFormat: @"%@/%@", _pathForComparison, self] );

	return result;
};

- (BOOL) isNotDotFile
{
	register BOOL	result = NO;

	result = [self characterAtIndex: 0] != '.';

	return result;
};

@end
