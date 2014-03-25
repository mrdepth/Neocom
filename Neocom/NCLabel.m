//
//  NCLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 20.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@interface NCLabel()
@property (nonatomic, strong) NSLayoutConstraint* widthConstraint;
@end

@implementation NCLabel

- (void) awakeFromNib {
	self.widthConstraint = [NSLayoutConstraint constraintWithItem:self
														attribute:NSLayoutAttributeWidth
														relatedBy:NSLayoutRelationEqual
														   toItem:nil
														attribute:0
													   multiplier:1
														 constant:self.bounds.size.width];
	self.widthConstraint.priority = UILayoutPriorityFittingSizeLevel;
	[self addConstraint:self.widthConstraint];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	self.widthConstraint.constant = self.bounds.size.width;
	self.preferredMaxLayoutWidth = self.frame.size.width;
}

@end
