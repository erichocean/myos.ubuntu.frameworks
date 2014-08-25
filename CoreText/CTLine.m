/** <title>CTLine</title>

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

#import "CTLine-private.h"

/* Classes */

@implementation CTLine

- (id)initWithRuns: (NSArray*)runs
{
  self = [super init];
  if (self) {
    _runs = [runs retain];
  }
  return self;
}

- (NSArray*)runs
{
  return _runs;
}

- (void)drawOnContext: (CGContextRef)ctx
{
  const NSUInteger runsCount = [_runs count];
  for (NSUInteger i=0; i<runsCount; i++)
  {
    CTRunRef run = [_runs objectAtIndex: i];
    CTRunDraw(run, ctx, CFRangeMake(0, CTRunGetGlyphCount(run)));
  }
}

- (CFIndex)glyphCount
{
  CFIndex sum = 0;
  const NSUInteger runsCount = [_runs count];
  for (NSUInteger i=0; i<runsCount; i++)
  {
    CTRunRef run = [_runs objectAtIndex: i];
    sum += CTRunGetGlyphCount(run);
  }
  return sum;
}

- (NSArray*)glyphRuns
{
  return _runs;
}

- (CTLine*) truncatedLineWithWidth: (double)width
                    truncationType: (CTLineTruncationType)truncationType
                   truncationToken:	(CTLineRef)truncationToken
{
  double lineWidth = CTLineGetTypographicBounds(self, NULL, NULL, NULL);
  if (width < lineWidth) {
    double tokenWidth = CTLineGetTypographicBounds(truncationToken, NULL, NULL, NULL);
    double widthToRemove = lineWidth - width + tokenWidth;
    const NSUInteger runsCount = [_runs count];
    NSMutableArray *newRuns = [NSMutableArray arrayWithCapacity:0];
    switch(truncationType) {
      case kCTLineTruncationStart: {
        [newRuns addObjectsFromArray:truncationToken->_runs];
        for (int i = 0; i < runsCount; ++i) {
          CTRunRef run = [self->_runs objectAtIndex: i];
          double runWidth = CTRunGetTypographicBounds(run, CFRangeMake(0, CTRunGetGlyphCount(run)), NULL, NULL, NULL);
          if (widthToRemove >= runWidth) {
            widthToRemove -= runWidth; //truncate the whole run
          } else if (widthToRemove == 0) {
            [newRuns addObject:run]; //truncation finished
          } else {
            //truncate fraction of the run
            CFIndex runCount = CTRunGetGlyphCount(run);
            CFIndex runRemovedGlyphsCount = ceil(widthToRemove / (runWidth/runCount));
            //rough calculation, not considering the difference between glyphs width.
            CFRange truncatedRunRange = CFRangeMake(runRemovedGlyphsCount, CTRunGetGlyphCount(run) - runRemovedGlyphsCount);
            [newRuns addObject:[run runInRange:truncatedRunRange]];

            widthToRemove = 0;
          }
        }
      }
      break;
      case kCTLineTruncationEnd: {
        [newRuns addObjectsFromArray:truncationToken->_runs];
        for (int i = runsCount-1; i > -1; --i) {
          CTRunRef run = [self->_runs objectAtIndex: i];
          double runWidth = CTRunGetTypographicBounds(run, CFRangeMake(0, CTRunGetGlyphCount(run)), NULL, NULL, NULL);
          if (widthToRemove >= runWidth) {
            widthToRemove -= runWidth; //truncate the whole run
          } else if (widthToRemove == 0) {
            [newRuns insertObject:run atIndex:0]; //truncation finished
          } else {
            //truncate fraction of the run
            CFIndex runCount = CTRunGetGlyphCount(run);
            CFIndex runRemovedGlyphsCount = ceil(widthToRemove / (runWidth/runCount));
            //rough calculation, not considering the difference between glyphs width.
            CFRange truncatedRunRange = CFRangeMake(0, CTRunGetGlyphCount(run) - runRemovedGlyphsCount);
            [newRuns insertObject:[run runInRange:truncatedRunRange] atIndex:0];

            widthToRemove = 0;
          }
        }
      }
      break;
      case kCTLineTruncationMiddle:
      default: {
        double sideWidth = (lineWidth - widthToRemove) / 2;
        for (int i = 0; i < runsCount; ++i) {
          CTRunRef run = [self->_runs objectAtIndex: i];
          CFIndex runGlyphCount = CTRunGetGlyphCount(run);
          double runWidth = CTRunGetTypographicBounds(run, CFRangeMake(0, runGlyphCount), NULL, NULL, NULL);
          if (sideWidth > runWidth) {
            [newRuns addObject:run]; // Keep the whole run.
            sideWidth -= runWidth;
          } else if (widthToRemove == 0) {
            [newRuns addObject:run]; // Keep the whole run.
          } else if (widthToRemove >= runWidth) {
            widthToRemove -= runWidth; //truncate the whole run
          } else {
            //truncate fraction of the run
            CFIndex runRemovedGlyphsCount = ceil(widthToRemove / (runWidth/runGlyphCount));
            //rough calculation, not considering the difference between glyphs width.
            CFIndex startTruncationIndex = (runGlyphCount - runRemovedGlyphsCount) / 2.0;
            CFIndex endTruncationIndex = startTruncationIndex + runRemovedGlyphsCount;
            
            [newRuns addObject:[run runInRange:CFRangeMake(0, startTruncationIndex)]];

            [newRuns addObjectsFromArray:truncationToken->_runs];

            [newRuns addObject:[run runInRange:CFRangeMake(endTruncationIndex, runGlyphCount - endTruncationIndex)]];

            widthToRemove = 0;
          }
        }
      }
      break;
    }
    return [[[CTLine alloc] initWithRuns:newRuns] autorelease];
  }
  return self;
}

- (double)penOffset
{
  return penOffset;
}

- (CFRange)stringRange
{//TODO
  return CFRangeMake(0,0);
}
@end


/* Functions */

CTLineRef CTLineCreateWithAttributedString(NSAttributedString * string)
{
  CTTypesetterRef ts = CTTypesetterCreateWithAttributedString(string);
  CTLineRef line = CTTypesetterCreateLine(ts, CFRangeMake(0, CFAttributedStringGetLength(string)));
  [ts release];
  return line;
}

CTLineRef CTLineCreateTruncatedLine(
	CTLineRef line,
	double width,
	CTLineTruncationType truncationType,
	CTLineRef truncationToken)
{
  return [[line truncatedLineWithWidth: width
                        truncationType: truncationType
                       truncationToken: truncationToken] retain];
}

CTLineRef CTLineCreateJustifiedLine(
	CTLineRef line,
	CGFloat justificationFactor,
	double justificationWidth)
{//TODO
  return line;
}

CFIndex CTLineGetGlyphCount(CTLineRef line)
{
  return [line glyphCount];
}

CFArrayRef CTLineGetGlyphRuns(CTLineRef line)
{
  return [line glyphRuns];
}

CFRange CTLineGetStringRange(CTLineRef line)
{
  return [line stringRange];
}

double CTLineGetPenOffsetForFlush(
	CTLineRef line,
	CGFloat flushFactor,
	double flushWidth)
{
  return flushFactor * (flushWidth - CTLineGetTypographicBounds(line, NULL, NULL, NULL));
}
void CTLineDraw(CTLineRef line, CGContextRef context)
{
  return [line drawOnContext: context];
}

CGRect CTLineGetImageBounds(
	CTLineRef line,
	CGContextRef context)
{//TODO
  return CGRectMake(0,0,0,0);
}

double CTLineGetTypographicBounds(
	CTLineRef line,
	CGFloat* ascent,
	CGFloat* descent,
	CGFloat* leading)
{
  double width = 0;
  const NSUInteger runsCount = [line->_runs count];
  for (NSUInteger i=0; i<runsCount; i++) {
    CTRunRef run = [line->_runs objectAtIndex: i];
    width += CTRunGetTypographicBounds(run, CFRangeMake(0, CTRunGetGlyphCount(run)), ascent, descent, leading);
  }
  return width;
}

double CTLineGetTrailingWhitespaceWidth(CTLineRef line)
{//TODO
  return 0;
}

CFIndex CTLineGetStringIndexForPosition(
	CTLineRef line,
	CGPoint position)
{//TODO
  return 0;
}

CGFloat CTLineGetOffsetForStringIndex(
	CTLineRef line,
	CFIndex charIndex,
	CGFloat* secondaryOffset)
{//TODO
  return 0;
}

CFTypeID CTLineGetTypeID()
{
  return (CFTypeID)[CTLine class];
}

