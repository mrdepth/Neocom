//
//  NCDatabaseTypePickerContentViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCDatabaseTypePickerContentViewController : NCTableViewController
@property (nonatomic, assign) int32_t groupID;
@property (nonatomic, strong) NSArray* groups;

@end
