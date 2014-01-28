//
//  NCDatabaseTypePickerViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEDBInvType;
@interface NCDatabaseTypePickerViewController : UINavigationController

- (void) presentWithConditions:(NSArray*) conditions inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(EVEDBInvType* type)) completion;

@end
