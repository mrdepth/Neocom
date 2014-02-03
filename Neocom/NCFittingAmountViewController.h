//
//  NCFittingAmountViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCFittingAmountViewController : UITableViewController
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSInteger amount;
@property (nonatomic, assign) NSRange range;

@end
