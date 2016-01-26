//
//  NCFactoryCell.h
//  Neocom
//
//  Created by Артем Шиманский on 26.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCProgressLabel.h"

@interface NCFactoryCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *productLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentCycleLabel;
@property (weak, nonatomic) IBOutlet NCProgressLabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *input1Label;
@property (weak, nonatomic) IBOutlet UILabel *input2Label;
@property (weak, nonatomic) IBOutlet UILabel *input3Label;
@property (weak, nonatomic) IBOutlet NCProgressLabel *inputProgress1Label;
@property (weak, nonatomic) IBOutlet NCProgressLabel *inputProgress2Label;
@property (weak, nonatomic) IBOutlet NCProgressLabel *inputProgress3Label;
@property (weak, nonatomic) IBOutlet UILabel *ratioLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;

@end
