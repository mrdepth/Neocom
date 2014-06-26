//
//  NCFittingResistancesCell.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NCProgressLabel.h"

@interface NCFittingResistancesCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView* categoryImageView;
@property (nonatomic, weak) IBOutlet NCProgressLabel *emLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *thermalLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *kineticLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *explosiveLabel;
@property (nonatomic, weak) IBOutlet UILabel* hpLabel;

@end
