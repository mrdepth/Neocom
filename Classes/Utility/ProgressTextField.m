//
//  ProgressTextField.m
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProgressTextField.h"

@implementation ProgressTextField
@synthesize progress;

- (void) awakeFromNib {
	self.color = self.backgroundColor;
	self.backgroundColor = [UIColor clearColor];
	self.progress = 0;
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	const float *components = CGColorGetComponents([self.color CGColor]);
	CGContextSetRGBFillColor(context, components[0] * 0.4, components[1] * 0.4, components[2] * 0.4, 1);
	CGContextFillRect(context, rect);
	
	float scale;
	if (self.progress > 1.0) {
		CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
		scale = 1;
	}
	else {
		CGContextSetFillColorWithColor(context, [self.color CGColor]);
		scale = self.progress;
	}
	CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width * scale, rect.size.height));
	
	CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
	CGContextStrokeRectWithWidth(context, rect, 1);
	[super drawRect:rect];
}

- (void) setProgress:(float)value {
	self.progress = value;
	[self setNeedsDisplay];
}

@end
