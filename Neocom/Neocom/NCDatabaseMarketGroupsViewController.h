//
//  NCDatabaseMarketGroupsViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 20.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NCDBInvMarketGroup;
@interface NCDatabaseMarketGroupsViewController : UITableViewController
@property (nonatomic, strong) NCDBInvMarketGroup* parentGroup;
@end
