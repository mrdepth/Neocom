//
//  NCDatabaseCertificatesViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBInvGroup;
@interface NCDatabaseCertificatesViewController : NCTableViewController
@property (nonatomic, strong) NSManagedObjectID* groupID;

@end
