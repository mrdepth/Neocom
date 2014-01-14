//
//  NCDatabaseViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "EVEDBAPI.h"

typedef NS_ENUM(NSInteger, NCDatabaseFilter) {
	NCDatabaseFilterAll,
	NCDatabaseFilterPublished,
	NCDatabaseFilterUnpublished
};

@interface NCDatabaseViewController : NCTableViewController
@property (nonatomic, assign) NCDatabaseFilter filter;
@property (nonatomic, strong) EVEDBInvCategory* category;
@property (nonatomic, strong) EVEDBInvGroup* group;

@end
