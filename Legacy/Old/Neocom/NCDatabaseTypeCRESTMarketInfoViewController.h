//
//  NCDatabaseTypeCRESTMarketInfoViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 24.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_ENUM(NSInteger, NCDatabaseTypeCRESTMarketInfoViewControllerMode) {
	NCDatabaseTypeCRESTMarketInfoViewControllerModeSell,
	NCDatabaseTypeCRESTMarketInfoViewControllerModeBuy
};


@interface NCDatabaseTypeCRESTMarketInfoViewController : NCTableViewController
@property (nonatomic, strong) NSManagedObjectID* typeID;
@property (nonatomic, strong) NSManagedObjectID* regionID;
@property (nonatomic, assign) NCDatabaseTypeCRESTMarketInfoViewControllerMode mode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *regionBarButtonItem;
- (IBAction)onChangeMode:(id)sender;
@end
