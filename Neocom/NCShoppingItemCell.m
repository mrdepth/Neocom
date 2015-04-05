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
	self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
}

@end
