//
//  NCDatabaseFetchedResultsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCDatabaseFetchedResultsViewController : NCTableViewController
@property (nonatomic, strong) NSFetchRequest* request;
@end
