//
//  DronesAmountViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DronesAmountViewControllerDelegate.h"


@interface DronesAmountViewController : UITableViewController
@property (nonatomic, assign) NSInteger maxAmount;
@property (nonatomic, assign) NSInteger amount;

@property (nonatomic, copy) void (^completionHandler)(NSInteger amount);
@end
