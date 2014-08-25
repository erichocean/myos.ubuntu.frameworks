/*
 * Copyright (c) 2013. All rights reserved.
 *
 */

#import "ShapesView.h"

void frameArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
void paintArc(CGContextRef context, CGRect r, int startAngle, int arcAngle);
void frameOval(CGContextRef context, CGRect r);
void paintOval(CGContextRef context, CGRect r);
void frameRect(CGContextRef context, CGRect r);
void paintRect(CGContextRef context, CGRect r);
void fillRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);
void strokeRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat ovalHeight);

@implementation ShapesView

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        //self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - Overridden methods

- (void)drawRect:(CGRect)rect
{


    DLog(@"rect: %@", NSStringFromCGRect(rect));
    CGContextRef ctx = UIGraphicsGetCurrentContext();

        CGRect bounds = rect;
        double a, b;
        int count, k;

        CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
        CGContextFillRect(ctx, CGRectMake(0, rect.size.height / 2, rect.size.width, rect.size.height / 2));

        // Use a transparency layer for the first shape

        CGContextSetAlpha(ctx, 0.5);
        CGContextBeginTransparencyLayer(ctx, NULL);

        // Calculate the dimensions for an oval inside the bounding box
        a = 0.9 * bounds.size.width/4;
        b = 0.3 * bounds.size.height/2;
        count = 5;

        // Set the fill color to a partially transparent blue
        CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);

        // Set the stroke color to an opaque black
        CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

        // Set the line width to be used, in user space units.
        CGContextSetLineWidth(ctx, 3);

        // Save the conexts state because we are going to be moving the origin and
        // rotating context for drawing, but we would like to restore the current
        // state before drawing the next image.
        CGContextSaveGState(ctx);

        // Move the origin to the middle of the first image (left side) to draw.
        CGContextTranslateCTM(ctx, bounds.size.width/4, bounds.size.height/2);
  CGColorRef shadowColor = CGColorCreateGenericRGB(0, 0.2, 0.3, 0.75);

        // Draw "count" ovals, rotating the context around the newly translated origin
        // 1/count radians after drawing each oval
        for (k = 0; k < count; k++)
        {
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(6.0,-6.0), 2.0, shadowColor);
                // Paint the oval with the fill color
                paintOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));
    CGContextRestoreGState(ctx);

                // Frame the oval with the stroke color
                frameOval(ctx, CGRectMake(-a, -b, 2 * a, 2 * b));

                // Rotate the context around the center of the image
                CGContextRotateCTM(ctx, M_PI / count);
        }
        // Restore the saved state to a known state for dawing the next image
        CGContextRestoreGState(ctx);
  CGColorRelease(shadowColor);

        // End the transparency layer
  CGContextEndTransparencyLayer(ctx);



        // Calculate a bounding box for the rounded rect
        a = 0.9 * bounds.size.width/4;
        b = 0.3 * bounds.size.height/2;
        count = 5;

        // Set the fill color to a partially transparent red
        CGContextSetRGBFillColor(ctx, 1, 0, 0, 0.5);

        // Set the stroke color to an opaque black
        CGContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);

        // Set the line width to be used, in user space units.
        CGContextSetLineWidth(ctx, 3);

        // Save the conexts state because we are going to be moving the origin and
        // rotating context for drawing, but we would like to restore the current
        // state before drawing the next image.
        CGContextSaveGState(ctx);

        // Move the origin to the middle of the second image (right side) to draw.
        CGContextTranslateCTM(ctx, bounds.size.width/4 + bounds.size.width/2, bounds.size.height/2);

        for (k = 0; k < count; k++)
        {
                // Fill then stroke the rounding rect, otherwise the fill would cover the stroke
                fillRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
                strokeRoundedRect(ctx, CGRectMake(-a, -b, 2 * a, 2 * b), 20, 20);
                // Rotate the context for the next rounded rect
                CGContextRotateCTM(ctx, M_PI / count);
        }
        CGContextRestoreGState(ctx);

/*
//    CGSize offset = CGSizeMake(10,10);
    //CGContextSetShadow(ctx,offset,2);

    // draw curves
    CGContextSetStrokeColorWithColor(ctx, [[UIColor redColor] CGColor]);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, 100, 100, 25, 0, 2 * PI, YES);
    CGPathAddArc(path, NULL, 200, 200, 50, 0, 0.8 * PI, NO);
    CGPathAddArc(path, NULL, 300, 300, 50, 1.7 * PI, 1 * PI, NO);

    CGPathMoveToPoint(path, NULL, 300, 100);
    CGPathAddCurveToPoint(path, NULL, 300, 150, 350, 100, 350, 150);
    CGPathAddCurveToPoint(path, NULL, 400, 200, 400, 200, 450, 150);

    CGContextAddPath(ctx, (CGPathRef)path);
    CGContextStrokePath(ctx);

    // Draw the curved rectangle 
    CGContextSaveGState(ctx);
    CGRect aRect = CGRectMake(150, 10, 250, 100);
    CGFloat radius = 10;
    CGFloat buffer = floorf(CGRectGetMaxY(aRect) * 0);
    CGFloat aMaxX = floorf(CGRectGetMaxX(aRect) - buffer);
    CGFloat aMaxY = floorf(CGRectGetMaxY(aRect) - buffer);
    CGFloat aMinX = floorf(CGRectGetMinX(aRect) + buffer);
    CGFloat aMinY = floorf(CGRectGetMinY(aRect) + buffer);

    CGContextBeginPath(ctx);
    CGContextSetLineWidth(ctx,3);
    CGContextSetRGBFillColor(ctx, 0.5, 1.0, 0.0, 1.0);
    //CGContextSetStrokeColorWithColor(ctx, [[UIColor blueColor] CGColor]);
    CGContextAddArc(ctx, aMaxX - radius, aMinY + radius, radius, PI*1.5, 0 , NO);
    CGContextAddArc(ctx, aMaxX - radius, aMaxY - radius, radius, 0, PI/2 , NO);
    CGContextAddArc(ctx, aMinX + radius, aMaxY - radius, radius, PI/2, PI, NO);
    CGContextAddArc(ctx, aMinX + radius, aMinY + radius, radius, PI, PI*1.5, NO);
    CGContextClosePath(ctx);
    //CGContextStrokePath(ctx);
    CGContextFillPath(ctx);

    CGContextRestoreGState(ctx);
*/
}

@end

void addOvalToPath(CGContextRef context, CGRect r)
{
    CGAffineTransform matrix;

        // Save the context's state because we are going to transform and scale it
    CGContextSaveGState(context);

        // Create a transform to scale the context so that a radius of 1
        // is equal to the bounds of the rectangle, and transform the origin
        // of the context to the center of the bounding rectangle.  The 
        // center of the bounding rectangle will now be the center of
        // the oval.
    matrix = CGAffineTransformMake((r.size.width)/2, 0,
                                                                   0, (r.size.height)/2,
                                                                   r.origin.x + (r.size.width)/2,
                                                                   r.origin.y + (r.size.height)/2);

        // Apply the transform to the context
    CGContextConcatCTM(context, matrix);

        // Signal the start of a path
    CGContextBeginPath(context);

        // Add a circle to the path.  After the circle is transformed by the
        // context's transformation matrix, it will become an oval lying
        // just inside the bounding rectangle.
    CGContextAddArc(context, 0, 0, 1, 0, 2*M_PI, 0);

        // Restore the context's state. This removes the translation and scaling but leaves
        // the path, since the path is not part of the graphics state.
        CGContextRestoreGState(context);
}

void paintOval(CGContextRef context, CGRect r)
{
        // Add a path for the oval to this context
        addOvalToPath(context,r);

        // Fill the oval
    CGContextFillPath(context);
}

void frameOval(CGContextRef context, CGRect r)
{
        // Add a path for the oval to this context
        addOvalToPath(context,r);

        // Stroke the path
        CGContextStrokePath(context);
}

void frameRect(CGContextRef context, CGRect r)
{
    CGContextStrokeRect(context, r);
}

void paintRect(CGContextRef context, CGRect r)
{
    CGContextFillRect(context, r);
}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, CGFloat ovalWidth,
                                                  CGFloat ovalHeight)
{
        CGFloat fw, fh;
        // If the width or height of the corner oval is zero, then it reduces to a right angle,
        // so instead of a rounded rectangle we have an ordinary one.
        if (ovalWidth == 0 || ovalHeight == 0) {
                CGContextAddRect(context, rect);
                return;
        }

        //  Save the context's state so that the translate and scale can be undone with a call
        //  to CGContextRestoreGState.
        CGContextSaveGState(context);

        //  Translate the origin of the contex to the lower left corner of the rectangle.
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));

        //Normalize the scale of the context so that the width and height of the arcs are 1.0
        CGContextScaleCTM(context, ovalWidth, ovalHeight);

        // Calculate the width and height of the rectangle in the new coordinate system.
        fw = CGRectGetWidth(rect) / ovalWidth;
        fh = CGRectGetHeight(rect) / ovalHeight;

        // CGContextAddArcToPoint adds an arc of a circle to the context's path (creating the rounded
        // corners).  It also adds a line from the path's last point to the begining of the arc, making
        // the sides of the rectangle.
        CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
        CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
        CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
        CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
        CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right

        // Close the path
        CGContextClosePath(context);

        // Restore the context's state. This removes the translation and scaling
        // but leaves the path, since the path is not part of the graphics state.
        CGContextRestoreGState(context);
}

void fillRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth, CGFloat
                                         ovalHeight)
{
        // Signal the start of a path
        CGContextBeginPath(context);
        // Add a rounded rect to the path
        addRoundedRectToPath(context, rect, ovalWidth, ovalHeight);
        // Fill the path
        CGContextFillPath(context);
}


/*
strokeRoundedRect : Draws a rounded rectangle with the current stroke color

Parameter Descriptions
rect : The CG rectangle that defines the rectangle's boundary.
ovalWidth : The width of the CG rectangle that encloses the rounded corners
ovalHeight : The height of the CG rectangle that encloses the rounded corners
context : The CG context to render to.
*/
void strokeRoundedRect(CGContextRef context, CGRect rect, CGFloat ovalWidth,
                                           CGFloat ovalHeight)
{

        // Signal the start of a path
        CGContextBeginPath(context);
        // Add a rounded rect to the path
        addRoundedRectToPath(context, rect, ovalWidth, ovalHeight);
        // Stroke the path
        CGContextStrokePath(context);
}

void pathForArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{
    CGFloat start, end;
    CGAffineTransform matrix;

        // Save the context's state because we are going to scale it
    CGContextSaveGState(context);

        // Create a transform to scale the context so that a radius of 1 maps to the bounds
        // of the rectangle, and transform the origin of the context to the center of
        // the bounding rectangle.
    matrix = CGAffineTransformMake(r.size.width/2, 0,
                                                                   0, r.size.height/2,
                                                                   r.origin.x + r.size.width/2,
                                                                   r.origin.y + r.size.height/2);

        // Apply the transform to the context
    CGContextConcatCTM(context, matrix);

        // Calculate the start and ending angles
    if (arcAngle > 0) {
                start = (90 - startAngle - arcAngle) * M_PI / 180;
                end = (90 - startAngle) * M_PI / 180;
    } else {
                start = (90 - startAngle) * M_PI / 180;
                end = (90 - startAngle - arcAngle) * M_PI / 180;
    }

        // Add the Arc to the path
    CGContextAddArc(context, 0, 0, 1, start, end, false);

        // Restore the context's state. This removes the translation and scaling
        // but leaves the path, since the path is not part of the graphics state.
    CGContextRestoreGState(context);
}


void frameArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{

        // Signal the start of a path
    CGContextBeginPath(context);

        // Add to the path the arc of the oval that fits inside the rectangle.
        pathForArc(context,r,startAngle,arcAngle);

        // Stroke the path
    CGContextStrokePath(context);
}

/*
paintArc : Paints a wedge of the oval that fits inside a rectangle.

Parameter Descriptions
context : The CG context to render to.
r : The CG rectangle that defines the arc's boundary..
startAngle : The angle indicating the start of the arc.
arcAngle : The angle indicating the arcÕs extent.
*/

void paintArc(CGContextRef context, CGRect r, int startAngle, int arcAngle)
{
        // Signal the start of a path
    CGContextBeginPath(context);

        // Set the start of the path to the arcs focal point
    CGContextMoveToPoint(context, r.origin.x + r.size.width/2, r.origin.y + r.size.height/2);

        // Add to the path the arc of the oval that fits inside the rectangle.
        pathForArc(context,r,startAngle,arcAngle);

        // Complete the path closing the arc at the focal point
    CGContextClosePath(context);

        // Fill the path
    CGContextFillPath(context);
}
