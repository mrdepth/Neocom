//
//  NCDatabaseMarketViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 18.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "EVEDBAPI.h"

@interface NCDatabaseMarketViewController : NCTableViewController
@property (nonatomic, strong) EVEDBInvMarketGroup* marketGroup;

@end
