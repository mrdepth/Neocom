//
//  NCAccountsCell.m
//  Neocom
//
//  Created by Artem Shimanski on 15.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCAccountsCell.h"
#import "UIColor+CS.h"

@implementation NCAccountsCell

- (void)awakeFromNib {
    [super awakeFromNib];
	CALayer* layer = self.trainingProgressView.superview.layer;
	layer.borderColor = [UIColor colorWithUInteger:0x3d5866ff].CGColor;
	layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
