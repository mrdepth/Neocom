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
@property (weak, nonatomic) IBOutlet UIImageView* factoryIconView;
@property (weak, nonatomic) IBOutlet UILabel *effectivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *extrapolatedEffectivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *input1TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *input2TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *input3TitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *input1ShortageLabel;
@property (weak, nonatomic) IBOutlet UILabel *input2ShortageLabel;
@property (weak, nonatomic) IBOutlet UILabel *input3ShortageLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratioLabel;

@end
