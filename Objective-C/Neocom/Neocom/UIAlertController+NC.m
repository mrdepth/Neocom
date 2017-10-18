//
//  UIAlertController+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "UIAlertController+NC.h"

@implementation UIAlertController (NC)

+ (instancetype) alertControllerWithTitle:(NSString*) title error:(NSError*) error handler:(void (^)(UIAlertAction *action)) handler {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:title message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleCancel handler:handler]];
	return controller;
}

+ (instancetype) alertControllerWithError:(NSError*) error handler:(void (^)(UIAlertAction *action)) handler {
	return [self alertControllerWithTitle:NSLocalizedString(@"Error", nil) error:error handler:handler];
}


@end
