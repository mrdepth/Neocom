//
//  NCDatabaseTypeVariationsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 16.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBInvType;
@interface NCDatabaseTypeVariationsViewController : NCTableViewController
@property (nonatomic, strong) NCDBInvType* type;

@end
