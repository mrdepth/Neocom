//
//  NCFittingShipModulesTableHeaderView.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipModulesTableHeaderView.h"
#import "UIColor+Neocom.h"

@implementation NCFittingShipModulesTableHeaderView

- (void) awakeFromNib {
	self.backgroundColor = [UIColor appearanceTableViewHeaderViewBackgroundColor];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
