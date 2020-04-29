/***********************************************************************************************************************************
 *
 *	NSArray+Additions.m
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

#import "aux.h"
#import "NSArray+Additions.h"

@implementation NSArray(WMAdditions)

- (NSArray *) filteredArrayUsingSelector: (SEL) selector
{
	register NSMutableArray	* result = nil;
	register NSEnumerator	* dispenser = nil;
	register void		* target = NULL;
	register id		object = nil;
	register ComparatorIMP	method = NULL;
	register BOOL		criteria = NO;

	result = [NSMutableArray arrayWithCapacity: [self count]];
	criteria = ( result == nil );
	target = Choose ( criteria, && out, && in );
	goto * target;
in:	dispenser = [self objectEnumerator];
	object = [dispenser nextObject];
	criteria = ( object != nil );

	while ( criteria ) {
		method = (ComparatorIMP) objc_msg_lookup ( object, selector );
		criteria = method ( object, selector );
		target = Choose ( criteria, && add, && skip );
		goto * target;
add:		[result addObject: object];
skip:		object = [dispenser nextObject];
		criteria = ( object != nil );
	}

out:	return result;
};

@end
