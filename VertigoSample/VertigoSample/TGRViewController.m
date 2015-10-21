//
//  TGRViewController.m
//  VertigoSample
//
//  Created by guille on 07/10/13.
//  Copyright (c) 2013 Guillermo Gonzalez. All rights reserved.
//

#import "TGRViewController.h"
#import "TGRImageViewController.h"
#import "TGRImageZoomAnimationController.h"

@interface TGRViewController () <UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TGRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.imageButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
}

#pragma mark - UIViewControllerTransitioningDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    if ([presented isKindOfClass:TGRImageViewController.class]) {
        return [[TGRImageZoomAnimationController alloc] initWithReferenceImageView:self.imageView];
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if ([dismissed isKindOfClass:TGRImageViewController.class]) {
        return [[TGRImageZoomAnimationController alloc] initWithReferenceImageView:self.imageView];
    }
    return nil;
}

#pragma mark - Private methods

- (IBAction)showImage {
    TGRImageViewController *viewController = [[TGRImageViewController alloc] initWithImage:[self.imageButton imageForState:UIControlStateNormal]];
    viewController.transitioningDelegate = self;
    viewController.modalPresentationCapturesStatusBarAppearance = YES;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)showAspectFitImage:(id)sender {
    TGRImageViewController *viewController = [[TGRImageViewController alloc] initWithImage:self.imageView.image];
    viewController.transitioningDelegate = self;
    viewController.modalPresentationCapturesStatusBarAppearance = self;
    [self presentViewController:viewController animated:YES completion:nil];
}
@end
