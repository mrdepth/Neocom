//
//  NCFittingDamagePatternCell.h
//  Neocom
//
//  Created by Артем Шиманский on 04.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCFittingDamagePatternCell : NCTableViewCell
@property (nonatomic, weak) IBOutlet UILabel* titleLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel* emLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel* kineticLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel* thermalLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel* explosiveLabel;

@end
