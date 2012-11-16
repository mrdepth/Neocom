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

- (void) setCollapsed:(BOOL)value {
	_collapsed = value;
	self.collapsImageView.image = [UIImage imageNamed:value ? @"Icons/icon105_04.png" : @"Icons/icon105_05.png"];
}

- (void)dealloc {
    [_titleLabel release];
    [_collapsImageView release];
    [super dealloc];
}

@end
