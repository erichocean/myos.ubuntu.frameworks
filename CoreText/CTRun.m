/** <title>CTRun</title>

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

#import "CTRun-private.h"
#import "CTFont.h"
#import "CTStringAttributes.h"

/* Classes */

@implementation CTRun

@synthesize range=_stringRange;

#pragma mark - Life cycle

- (id)initWithGlyphs:(CGGlyph *)glyphs advances:(CGSize *)advances range:(CFRange)range attributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        _stringRange = range;
        _glyphs = malloc(sizeof(CGGlyph) * range.length);
        _advances = malloc(sizeof(CGSize) * range.length);
        _positions = malloc(sizeof(CGPoint) * range.length);
        for (int i = 0; i < range.length; ++i) {
            _glyphs[i] = glyphs[i];
            _advances[i] = advances[i];
            _positions[i] = CGPointMake(i*20,0);//TODO fix this
        }
        _attributes = [[NSDictionary alloc] initWithDictionary:attributes];
        _count = range.length;
    }
    return self;
}

- (void)dealloc
{
    free(_glyphs);
    free(_advances);
    free(_positions);
    [_attributes release];
    [super dealloc];
}

#pragma mark - Accessors

- (CFIndex)glyphCount
{
    return _count;
}

- (NSDictionary *)attributes
{
    return _attributes;
}

- (CTRunStatus)status
{
    return _status;
}

- (const CGGlyph *)glyphs
{
    return _glyphs;
}

- (const CGPoint *)positions
{
    return _positions;
}

- (const CGSize *)advances
{
    return _advances;
}

- (const CFIndex *)stringIndices
{
    return _stringIndices;
}

- (CFRange)stringRange
{
    return _stringRange;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p; count: %d; stringRange: %d, %d>", [self className], self, _count, _stringRange.location, _stringRange.length];
}

- (double)typographicBoundsForRange:(CFRange)range
			     ascent:(CGFloat *)ascent//FIXME
			    descent:(CGFloat *)descent//FIXME
			    leading:(CGFloat *)leading//FIXME
{
    if (range.location < _count && (range.location + range.length) <= _count) {
        CGFloat width = 0;
        CGSize *currentAdvance = _advances;
        if (range.length == 0) {
            range.length = _count;
        }
        for (int i = range.location; i < range.length; ++i, ++currentAdvance) {
            width += (*currentAdvance).width;
        }
        return width;
    }
    
    return 0;
}

- (CGRect)imageBoundsForRange: (CFRange)range
		  withContext: (CGContextRef)context
{
    if (context != NULL && range.location < _count && (range.location + range.length) <= _count) {
        CGPoint origin = CGContextGetTextPosition(context);
        CGFloat height = 0;
        CGFloat width = 0;
        CGSize* currentAdvance = _advances;
        for (int i = range.location; i < range.length; ++i, ++currentAdvance) {
            if ((*currentAdvance).height > height) {
                height = (*currentAdvance).height;
            }
            width += (*currentAdvance).width;
        }
        
        return CGRectMake(origin.x, origin.y, width, height);
    }
    return CGRectNull; //invalid parameter
}

- (CGAffineTransform)matrix
{
    return _matrix;
}

- (void)drawRange:(CFRange)range onContext:(CGContextRef)ctx
{
    if (range.length == 0) {
        range.length = _count;
    }
    if (range.location > _count || (range.location + range.length) > _count) {
        NSLog(@"CTRunDraw range out of bounds");
        return;
    }
    // TODO check for each attribute and apply the effect
    //kCTKernAttributeName;
    //kCTLigatureAttributeName;
    //kCTParagraphStyleAttributeName;
    //kCTStrokeWidthAttributeName;
    //kCTUnderlineStyleAttributeName;
    //kCTSuperscriptAttributeName;
    //kCTUnderlineColorAttributeName;
    //kCTVerticalFormsAttributeName;
    //kCTGlyphInfoAttributeName;
    //kCTCharacterShapeAttributeName;
    
    CTFontRef font = [_attributes objectForKey:kCTFontAttributeName];
    CGFloat size = CTFontGetSize(font);
    CFStringRef fontName = CTFontCopyPostScriptName(font);
    //DLog(@"Drawing with %@, %f", fontName, size);
    
    // Set color
    CFBooleanRef getForegroundColorFromContext = (CFBooleanRef)[_attributes objectForKey:kCTForegroundColorFromContextAttributeName];
    if (!CFBooleanGetValue(getForegroundColorFromContext)) {
        CGColorRef foregroundColor = [_attributes objectForKey:kCTForegroundColorAttributeName];
        CGContextSetFillColorWithColor(ctx, foregroundColor);
        CGColorRef strokeColor = [_attributes objectForKey:kCTStrokeColorAttributeName];
        CGContextSetStrokeColorWithColor(ctx, strokeColor);
    }
    // Set font
    CGFontRef f = CGFontCreateWithFontName(fontName);
    CGContextSetFont(ctx, f);
    // Set font size
    CGContextSetFontSize(ctx, size);
    
    // Draw
    CGContextShowGlyphs(ctx, _glyphs, range.length);
    //CGContextShowGlyphsWithAdvances(ctx, _glyphs, _advances, range.length);
}

- (CTRun *)runInRange:(CFRange)range
{
    CTRun *subRun = nil;
    if (range.location < _count && (range.location + range.length) <= _count) {
        CFRange  stringRange = CFRangeMake(_stringRange.location + range.location, range.length);
        CGGlyph * glyphs = malloc(sizeof(CGGlyph) * range.length);
        CGSize * advances = malloc(sizeof(CGSize) * range.length);
        for (int i = 0; i < range.length; ++i) {
            glyphs[i] = _glyphs[i+range.location];
            advances[i] = _advances[i+range.location];
        }
        subRun = [[[CTRun alloc] initWithGlyphs:glyphs advances:advances range:stringRange attributes:_attributes] autorelease];
        free(glyphs);
        free(advances);
    }
    return subRun;
}

@end

/* Functions */
 
CFIndex CTRunGetGlyphCount(CTRunRef run)
{
    return [run glyphCount];
}

CFDictionaryRef CTRunGetAttributes(CTRunRef run)
{
    return [run attributes];
}

CTRunStatus CTRunGetStatus(CTRunRef run)
{
    return [run status];
}

const CGGlyph* CTRunGetGlyphsPtr(CTRunRef run)
{
    return [run glyphs];
}

void CTRunGetGlyphs(
	CTRunRef run,
	CFRange range,
	CGGlyph buffer[])
{
    memcpy(buffer, [run glyphs] + range.location, sizeof(CGGlyph) * range.length);
}

const CGPoint *CTRunGetPositionsPtr(CTRunRef run)
{
    return [run positions];
}

void CTRunGetPositions(
	CTRunRef run,
	CFRange range,
	CGPoint buffer[])
{
  memcpy(buffer, [run positions] + range.location, sizeof(CGPoint) * range.length);
}

const CGSize *CTRunGetAdvancesPtr(CTRunRef run)
{
  return [run advances];
}

void CTRunGetAdvances(
	CTRunRef run,
	CFRange range,
	CGSize buffer[])
{
    memcpy(buffer, [run advances] + range.location, sizeof(CGSize) * range.length);
}

const CFIndex *CTRunGetStringIndicesPtr(CTRunRef run)
{
    return [run stringIndices];
}

void CTRunGetStringIndices(
	CTRunRef run,
	CFRange range,
	CFIndex buffer[])
{
    memcpy(buffer, [run stringIndices] + range.location, sizeof(CFIndex) * range.length);
}

CFRange CTRunGetStringRange(CTRunRef run)
{
    return [run stringRange];
}

double CTRunGetTypographicBounds(
	CTRunRef run,
	CFRange range,
	CGFloat *ascent,
	CGFloat *descent,
	CGFloat *leading)
{
    return [run typographicBoundsForRange:range
                                   ascent:ascent
                                  descent:descent
                                  leading:leading];
}

CGRect CTRunGetImageBounds(
	CTRunRef run,
	CGContextRef context,
	CFRange range)
{
    return [run imageBoundsForRange: range
                        withContext: context];
}

CGAffineTransform CTRunGetTextMatrix(CTRunRef run)
{
    return [run matrix];
}

void CTRunDraw(
	CTRunRef run,
	CGContextRef ctx,
	CFRange range)
{
    [run drawRange: range onContext: ctx];
}

CFTypeID CTRunGetTypeID()
{
    return (CFTypeID)[CTRun class];
}

