//
//  ContentView.m
//  EVEUniverse
//
//  Created by TANYA on 16.07.13.
//
//

#import "ContentView.h"
#import "UIColor+NSNumber.h"

@implementation ContentView

- (void) awakeFromNib {
	self.layer.shadowOffset = CGSizeMake(2, 2);
	self.layer.shadowOpacity = 1.0;
	//self.backgroundColor = [UIColor colorWithWhite:1.0 / 3.0 alpha:0.5];
	self.backgroundColor = [UIColor colorWithNumber:@(0x242328ff)];
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

- (void) setHighlighted:(BOOL)highlighted {
	_highlighted = highlighted;
	//self.backgroundColor = highlighted ? [UIColor colorWithWhite:2.0 / 3.0 alpha:0.5] : [UIColor colorWithWhite:1.0 / 3.0 alpha:0.5];
	self.backgroundColor = highlighted ? [UIColor colorWithNumber:@(0x2e2d33ff)] : [UIColor colorWithNumber:@(0x242328ff)];
}

@end
