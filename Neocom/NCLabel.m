//
//  NCLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 20.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@implementation NCLabel

- (void) layoutSubviews {
	[super layoutSubviews];
	if (self.preferredMaxLayoutWidth != self.frame.size.width) {
		self.preferredMaxLayoutWidth = self.frame.size.width;
		[self invalidateIntrinsicContentSize];
		[self.superview setNeedsLayout];
		[self.superview layoutIfNeeded];
	}
}


@end
