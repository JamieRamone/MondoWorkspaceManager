/***********************************************************************************************************************************
 *
 *	NSFileManager+Additions.m
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
#include <unistd.h>
#include <sys/stat.h>

#import <Foundation/Foundation.h>

@implementation NSFileManager (WMAdditions)

- (BOOL) isExecutableFileAtPath: (NSString *) path
{
	register const char	* file = NULL;
	struct stat		info;
	register BOOL		result = NO;

	file = [path cString];
	info.st_uid = -1;
	info.st_mode = 0;
	result = ( stat ( file, & info ) == 0 );
	result = ( result && ((( info.st_uid == getuid ()) && (( info.st_mode & S_IXUSR ) != 0 )) ||
			     (( info.st_uid == geteuid ()) && (( info.st_mode & S_IXUSR ) != 0 ))));
	result = ( result || ((( info.st_gid == getgid ()) && (( info.st_mode & S_IXGRP ) != 0 )) ||
			     (( info.st_gid == getegid ()) && (( info.st_mode & S_IXGRP ) != 0 ))));
	result = ( result || ((( info.st_uid != getuid ()) && (( info.st_mode & S_IXOTH ) != 0 )) ||
			     (( info.st_uid != geteuid ()) && (( info.st_mode & S_IXOTH ) != 0 ))));
	//printf ( "File %s is %s.\n", file, result ? "executable" : "not executable" );

	return result;
};

- (BOOL) isDeletableFileAtPath: (NSString *) path
{
	register NSString	* file = NULL;
	register BOOL		result = NO;

	file = [path stringByDeletingLastPathComponent];
	result = [self isWritableFileAtPath: file];
	result = result && [self isExecutableFileAtPath: file];
	//printf ( "File %s is %s.\n", [file cString], result ? "deletable" : "not deletable" );

	return result;
};

- (BOOL) isReadableFileAtPath: (NSString *) path
{
	register const char	* file = NULL;
	struct stat		info;
	register BOOL		result = NO;

	file = [path cString];
	info.st_uid = -1;
	info.st_mode = 0;
	result = ( stat ( file, & info ) == 0 );
	result = ( result && ((( info.st_uid == getuid ()) && (( info.st_mode & S_IRUSR ) != 0 )) ||
			     (( info.st_uid == geteuid ()) && (( info.st_mode & S_IRUSR ) != 0 ))));
	result = ( result || ((( info.st_gid == getgid ()) && (( info.st_mode & S_IRGRP ) != 0 )) ||
			     (( info.st_gid == getegid ()) && (( info.st_mode & S_IRGRP ) != 0 ))));
	result = ( result || ((( info.st_uid != getuid ()) && (( info.st_mode & S_IROTH ) != 0 )) ||
			     (( info.st_uid != geteuid ()) && (( info.st_mode & S_IROTH ) != 0 ))));
	//printf ( "File %s is %s.\n", file, result ? "readable" : "not readable" );

	return result;
};

- (BOOL) isWritableFileAtPath: (NSString *) path
{
	register const char	* file = NULL;
	struct stat		info;
	register BOOL		result = NO;

	file = [path cString];
	info.st_uid = -1;
	info.st_mode = 0;
	result = ( stat ( file, & info ) == 0 );
	result = ( result && ((( info.st_uid == getuid ()) && (( info.st_mode & S_IWUSR ) != 0 )) ||
			     (( info.st_uid == geteuid ()) && (( info.st_mode & S_IWUSR ) != 0 ))));
	result = ( result || ((( info.st_gid == getgid ()) && (( info.st_mode & S_IWGRP ) != 0 )) ||
			     (( info.st_gid == getegid ()) && (( info.st_mode & S_IWGRP ) != 0 ))));
	result = ( result || ((( info.st_uid != getuid ()) && (( info.st_mode & S_IWOTH ) != 0 )) ||
			     (( info.st_uid != geteuid ()) && (( info.st_mode & S_IWOTH ) != 0 ))));
	//printf ( "File %s is %s.\n", file, result ? "writable" : "not writable" );

	return result;
};

@end
