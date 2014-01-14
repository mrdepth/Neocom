//
//  NCDatabaseCategoriesViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_ENUM(NSInteger, NCDatabaseFilter) {
	NCDatabaseFilterAll,
	NCDatabaseFilterPublished,
	NCDatabaseFilterUnpublished
};

@interface NCDatabaseCategoriesViewController : NCTableViewController
@property (nonatomic, assign) NCDatabaseFilter filter;

@end
