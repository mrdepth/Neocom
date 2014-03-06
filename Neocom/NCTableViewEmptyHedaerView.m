//
//  NCTableViewEmptyHedaerView.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewEmptyHedaerView.h"

@implementation NCTableViewEmptyHedaerView

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
		self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		//self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		self.backgroundView.backgroundColor = [UIColor clearColor];
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
