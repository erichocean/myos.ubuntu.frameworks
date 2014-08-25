/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import <CoreAnimation/CABase.h>

@protocol CAAction

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict;

@end
