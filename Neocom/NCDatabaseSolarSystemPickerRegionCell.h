//
//  NCDatabaseSolarSystemPickerRegionCell.h
//  Neocom
//
//  Created by Артем Шиманский on 08.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCDatabaseSolarSystemPickerRegionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) id object;
@end
