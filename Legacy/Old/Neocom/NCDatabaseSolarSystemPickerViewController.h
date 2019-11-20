//
//  NCDatabaseSolarSystemPickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 27.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCDatabaseSolarSystemPickerViewController : NCTableViewController
@property (nonatomic, strong) NCDBMapRegion* region;
@property (nonatomic, strong) id selectedObject;
@end
