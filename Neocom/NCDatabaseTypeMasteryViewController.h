//
//  NCDatabaseTypeMasteryViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 22.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "EVEDBAPI.h"

@interface NCDatabaseTypeMasteryViewController : NCTableViewController
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, assign) NSInteger masteryLevel;

@end
