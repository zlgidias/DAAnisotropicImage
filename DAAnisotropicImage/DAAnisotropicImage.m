//
//  DAAnisotropicImage.m
//  DAAnisotropicImage
//
//  Created by Daniel Amitay on 6/26/12.
//  Copyright (c) 2012 Daniel Amitay. All rights reserved.
//

#import "DAAnisotropicImage.h"

@implementation DAAnisotropicImage

static CMMotionManager *motionManager = nil;
static NSOperationQueue *accelerometerQueue = nil;

static UIImage *base = nil;
static UIImage *dark = nil;
static UIImage *left = nil;
static UIImage *right = nil;

static CGFloat darkImageRotation = 0.0f;
static CGFloat leftImageRotation = 0.0f;
static CGFloat rightImageRotation = 0.0f;

+ (void)initialize
{
	if(self == [DAAnisotropicImage class])
	{
        motionManager = [[CMMotionManager alloc] init];
        motionManager.accelerometerUpdateInterval = 0.05f;
        accelerometerQueue = [[NSOperationQueue alloc] init];
        
        // These images will be accessed and drawn many times per second.
        // It is wise to allocate and retain them here to minimize future lag.
        // The difference is imperceptible, yet exists.
        
        base = [UIImage imageNamed:@"DAAnisotropicImage.bundle/base"];
        dark = [UIImage imageNamed:@"DAAnisotropicImage.bundle/dark"];
        left = [UIImage imageNamed:@"DAAnisotropicImage.bundle/left"];
        right = [UIImage imageNamed:@"DAAnisotropicImage.bundle/right"];
    }
}

+ (void)startAnisotropicUpdatesWithHandler:(DAAnisotropicBlock)block
{
    [motionManager startAccelerometerUpdatesToQueue:accelerometerQueue 
                                         withHandler:^(CMAccelerometerData *data, NSError *error) {
                                             UIImage *anisotropicImage = [self imageFromAccelerometerData:data];
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 block(anisotropicImage);
                                             });
                                         }];
}

+ (void)stopAnisotropicUpdates
{
    [motionManager stopAccelerometerUpdates];
}

+ (BOOL)anisotropicUpdatesActive
{
    return motionManager.accelerometerActive;
}

+ (UIImage *)imageFromAccelerometerData:(CMAccelerometerData *)data
{
    CGSize imageSize = base.size;
    CGPoint drawPoint = CGPointMake(-imageSize.width / 2.0f, -imageSize.height / 2.0f);
    
    if (UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0f);
    }
    else
    {
        UIGraphicsBeginImageContext(imageSize);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [base drawAtPoint:CGPointZero];
    CGContextTranslateCTM(context, imageSize.width / 2.0f, imageSize.height / 2.0f);
    
    // The following numbers are made up
    // They look OK, but there is definitely improvement to be made
    
    darkImageRotation = (darkImageRotation * 0.6f) + (data.acceleration.x * M_PI_2) * 0.4f;
    CGContextRotateCTM(context, darkImageRotation);
    [dark drawAtPoint:drawPoint];
    
    leftImageRotation = (leftImageRotation * 0.6f) + (data.acceleration.y * M_PI_2 - darkImageRotation) * 0.4f;
    CGContextRotateCTM(context, leftImageRotation);
    [left drawAtPoint:drawPoint];
    
    rightImageRotation = (rightImageRotation * 0.6f) + (data.acceleration.z * M_PI_2 - leftImageRotation) * 0.4f;
    CGContextRotateCTM(context, rightImageRotation);
    [right drawAtPoint:drawPoint];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

@end
