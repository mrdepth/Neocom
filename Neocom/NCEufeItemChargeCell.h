//
//  NCEufeItemChargeCell.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCEufeItemChargeCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;
@property (weak, nonatomic) IBOutlet UILabel *typeNameLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *emLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *thermalLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *kineticLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *explosiveLabel;
@property (nonatomic, weak) IBOutlet UILabel* damageLabel;

@end
