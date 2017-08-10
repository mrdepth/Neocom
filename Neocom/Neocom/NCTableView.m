//
//  NCTableView.m
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableView.h"

@implementation NCTableView
//@dynamic backgroundColor;
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void) setTableBackgroundColor:(UIColor *)tableBackgroundColor {
	_tableBackgroundColor = tableBackgroundColor;
	[super setBackgroundColor:tableBackgroundColor];
}

@end
