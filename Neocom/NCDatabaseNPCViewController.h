//
//  NCDatabaseNPCViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 27.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCDBNpcGroup;
@interface NCDatabaseNPCViewController : NCTableViewController
@property (nonatomic, strong) NCDBNpcGroup* npcGroup;

@end
