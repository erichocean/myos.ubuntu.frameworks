
#import "RRSolidView.h"

@implementation RRSolidView

#pragma mark - Life cycle

#pragma mark - Overridden methods

- (void)drawRect:(NSRect)rect
{
    [[NSColor redColor] set];
    [[NSColor redColor] setFill];
    NSRectFill(NSMakeRect(0,0,200,100));
}

@end
