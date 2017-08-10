//
//  NCTableViewCell.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCLabel.h"



@implementation NCTableViewCell

- (void) awakeFromNib {
	[super awakeFromNib];
	for (NSLayoutConstraint* constraint in self.contentView.constraints) {
		if (constraint.firstAttribute == NSLayoutAttributeBottom) {
			if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
				[self.contentView removeConstraint:constraint];
			}
			else
				constraint.priority = 999;
			break;
		}
	}
}

- (void) layoutSubviews {
	[super layoutSubviews];
	[self.contentView layoutIfNeeded];
}


@end
