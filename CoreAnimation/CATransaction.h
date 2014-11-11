/*
 Copyright © 2014 myOS Group.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 Lesser General Public License for more details.
 
 Contributor(s):
 Amr Aboelela <amraboelela@gmail.com>
 */

#import <CoreAnimation/CABase.h>

extern NSString *const kCATransactionAnimationDuration;
extern NSString *const kCATransactionAnimationTimingFunction;
extern NSString *const kCATransactionDisableActions;
extern NSString *const kCATransactionCompletionBlock;

@class CAMediaTimingFunction;

@interface CATransaction : NSObject 

+ (CFTimeInterval)animationDuration;
+ (void)setAnimationDuration:(CFTimeInterval)dur;
+ (CAMediaTimingFunction *)animationTimingFunction;
+ (void)setAnimationTimingFunction:(CAMediaTimingFunction *)function;
+ (BOOL)disableActions;
+ (void)setDisableActions:(BOOL)flag;
+ (id)valueForKey:(NSString *)key;
+ (void)setValue:(id)value forKey:(NSString *)key;

+ (void)begin;
+ (void)commit;
+ (void)flush;
+ (void)lock;
+ (void)unlock;

@end

