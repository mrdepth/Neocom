//
//  CollapsableTableHeaderView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 05.11.12.
//
//

#import "CollapsableTableHeaderView.h"

@implementation CollapsableTableHeaderView

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

- (void) setFrame:(CGRect)frame {
	[super setFrame:frame];
}

- (void) setCollapsed:(BOOL)value {
	_collapsed = value;
	self.collapsImageView.image = [UIImage imageNamed:value ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	self.titleLabel.frame = CGRectMake(10, 0, self.frame.size.width - 40, self.frame.size.height);
	self.collapsImageView.frame = CGRectMake(self.frame.size.width - 26, 0, 22, 22);
}

@end
