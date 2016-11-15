//
//  UIAlertController+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (NC)

+ (instancetype) alertControllerWithTitle:(NSString*) title error:(NSError*) error handler:(void (^)(UIAlertAction *action)) handler;
+ (instancetype) alertControllerWithError:(NSError*) error handler:(void (^)(UIAlertAction *action)) handler;


@end
