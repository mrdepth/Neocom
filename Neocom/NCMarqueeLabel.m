//
//  NCMarqueeLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 25.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCMarqueeLabel.h"

@interface NCTextLayer : CALayer
@property (nonatomic, strong) NSString* text;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) UIColor* textColor;
@end

@implementation NCTextLayer

+ (BOOL)needsDisplayForKey:(NSString *)key {
	return YES;
}

- (void) drawInContext:(CGContextRef)ctx {
	UIGraphicsPushContext(ctx);
	CGContextSetStrokeColorWithColor(ctx, [self.textColor CGColor]);
	CGContextSetFillColorWithColor(ctx, [self.textColor CGColor]);
	[self.text drawInRect:self.bounds withFont:self.font lineBreakMode:NSLineBreakByClipping];
	UIGraphicsPopContext();
}

@end


@interface NCMarqueeLabel()
@property (nonatomic, strong) CAAnimation* animation;

@end

@implementation NCMarqueeLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) awakeFromNib {
	CALayer* layer = [CALayer layer];
	[self.layer addSublayer:layer];
	layer.frame = self.layer.bounds;
	layer.contentsScale = self.contentScaleFactor;
}

- (void) setText:(NSString *)text {
	[super setText:text];
	[self setNeedsLayout];
	
	CGRect bounds = [self textRectForBounds:CGRectMake(0, 0, 2048, self.bounds.size.height) limitedToNumberOfLines:1];
	bounds.origin.x += 15;
	bounds.size.height = self.bounds.size.height;
	CALayer* layer = self.layer.sublayers[0];
	[layer removeAllAnimations];
	self.animation = nil;
	layer.frame = self.bounds;
	
	for (CALayer* subLayer in [layer.sublayers copy])
		[subLayer removeFromSuperlayer];
	
	if (self.text.length == 0)
		return;
	
	NCTextLayer* textLayer = [NCTextLayer new];
	textLayer.contentsScale = self.contentScaleFactor;
	textLayer.text = self.text;
	textLayer.textColor = self.textColor;
	textLayer.font = self.font;
	textLayer.frame = bounds;
	[layer addSublayer:textLayer];
	
	if (bounds.size.width + 30 > self.bounds.size.width) {
		bounds.origin.x += bounds.size.width + 10;
		textLayer.contentsScale = self.contentScaleFactor;
		textLayer = [NCTextLayer new];
		textLayer.text = self.text;
		textLayer.textColor = self.textColor;
		textLayer.font = self.font;
		textLayer.frame = bounds;
		[layer addSublayer:textLayer];
		CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform"];
		animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
		animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-bounds.size.width - 10, 0, 0)];
		animation.duration = 25.0;
		animation.repeatCount = HUGE_VALF;
		[layer addAnimation:animation forKey:@"transform"];
		self.animation = animation;
	}

}

- (void) drawRect:(CGRect)rect {
}

- (void) layoutSubviews {
	[super layoutSubviews];
}

- (void) didMoveToWindow {
	if (self.window) {
		if (self.animation) {
			CALayer* layer = self.layer.sublayers[0];
			[layer addAnimation:self.animation forKey:@"transform"];
		}
	}
	else {
		CALayer* layer = self.layer.sublayers[0];
		[layer removeAllAnimations];
	}
}

@end
