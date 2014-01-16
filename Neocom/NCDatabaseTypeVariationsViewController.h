//
//  NCDatabaseTypeVariationsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 16.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class EVEDBInvType;
@interface NCDatabaseTypeVariationsViewController : NCTableViewController
@property (nonatomic, strong) EVEDBInvType* type;

@end
