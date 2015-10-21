// TGRImageZoomAnimationController.m
//
// Copyright (c) 2013 Guillermo Gonzalez
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TGRImageZoomAnimationController.h"
#import <AVFoundation/AVFoundation.h>
#import "TGRImageViewController.h"
#import "TGRVertigoDestination.h"

#import "TGRImageViewController.h"
#import "UIImage+AspectFit.h"


@implementation TGRImageZoomAnimationController
- (id)initWithReferenceImageView:(UIImageView *)referenceImageView {
	if (self = [super init]) {
		NSAssert(referenceImageView.contentMode == UIViewContentModeScaleAspectFill ||
				 referenceImageView.contentMode == UIViewContentModeScaleAspectFit, @"*** referenceImageView must have a UIViewContentModeScaleAspectFill or UIViewContentModeScaleAspectFit contentMode!");
		_referenceImageView = referenceImageView;
	}
	return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	return viewController.isBeingPresented ? 0.5 : 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	if (viewController.isBeingPresented) {
		[self animateZoomInTransition:transitionContext];
	}
	else {
		[self animateZoomOutTransition:transitionContext];
	}
}

- (void)animateZoomInTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    // Get the view controllers participating in the transition
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController<TGRVertigoDestination> *toViewController = (TGRImageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSAssert([toViewController conformsToProtocol:@protocol(TGRVertigoDestination)], @"*** toViewController must conforms with  TGRVertigoDestination protocol!");
    
    // Get the final frame and set it to the final controller
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.frame = finalFrame;
    
    // Create the transition view and set the frame as the final one
    UIView * transitionView = [[UIView alloc] initWithFrame:finalFrame];
    [transitionContext.containerView addSubview:transitionView];
    
    // Snapshot of the from view
    self.referenceImageView.alpha = 0;
    UIView * fromSnapshot = [fromViewController.view snapshotViewAfterScreenUpdates:YES];
    [transitionView addSubview:fromSnapshot];
    
    // Hide destinationImageView and create an snapshot of the next view controller without it
    toViewController.destinationImageView.alpha = 0;
    UIView * toSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:YES];
    toSnapshot.alpha = 0;
    [transitionView addSubview:toSnapshot];
    
    // Animates the toSnapshot alpha
    [UIView animateWithDuration:0.3
                     animations:^{
                         toSnapshot.alpha = 1;
                     }];
    
    // Create the image snapshot
    UIImageView * destinationImageView = toViewController.destinationImageView;
    CGRect imageViewInitialFrame;
    if (self.referenceImageView.contentMode == UIViewContentModeScaleAspectFit) {
        imageViewInitialFrame = AVMakeRectWithAspectRatioInsideRect(self.referenceImageView.image.size, self.referenceImageView.frame);
    }
    
    else {
        imageViewInitialFrame = [fromViewController.view convertRect:self.referenceImageView.bounds
                                    fromView:self.referenceImageView];
    }
    
    
    UIImageView * transitionImageView = [[UIImageView alloc] initWithFrame:imageViewInitialFrame];
    transitionImageView.clipsToBounds = YES;
    transitionImageView.image = destinationImageView.image;
    transitionImageView.contentMode = destinationImageView.contentMode;
    [transitionView addSubview:transitionImageView];
    
    // Calculate destination view controller frame
    CGRect imgeViewFinalFrame = toViewController.destinationImageView.frame;
    
    // Animate the image position
    [UIView animateWithDuration:0.6
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         transitionImageView.frame = imgeViewFinalFrame;
                     }
                     completion:^(BOOL finished) {
                         // Remove transition view
                         [transitionView removeFromSuperview];
                         
                         // Add the destination view
                         [transitionContext.containerView addSubview:toViewController.view];
                         toViewController.destinationImageView.alpha = 1;
                         
                         // mark as complete
                         [transitionContext completeTransition:YES];
                     }];
}


- (void)animateZoomOutTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
	// Get the view controllers participating in the transition
	UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
	TGRImageViewController *fromViewController = (TGRImageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
	NSAssert([fromViewController isKindOfClass:TGRImageViewController.class], @"*** fromViewController must be a TGRImageViewController!");
	
	// The toViewController view will fade in during the transition
	toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
	toViewController.view.alpha = 0;
	[transitionContext.containerView addSubview:toViewController.view];
	[transitionContext.containerView sendSubviewToBack:toViewController.view];
	
	// Compute the initial frame for the temporary view based on the image view
    // of the TGRImageViewController
    CGRect transitionViewInitialFrame = [fromViewController.imageView.image tgr_aspectFitRectForSize:fromViewController.imageView.bounds.size];
    transitionViewInitialFrame = [transitionContext.containerView convertRect:transitionViewInitialFrame
                                                                     fromView:fromViewController.imageView];
    
    CGRect transitionViewFinalFrame;
    
    // Compute the final frame for the temporary view based on the reference
    if (self.referenceImageView.contentMode == UIViewContentModeScaleAspectFit) {
        CGRect imageFrame = [self.referenceImageView.image tgr_aspectFitRectForSize:self.referenceImageView.frame.size];
        transitionViewFinalFrame = [transitionContext.containerView convertRect:imageFrame
                                                                       fromView:self.referenceImageView];
    }
    
    else {
        transitionViewFinalFrame = [transitionContext.containerView convertRect:self.referenceImageView.bounds
                                                                       fromView:self.referenceImageView];
    }
    
    if (UIApplication.sharedApplication.isStatusBarHidden && ![toViewController prefersStatusBarHidden]) {
        transitionViewFinalFrame = CGRectOffset(transitionViewFinalFrame, 0, 20);
    }
    
    // Create a temporary view for the zoom out transition based on the image
    // view controller contents
	UIImageView *transitionView = [[UIImageView alloc] initWithImage:fromViewController.imageView.image];
	transitionView.contentMode = UIViewContentModeScaleAspectFill;
	transitionView.clipsToBounds = YES;
	transitionView.frame = transitionViewInitialFrame;
	[transitionContext.containerView addSubview:transitionView];
	[fromViewController.view removeFromSuperview];
	
	// Perform the transition
	NSTimeInterval duration = [self transitionDuration:transitionContext];
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 toViewController.view.alpha = 1;
						 transitionView.frame = transitionViewFinalFrame;
					 } completion:^(BOOL finished) {
						 self.referenceImageView.alpha = 1;
						 [transitionView removeFromSuperview];
						 [transitionContext completeTransition:YES];
					 }];
}


@end
