//
//  NCEufeItemModuleCell.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCEufeItemModuleCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *typeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *powerGridLabel;
@property (weak, nonatomic) IBOutlet UILabel *cpuLabel;
@property (weak, nonatomic) IBOutlet UILabel *calibrationLabel;

@end
