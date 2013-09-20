//
//  EUPopoverBackgroundView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.09.13.
//
//

#import "EUPopoverBackgroundView.h"
#import "appearance.h"

#define ARROW_HEIGHT 15
#define ARROW_BASE 30
#define CORNER_RADIUS 8

@interface EUPopoverBackgroundView()
@property (nonatomic, assign) CGFloat arrowOffset;
@property (nonatomic, assign) UIPopoverArrowDirection arrowDirection;
@property (nonatomic, strong) CAShapeLayer* mask;
@property (nonatomic, strong) CAShapeLayer* border;

@end

@implementation EUPopoverBackgroundView
@synthesize arrowDirection = _arrowDirection;
@synthesize arrowOffset = _arrowOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		//self.backgroundColor = [UIColor colorWithNumber:AppearanceNavigationBarColor];
		self.mask = [CAShapeLayer new];
		self.border = [CAShapeLayer new];
		self.border.strokeColor = [[UIColor colorWithNumber:@(0x1b1b1fff)] CGColor];
		self.border.fillColor = [[UIColor clearColor] CGColor];
		self.border.lineWidth = 1.0;
		self.layer.mask = self.mask;
		self.layer.masksToBounds = YES;
		self.layer.backgroundColor = [[UIColor colorWithNumber:AppearanceNavigationBarColor] CGColor];
		[self.layer addSublayer:self.border];
		self.border.zPosition = 10;
    }
    return self;
}

+ (CGFloat)arrowHeight {
	return ARROW_HEIGHT;
}

+ (CGFloat)arrowBase {
	return ARROW_BASE;
}

+ (UIEdgeInsets)contentViewInsets {
	return UIEdgeInsetsMake(4, 4, 4, 4);
}

- (void) layoutSubviews {
	UIBezierPath* path = [UIBezierPath new];
	if (self.arrowDirection == UIPopoverArrowDirectionUp) {
		[path moveToPoint:CGPointMake(0, self.bounds.size.height - CORNER_RADIUS)];
		[path addLineToPoint:CGPointMake(0, ARROW_HEIGHT + CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, ARROW_HEIGHT + CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI endAngle:-M_PI_2 clockwise:YES];
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset - ARROW_BASE / 2, ARROW_HEIGHT)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset, 0)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset + ARROW_BASE / 2, ARROW_HEIGHT)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width - CORNER_RADIUS, ARROW_HEIGHT)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, ARROW_HEIGHT + CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI_2 endAngle:0 clockwise:YES];
		[path addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height - CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:0 endAngle:M_PI_2 clockwise:YES];
		[path addLineToPoint:CGPointMake(CORNER_RADIUS, self.bounds.size.height)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:M_PI_2 endAngle:M_PI clockwise:YES];

		[path closePath];
	}
	else if (self.arrowDirection == UIPopoverArrowDirectionDown) {
		[path moveToPoint:CGPointMake(0, self.bounds.size.height - CORNER_RADIUS - ARROW_HEIGHT)];
		[path addLineToPoint:CGPointMake(0, CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI endAngle:-M_PI_2 clockwise:YES];
		[path addLineToPoint:CGPointMake(self.bounds.size.width - CORNER_RADIUS, 0)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI_2 endAngle:0 clockwise:YES];
		[path addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height - CORNER_RADIUS - ARROW_HEIGHT)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS - ARROW_HEIGHT) radius:CORNER_RADIUS startAngle:0 endAngle:M_PI_2 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset + ARROW_BASE / 2, self.bounds.size.height - ARROW_HEIGHT)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset, self.bounds.size.height)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width / 2 + self.arrowOffset - ARROW_BASE / 2, self.bounds.size.height - ARROW_HEIGHT)];

		[path addLineToPoint:CGPointMake(CORNER_RADIUS, self.bounds.size.height - ARROW_HEIGHT)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS - ARROW_HEIGHT) radius:CORNER_RADIUS startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
		
		[path closePath];
	}
	else if (self.arrowDirection == UIPopoverArrowDirectionRight) {
		[path moveToPoint:CGPointMake(0, self.bounds.size.height - CORNER_RADIUS)];
		[path addLineToPoint:CGPointMake(0, CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI endAngle:-M_PI_2 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(self.bounds.size.width - CORNER_RADIUS - ARROW_HEIGHT, 0)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS - ARROW_HEIGHT, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI_2 endAngle:0 clockwise:YES];

		[path addLineToPoint:CGPointMake(self.bounds.size.width - ARROW_HEIGHT,	self.bounds.size.height / 2 + self.arrowOffset - ARROW_BASE / 2)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width,				self.bounds.size.height / 2 + self.arrowOffset)];
		[path addLineToPoint:CGPointMake(self.bounds.size.width - ARROW_HEIGHT,	self.bounds.size.height / 2 + self.arrowOffset + ARROW_BASE / 2)];
		
		[path addLineToPoint:CGPointMake(self.bounds.size.width - ARROW_HEIGHT, self.bounds.size.height - CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS - ARROW_HEIGHT, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:0 endAngle:M_PI_2 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(CORNER_RADIUS, self.bounds.size.height)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
		
		[path closePath];
	}
	else if (self.arrowDirection == UIPopoverArrowDirectionLeft) {
		[path moveToPoint:CGPointMake(ARROW_HEIGHT, self.bounds.size.height - CORNER_RADIUS)];
		[path addLineToPoint:CGPointMake(ARROW_HEIGHT,	self.bounds.size.height / 2 + self.arrowOffset + ARROW_BASE / 2)];
		[path addLineToPoint:CGPointMake(0,				self.bounds.size.height / 2 + self.arrowOffset)];
		[path addLineToPoint:CGPointMake(ARROW_HEIGHT,	self.bounds.size.height / 2 + self.arrowOffset - ARROW_BASE / 2)];

		[path addLineToPoint:CGPointMake(ARROW_HEIGHT, CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS + ARROW_HEIGHT, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI endAngle:-M_PI_2 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(self.bounds.size.width - CORNER_RADIUS, 0)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, CORNER_RADIUS) radius:CORNER_RADIUS startAngle:-M_PI_2 endAngle:0 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(self.bounds.size.width, self.bounds.size.height - CORNER_RADIUS)];
		[path addArcWithCenter:CGPointMake(self.bounds.size.width - CORNER_RADIUS, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:0 endAngle:M_PI_2 clockwise:YES];
		
		[path addLineToPoint:CGPointMake(CORNER_RADIUS + ARROW_HEIGHT, self.bounds.size.height)];
		[path addArcWithCenter:CGPointMake(CORNER_RADIUS + ARROW_HEIGHT, self.bounds.size.height - CORNER_RADIUS) radius:CORNER_RADIUS startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
		
		[path closePath];
	}
	self.mask.path = [path CGPath];
	self.border.path = [path CGPath];
}

#pragma mark - Private

@end
