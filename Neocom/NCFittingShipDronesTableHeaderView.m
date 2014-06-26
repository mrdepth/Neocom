//
//  NCFittingShipDronesTableHeaderView.m
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipDronesTableHeaderView.h"
#import "UIColor+Neocom.h"

@implementation NCFittingShipDronesTableHeaderView

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
