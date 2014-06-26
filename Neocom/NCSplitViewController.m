//
//  NCSplitViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 31.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSplitViewController.h"

@interface NCSplitViewController ()<UISplitViewControllerDelegate>
@property (nonatomic, strong) UIBarButtonItem* menuBarButtonItem;
@end

@implementation NCSplitViewController

- (void) awakeFromNib {
	self.delegate = self;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
	barButtonItem.image = [UIImage imageNamed:@"menuIcon.png"];
	UINavigationController* navigationController = [[self viewControllers] objectAtIndex:1];
	if ([navigationController isKindOfClass:[UINavigationController class]]) {
		[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:barButtonItem animated:YES];
	}
	self.masterPopover = pc;
	self.menuBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	UINavigationController* navigationController = [[self viewControllers] objectAtIndex:1];
	if ([navigationController isKindOfClass:[UINavigationController class]]) {
		[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:nil animated:YES];
	}
	self.masterPopover = nil;
	self.menuBarButtonItem = nil;
}

- (void) setViewControllers:(NSArray *)viewControllers {
	[super setViewControllers:viewControllers];
	UINavigationController* navigationController = [[self viewControllers] objectAtIndex:1];
	if ([navigationController isKindOfClass:[UINavigationController class]]) {
		[[[[navigationController viewControllers] objectAtIndex:0] navigationItem] setLeftBarButtonItem:self.menuBarButtonItem animated:YES];
	}
}

@end
