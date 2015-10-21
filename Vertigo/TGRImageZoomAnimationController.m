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
    
    UIViewController<TGRVertigoDestination> *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    NSAssert([toViewController conformsToProtocol:@protocol(TGRVertigoDestination)], @"*** toViewController must conforms with  TGRVertigoDestination protocol!");
    
    [self animateTransitionFromImageView:self.referenceImageView
                             toImageView:toViewController.destinationImageView
                             withContext:transitionContext];
    
}


- (void)animateZoomOutTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController<TGRVertigoDestination> *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    NSAssert([fromViewController conformsToProtocol:@protocol(TGRVertigoDestination)], @"*** fromViewController must conforms with  TGRVertigoDestination protocol!");
    
    [self animateTransitionFromImageView:fromViewController.destinationImageView
                             toImageView:self.referenceImageView
                             withContext:transitionContext];
}

- (void) animateTransitionFromImageView:(UIImageView *) fromImageView toImageView:(UIImageView *) toImageView withContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    // Get the view controllers participating in the transition
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Get the final frame and set it to the final controller
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.frame = finalFrame;
    
    // Create the transition view and set the frame as the final one
    UIView * transitionView = [[UIView alloc] initWithFrame:finalFrame];
    [transitionContext.containerView addSubview:transitionView];
    
    // Snapshot of the from view
    fromImageView.alpha = 0;
    
    // Hide destinationImageView and create an snapshot of the next view controller without it
    toImageView.alpha = 0;
    UIView * toSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:YES];
    toSnapshot.alpha = 0;
    [transitionView addSubview:toSnapshot];
    
    CGFloat duration = 5;
    // Animates the toSnapshot alpha
    [UIView animateWithDuration:duration/2
                     animations:^{
                         toSnapshot.alpha = 1;
                     }];
    
    // Create the image snapshot
    CGRect imageViewInitialFrame;
    if (fromImageView.contentMode == UIViewContentModeScaleAspectFit) {
        imageViewInitialFrame = AVMakeRectWithAspectRatioInsideRect(fromImageView.image.size, fromImageView.frame);
    }
    
    else {
        imageViewInitialFrame = [fromViewController.view convertRect:fromImageView.bounds
                                                            fromView:fromImageView];
    }
    
    
    UIImageView * transitionImageView = [[UIImageView alloc] initWithFrame:imageViewInitialFrame];
    transitionImageView.clipsToBounds = YES;
    transitionImageView.image = toImageView.image;
    transitionImageView.contentMode = toImageView.contentMode;
    [transitionView addSubview:transitionImageView];
    
    // Calculate destination view controller frame
    CGRect imgeViewFinalFrame = toImageView.frame;
    
    // Animate the image position
    [UIView animateWithDuration:duration
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
                         toImageView.alpha = 1;
                         
                         // mark as complete
                         [transitionContext completeTransition:YES];
                     }];
}

@end
