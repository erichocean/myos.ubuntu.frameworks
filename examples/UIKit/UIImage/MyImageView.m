/*
 * Copyright (c) 2012-2013. All rights reserved.
 *
 */

#import "MyImageView.h"
#import "AppDelegate.h"

#define kImageSize           125
#define kSmallValue          0.0001
#define kDisplayTimeInterval 1.0/60

@implementation MyImageView

@synthesize imageView;

#pragma mark - Life cycle

- (id)initWithFrame:(CGRect)theFrame
{
    self = [super initWithFrame:theFrame];
    if (self) {
        self.backgroundColor = [UIColor greenColor];
        self.layer.masksToBounds = YES;
        self.imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sunglass.png"]] autorelease];
        //self.imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cuckoo.png"]] autorelease];
        self.imageView.frame = CGRectMake(70,70,kImageSize,kImageSize);
        [self addSubview:imageView];

        // Single tap gesture
        UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapped:)] autorelease];
        [self addGestureRecognizer:singleTap];

        // Double tap gesture
        UITapGestureRecognizer *doubleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)] autorelease];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        
        // Pan gesture
        UIPanGestureRecognizer *panGesture = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMoved:)] autorelease];
        [self addGestureRecognizer:panGesture];
        [singleTap requireGestureRecognizerToFail:panGesture];
        [doubleTap requireGestureRecognizerToFail:panGesture];

        self.superview.alpha = 0.0;
        self.alpha = 0.0;
        self.imageView.alpha = 0.0;
        [UIView beginAnimations:@"animateOpacity" context:nil];
        [UIView setAnimationDuration:2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.superview.alpha = 1.0;
        self.alpha = 1;
        self.imageView.alpha = 1;
        [UIView commitAnimations];

        [UIView beginAnimations:@"animateContent" context:nil];
        [UIView setAnimationDelay:2];
        [UIView setAnimationDuration:2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.imageView.image = [UIImage imageNamed:@"cuckoo.png"];
        [UIView commitAnimations];
    }
    return self;
}

#pragma mark - Actions

- (void)singleTapped:(id)sender
{
    UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
    //DLog(@"gesture: %@", gesture);
    //DLog(@"locationInView: %@", NSStringFromCGPoint([gesture locationInView:self]));
    
    [UIView beginAnimations:@"moveTheImage" context:nil];
    [UIView setAnimationDuration:0.5];
    //[UIView setAnimationCurve:UIViewAnimationCurveLinear];
    //[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    imageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    self.imageView.center = [gesture locationInView:self];
    //DLog(@"self.imageView.center: %@", NSStringFromCGPoint(self.imageView.center));
    
    [UIView commitAnimations];
}

- (void)doubleTapped:(id)sender
{
    UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
    //DLog(@"gesture: %@", gesture);
    
    CGPoint pointInImage = [gesture locationInView:self.imageView];
    //CGPoint pointInView = [gesture locationInView:self];
    //DLog(@"pointInView: %@", NSStringFromCGPoint(pointInView));
    //DLog(@"locationInImage: %@", NSStringFromCGPoint(pointInImage));
    if ([self.imageView pointInside:pointInImage withEvent:nil]) {
        //DLog(@"inside!");
        self.imageView.center = [gesture locationInView:self];
        //DLog(@"self.imageView.center: %@", NSStringFromCGPoint(self.imageView.center));
        imageView.layer.anchorPoint = CGPointMake(pointInImage.x/imageView.bounds.size.width, 1-pointInImage.y/imageView.bounds.size.height);
        [UIView beginAnimations:@"zoomInTheImage" context:nil];
        [UIView setAnimationDuration:0.5];
        
        //self.imageView.layer.position = [gesture locationInView:self];
        if (fabs(imageView.frame.size.width-kImageSize) < kSmallValue) {
            //DLog(@"imageView.layer.anchorPoint: %@", NSStringFromCGPoint(imageView.layer.anchorPoint));
            //            imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y,
            //	                                      kImageSize*1.5, kImageSize*1.5);
            imageView.bounds = CGRectMake(0, 0, kImageSize*1.3, kImageSize*1.3);
            
        } else {
            imageView.bounds = CGRectMake(0, 0, kImageSize, kImageSize);
        }
        [UIView commitAnimations];
    } else {
        //[self singleTapped:sender];
//        [gesture reset];
    }
} 

- (void)panMoved:(id)sender
{
    UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
//    DLog(@"gesture: %@", gesture);
    CGPoint pointInView = [gesture locationInView:self];
    CGPoint pointInImage = [gesture locationInView:imageView];
    //DLog(@"pointInView: %@", NSStringFromCGPoint(pointInView));
    if (![self.imageView pointInside:pointInImage withEvent:nil]) {
        return;
    }
    //DLog(@"gesture: %@", gesture);
    if (gesture.state == UIGestureRecognizerStateBegan && [self.imageView pointInside:pointInImage withEvent:nil]) {
        imageView.center = pointInView;
        firstY = imageView.center.y;
        previousTimestamp = CACurrentMediaTime();
        //DLog(@"firstY: %f", firstY);
        imageView.layer.anchorPoint = CGPointMake(pointInImage.x/imageView.bounds.size.width, 1-pointInImage.y/imageView.bounds.size.height);
    } /*else if (gesture.state == UIGestureRecognizerStateEnded) {
        imageView.center = CGPointMake(pointInView.x, pointInView.y);
    }*/ else {
        //DLog(@"imageView.center: %@", NSStringFromCGPoint(imageView.center));
        NSTimeInterval currentTime = CACurrentMediaTime();
        if ((currentTime - previousTimestamp) >= kDisplayTimeInterval) {
            previousTimestamp = CACurrentMediaTime();
            //DLog(@"currentTime: %f", currentTime);
            imageView.center = CGPointMake(pointInView.x, firstY);
            //imageView.center = CGPointMake(pointInView.x, pointInView.y);
            //DLog(@"imageView.center: %@", NSStringFromCGPoint(imageView.center));
        }
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        //DLog();
        //        imageView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        [UIView beginAnimations:@"adjustImagePosition" context:nil];
        [UIView setAnimationDuration:0.25];
        float xDifference = imageView.bounds.size.width/2.0 - pointInImage.x;
        if (pointInView.x > kParentFrameSize/2) {
            self.imageView.center = CGPointMake(kParentFrameSize/4.0*3.0 - xDifference, firstY);
        } else {
            self.imageView.center = CGPointMake(kParentFrameSize/4.0 - xDifference, firstY);
        }
        [UIView commitAnimations];
    }
}

@end

