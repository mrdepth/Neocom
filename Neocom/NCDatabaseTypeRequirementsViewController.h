//
//  NCDatabaseTypeRequirementsViewController.h
//  Neocom
//
//  Created by Artem Shimanski on 04.03.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBInvType;
@interface NCDatabaseTypeRequirementsViewController : NCTableViewController
@property (nonatomic, strong) NCDBInvType* type;

@end
