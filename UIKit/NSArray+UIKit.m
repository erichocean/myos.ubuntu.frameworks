/*
 Copyright © 2014 myOS Group.
 
 This file is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This file is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import <UIKit/NSArray+UIKit.h>

@implementation NSMutableArray (UIKit)

- (void)moveObjectToTop:(id)anObject
{
    //DLog(@"anObject: %@", anObject);
    [anObject retain];
    [self removeObject:anObject];
    [self addObject:anObject];
    [anObject release];
}

- (void)moveObject:(id)firstObject afterObject:(id)secondObject
{
    [firstObject retain];
    [self removeObject:firstObject];
    if ([self lastObject] == secondObject) {
        [self addObject:firstObject];
    } else {
        [self insertObject:firstObject atIndex:[self indexOfObject:secondObject]+1];
    }
    [firstObject release];
}

- (void)moveObject:(id)firstObject beforeObject:(id)secondObject
{
    [firstObject retain];
    [self removeObject:firstObject];
    [self insertObject:firstObject atIndex:[self indexOfObject:secondObject]];
    [firstObject release];
}

- (void)moveObject:(id)anObject toIndex:(int)index
{
    [anObject retain];
    [self removeObject:anObject];
    [self insertObject:anObject atIndex:index];
    [anObject release];
}

@end
