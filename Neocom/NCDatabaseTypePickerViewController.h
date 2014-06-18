//
//  NCDatabaseTypePickerViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+Neocom.h"

@class EVEDBInvType;
@class NCDBEufeItemCategory;
@class NCDBInvType;
@interface NCDatabaseTypePickerViewController : UINavigationController

- (void) presentWithConditions:(NSArray*) conditions inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(EVEDBInvType* type)) completion;
- (void) presentWithCategory:(NCDBEufeItemCategory*) category inViewController:(UIViewController*) controller fromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated completionHandler:(void(^)(NCDBInvType* type)) completion;

@end
