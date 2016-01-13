//
//  NCIncursionCell.h
//  Neocom
//
//  Created by Артем Шиманский on 05.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCIncursionCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *ownerImageView;
@property (weak, nonatomic) IBOutlet UILabel *ownerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *constellationLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet NCProgressLabel *influenceLabel;
@property (weak, nonatomic) IBOutlet UILabel *solarSystemLabel;
@property (weak, nonatomic) IBOutlet UIImageView *hasBossImageView;

@end
