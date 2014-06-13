//
//  NCDatabaseViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCDatabase.h"

typedef NS_ENUM(NSInteger, NCDatabaseFilter) {
	NCDatabaseFilterAll,
	NCDatabaseFilterPublished,
	NCDatabaseFilterUnpublished
};

@interface NCDatabaseViewController : NCTableViewController
@property (nonatomic, assign) NCDatabaseFilter filter;
@property (nonatomic, strong) NCDBInvCategory* category;
@property (nonatomic, strong) NCDBInvGroup* group;
- (IBAction)onFilter:(id)sender;

@end
