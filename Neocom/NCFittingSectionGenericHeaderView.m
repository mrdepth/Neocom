//
//  NCFittingSectionGenericHeaderView.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingSectionGenericHeaderView.h"
#import "UIColor+Neocom.h"

@implementation NCFittingSectionGenericHeaderView

- (void) awakeFromNib {
	self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
	self.backgroundView.backgroundColor = [UIColor appearanceTableViewHeaderViewBackgroundColor];
	self.backgroundView.opaque = NO;
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
