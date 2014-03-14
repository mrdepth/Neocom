//
//  NCDatabaseGroupPickerViewContoller.h
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCDatabaseGroupPickerViewContoller : NCTableViewController
@property (nonatomic, assign) int32_t categoryID;
@property (nonatomic, strong) EVEDBInvGroup* selectedGroup;

@end
