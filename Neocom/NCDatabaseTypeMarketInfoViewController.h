//
//  NCDatabaseTypeMarketInfoViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 17.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_ENUM(NSInteger, NCDatabaseTypeMarketInfoViewControllerMode) {
	NCDatabaseTypeMarketInfoViewControllerModeSummary,
	NCDatabaseTypeMarketInfoViewControllerModeSellOrders,
	NCDatabaseTypeMarketInfoViewControllerModeBuyOrders
};

@interface NCDatabaseTypeMarketInfoViewController : NCTableViewController
@property (nonatomic, strong) NCDBInvType* type;

@property (nonatomic, assign) NCDatabaseTypeMarketInfoViewControllerMode mode;

- (IBAction)onChangeMode:(id)sender;

@end
