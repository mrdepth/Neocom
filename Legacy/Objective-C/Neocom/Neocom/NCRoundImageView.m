//
//  NCRoundImageView.m
//  Neocom
//
//  Created by Artem Shimanski on 13.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCRoundImageView.h"

@implementation NCRoundImageView




- (void) layoutSubviews {
	[super layoutSubviews];
	self.layer.cornerRadius = self.bounds.size.width / 2;
}

@end
