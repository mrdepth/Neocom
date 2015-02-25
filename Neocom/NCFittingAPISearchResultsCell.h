//
//  NCFittingAPISearchResultsCell.h
//  Neocom
//
//  Created by Артем Шиманский on 13.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@interface NCFittingAPISearchResultsCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *ehpLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tankTypeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *weaponTypeImageView;
@property (weak, nonatomic) IBOutlet UILabel *turretDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *droneDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *falloffLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *capacitorLabel;
@property (strong, nonatomic) id object;
@end
