//
//  NCTableViewHeaderCell.m
//  Neocom
//
//  Created by Artem Shimanski on 21.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewHeaderCell.h"

@implementation NCTableViewHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
	self.separatorInset = UIEdgeInsetsZero;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setExpanded:(BOOL)expanded animated:(BOOL)animated {
	self.expandIcon.image = [UIImage imageNamed:expanded ? @"collapse" : @"expand"];
}

@end
