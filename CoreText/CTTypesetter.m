/** <title>CTTypesetter</title>

   <abstract>C Interface to text layout library</abstract>

   Copyright <copy>(C) 2010 Free Software Foundation, Inc.</copy>

   Author: Eric Wasylishen
   Date: Aug 2010

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.
   
   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   */

#include <CoreText/CTTypesetter.h>

#import "CTLine-private.h"
#import "CTRun-private.h"
// FIXME: use advanced layout engines if available
#import "OPSimpleLayoutEngine.h"

/* Constants */

const CFStringRef kCTTypesetterOptionDisableBidiProcessing = @"kCTTypesetterOptionDisableBidiProcessing";
const CFStringRef kCTTypesetterOptionForcedEmbeddingLevel = @"kCTTypesetterOptionForcedEmbeddingLevel";

/* Classes */

/**
 * Typesetter
 */
@interface CTTypesetter : NSObject {
    NSAttributedString *_as;
    NSDictionary *_options;
}

- (id)initWithAttributedString: (NSAttributedString*)string
                       options: (NSDictionary*)options;

- (CTLineRef)createLineWithRange: (CFRange)range;
- (CFIndex)suggestClusterBreakAtIndex: (CFIndex)start
                                width: (double)width;
- (CFIndex)suggestLineBreakAtIndex: (CFIndex)start
                             width: (double)width;

@end

@implementation CTTypesetter

#pragma mark - Life cycle

- (id)initWithAttributedString:(NSAttributedString *)string
                       options:(NSDictionary *)options
{
    //DLog(@"string: %@", string);
    if ((self = [super init])) {
        _as = [string retain];
        _options = [options retain];
    }
    return self;
}

- (void)dealloc
{
    [_as release];
    [_options release];
    [super dealloc];
}

#pragma mark - Accessors

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; as: %@; options: %@>", [self className], self, _as, _options];
}

#pragma mark - Private methods

- (CTLineRef)createLineWithRange:(CFRange)range
{
    // FIXME: This should do the core typesetting stuff:
    // - divide the attributed string into runs with the same attributes.
     
    //DLog(@"range: %d, %d", range.location, range.length);
    NSMutableArray *runs = [NSMutableArray array];
    
    OPSimpleLayoutEngine *layoutEngine = [[[OPSimpleLayoutEngine alloc] init] autorelease];
    NSUInteger index = range.location;
    
    while (index < range.length) {
        CFRange runRange;
        NSDictionary *runAttributes = CFAttributedStringGetAttributesAndLongestEffectiveRange(_as, index, CFRangeMake(index, range.length - index), &runRange);
        CFAttributedStringRef runAttributedString = CFAttributedStringCreateWithSubstring(NULL, _as, runRange);
        NSString *runString = CFAttributedStringGetString(runAttributedString);
        CFRelease(runAttributedString);
        //DLog(@"self: %@", self);
        CTRun *run = [layoutEngine layoutString:runString withAttributes:runAttributes];
        run.range = runRange;
        [runs addObject:run];
        index += runRange.length;
    }
    // - run the bidirectional algorithm if needed
    // - call the shaper on each run
    CTLineRef line = [[CTLine alloc] initWithRuns:runs];
    return line;
}

- (CFIndex)suggestClusterBreakAtIndex:(CFIndex)start
                                width:(double)width
{
    DLog();
    return 0;
}

- (CFIndex)suggestLineBreakAtIndex:(CFIndex)start width:(double)width
{
    int stringLength = _as.string.length;
    int numberOfChars = stringLength - start;
    if (numberOfChars > 10) {
        numberOfChars = 10;
    }
    //DLog(@"start: %d, width: %0.2f, numberOfChars: %d", start, width, numberOfChars);
    CTLineRef line = [self createLineWithRange:CFRangeMake(start, numberOfChars)];
    double lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    float charAverageWidth = lineWidth / numberOfChars;
    int suggestedLength = width / charAverageWidth;
    if (suggestedLength + start > stringLength) {
        suggestedLength = stringLength - start;
    }
    line = [self createLineWithRange:CFRangeMake(start, suggestedLength)];
    lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    if (lineWidth > width) {
        while (lineWidth > width) {
            suggestedLength--;
            CTLineRef line = [self createLineWithRange:CFRangeMake(start, suggestedLength)];
            lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            CFRelease(line);
        }
    } else if (lineWidth < width) {
        while (lineWidth < width && suggestedLength + start < stringLength) {
            suggestedLength++;
            CTLineRef line = [self createLineWithRange:CFRangeMake(start, suggestedLength)];
            lineWidth = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            CFRelease(line);
        }
        if (lineWidth > width) {
            suggestedLength--;
        }
    }
    return suggestedLength;
}

@end

#pragma mark - Shared functions

CTTypesetterRef CTTypesetterCreateWithAttributedString(NSAttributedString *string)
{
    return [[CTTypesetter alloc] initWithAttributedString:string
                                                  options:nil];
}

CTTypesetterRef CTTypesetterCreateWithAttributedStringAndOptions(
	NSAttributedString * string,
	CFDictionaryRef opts)
{
    return [[CTTypesetter alloc] initWithAttributedString: string
                                                  options: opts];
}

CTLineRef CTTypesetterCreateLine(CTTypesetterRef ts, CFRange range)
{
    //DLog(@"ts: %@", ts);
    return [ts createLineWithRange:range];
}

CFIndex CTTypesetterSuggestClusterBreak(
	CTTypesetterRef ts,
	CFIndex start,
	double width)
{
    return [ts suggestClusterBreakAtIndex:start width:width];
}

CFIndex CTTypesetterSuggestLineBreak(
	CTTypesetterRef ts,
	CFIndex start,
	double width)
{
    //DLog(@"width: %f", width);
    return [ts suggestLineBreakAtIndex:start width:width];
}

CFTypeID CTTypesetterGetTypeID()
{
    return (CFTypeID)[CTTypesetter class];
}

