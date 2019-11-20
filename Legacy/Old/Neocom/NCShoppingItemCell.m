//
//  NCShoppingItemCell.m
//  Neocom
//
//  Created by Artem Shimanski on 05.04.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCShoppingItemCell.h"

@interface NCShoppingItemCell()
@end

@implementation NCShoppingItemCell

- (void) awakeFromNib {
	[super awakeFromNib];
	self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
	self.backgroundView.backgroundColor = [UIColor clearColor];
//	self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
//	if (!highlighted && self.finished)
//		self.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
//	if (!selected && self.finished)
//		self.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
}

- (void) setFinished:(BOOL)finished {
	_finished = finished;
	if (finished)
		self.backgroundView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
	else
		self.backgroundView.backgroundColor = [UIColor clearColor];
}

- (void) setBackgroundColor:(UIColor *)backgroundColor {
	[super setBackgroundColor:backgroundColor];
}

@end
