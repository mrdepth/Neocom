//
//  NCDatabaseRegionPickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 24.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@interface NCDatabaseRegionPickerViewController : NCTableViewController
@property (nonatomic, strong) NCDBMapRegion* selectedRegion;

@end
