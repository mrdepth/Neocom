//
//  UIAlertController+Neocom.m
//  Neocom
//
//  Created by Артем Шиманский on 21.10.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "UIAlertController+Neocom.h"

@implementation UIAlertController (Neocom)

+ (instancetype) alertWithTitle:(NSString *)title message:(NSString *)message {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
	return controller;
}

+ (instancetype) alertWithError:(NSError *)error {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
	return controller;
}

+ (UIViewController*) frontMostViewController {
	UIViewController* frontMostViewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
	for (; frontMostViewController.presentedViewController; frontMostViewController = frontMostViewController.presentedViewController)
		if ([frontMostViewController.presentedViewController isKindOfClass:[UIAlertController class]])
			break;
	
	return frontMostViewController;
}

@end
