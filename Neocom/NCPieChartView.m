//
//  NCPieChartView.m
//  Neocom
//
//  Created by Артем Шиманский on 17.11.15.
//  Copyright © 2015 Shimanski Artem. All rights reserved.
//

#import "NCPieChartView.h"

@interface NCPieChartLayer : CALayer
@property (nonatomic, strong) NSMutableArray* segmentLayers;
@property (nonatomic, strong) NSMutableArray* textLayers;

- (void) addSegment:(NCPieChartSegment*) segment animated:(BOOL) animated;
- (void) clear;
- (CGFloat) radius;
@end

@interface NCPieChartTextLayer : CALayer
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) double value;
@property (nonatomic, strong) NCPieChartSegment* segment;
- (NSAttributedString*) attributedString;
@end

@interface NCPieChartSegmentLayer : CALayer
@property (nonatomic, strong) NCPieChartSegment* segment;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat endAngle;
@end

@interface NCPieChartSegment()
@property (nonatomic, assign) double multiplier;
@end

@implementation NCPieChartSegment

+ (instancetype) segmentWithValue:(double) value color:(UIColor*) color numberFormatter:(NSNumberFormatter*) numberFormatter {
	return [[self alloc] initWithValue:value color:color numberFormatter:numberFormatter];
}

- (id) initWithValue:(double) value color:(UIColor*) color numberFormatter:(NSNumberFormatter*) numberFormatter {
	if (self = [super init]) {
		self.value = value;
		self.color = color;
		self.numberFormatter = [numberFormatter copy] ?: [NSNumberFormatter new];
		self.multiplier = [self.numberFormatter.multiplier doubleValue];
		self.numberFormatter.multiplier = @(1);
	}
	return self;
}


@end

@implementation NCPieChartLayer

- (id) init {
	if (self = [super init]) {
		self.segmentLayers = [NSMutableArray new];
		self.textLayers = [NSMutableArray new];
	}
	return self;
}

- (void) addSegment:(NCPieChartSegment*) segment animated:(BOOL) animated {
	NCPieChartSegmentLayer* segmentLayer = [NCPieChartSegmentLayer layer];
	[self addSublayer:segmentLayer];
	CGRect frame = self.bounds;
	CGFloat radius = self.radius;
	frame.origin.x = (frame.size.width - radius * 2) / 2;
	frame.origin.y = (frame.size.height - radius * 2) / 2;
	frame.size.width = frame.size.height = radius * 2;
	segmentLayer.frame = frame;
	segmentLayer.segment = segment;
	[self.segmentLayers insertObject:segmentLayer atIndex:0];
	
	NCPieChartTextLayer* textLayer = [NCPieChartTextLayer layer];
	textLayer.segment = segment;
	textLayer.radius = radius;
	textLayer.zPosition = 1;
	[self.textLayers insertObject:textLayer atIndex:0];
	[self addSublayer:textLayer];
	[segmentLayer displayIfNeeded];
	
	void (^layout)() = ^{
		CGFloat startAngle = -M_PI_2;
		double sum = [[self.segmentLayers valueForKeyPath:@"@sum.segment.value"] doubleValue];
		
		NSInteger i = 0;
		
		NSMutableDictionary* lengths = [NSMutableDictionary new];
		if (sum > 0) {
			CGFloat minLength = M_PI * 4 / 180;
			CGFloat left = M_PI * 2;
			
			for (NCPieChartSegmentLayer* layer in [self.segmentLayers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"segment.value" ascending:YES]]]) {
				CGFloat len = M_PI * 2 * (layer.segment.value / sum);
				len = MAX(len, minLength);
				len = MIN(len, left);
				left -= len;
				lengths[@((intptr_t) layer)] = @(len);
			}
		}
		
		for (NCPieChartSegmentLayer* layer in self.segmentLayers) {
			CGFloat endAngle;
			if (sum > 0) {
				CGFloat len = [lengths[@((intptr_t) layer)] floatValue];
				//endAngle = startAngle + M_PI * 2 * (layer.segment.value / sum);
				endAngle = startAngle + len;
			}
			else
				endAngle = 1.0 / self.segmentLayers.count * M_PI * 2;
			layer.startAngle = startAngle;
			layer.endAngle = endAngle;
			
			startAngle = layer.endAngle;
			NCPieChartTextLayer* textLayer = self.textLayers[i++];
			textLayer.angle = (layer.startAngle + layer.endAngle) / 2.0;
			textLayer.value = layer.segment.value;
		}
	};
	if (animated)
		dispatch_async(dispatch_get_main_queue(), ^{
			layout();
		});
	else
		layout();
	
}

- (void) clear {
	NSArray* layers = [self.sublayers copy];
	CATransition* transition = [CATransition animation];
	transition.type = kCATransitionFade;
	transition.duration = 0.25;
	for (CALayer* layer in layers) {
		[layer addAnimation:transition forKey:@"transition"];
		layer.hidden = YES;
	}
	[self.segmentLayers removeAllObjects];
	[self.textLayers removeAllObjects];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(transition.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		for (CALayer* layer in layers)
			[layer removeFromSuperlayer];
	});
}


- (void) layoutSublayers {
	[super layoutSublayers];
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	CGFloat radius = self.radius;
	
	CGRect frame = self.bounds;
	frame.origin.x = (frame.size.width - radius * 2) / 2;
	frame.origin.y = (frame.size.height - radius * 2) / 2;
	frame.size.width = frame.size.height = radius * 2;
	
	for (NCPieChartSegmentLayer* layer in self.segmentLayers)
		layer.frame = frame;
	
	for (NCPieChartTextLayer* layer in self.textLayers) {
		layer.radius = radius;
		layer.bounds = (CGRect){.size = [layer preferredFrameSize]};
		float angle = [layer.presentationLayer angle];
		float s = sin(angle);
		float c = cos(angle);
		
		CGPoint anchor;
		if (s < 0)
			anchor.y = 1;
		else
			anchor.y = 0;
		if (c > 0)
			anchor.x = 0;
		else
			anchor.x = 1;
		layer.anchorPoint = anchor;
		
		float y = round(self.bounds.size.height / 2 + s * layer.radius);
		float x = round(self.bounds.size.width / 2 + c * layer.radius);
		if (fpclassify(x) == FP_NAN)
			NSLog(@"123");
		layer.position = CGPointMake(x, y);
	};
	NSArray* layers = [self.textLayers sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"position.y" ascending:YES]]];
	
	NSUInteger n = layers.count;
	for (NSUInteger i = 0; i < n; i++) {
		NCPieChartTextLayer* first = layers[i];
		CGRect frame = first.frame;
		if (CGRectGetMaxX(frame) > self.bounds.size.width) {
			frame.size.width = self.bounds.size.width - frame.origin.x;
		}
		else if (CGRectGetMinX(frame) < 0) {
			frame.size.width += CGRectGetMinX(frame);
			frame.origin.x = 0;
		}
		if (CGRectGetMaxY(frame) > self.bounds.size.height) {
			frame.size.height = self.bounds.size.height - frame.origin.y;
		}
		else if (CGRectGetMinY(frame) < 0) {
			frame.size.height += CGRectGetMinY(frame);
			frame.origin.y = 0;
		}
		first.frame = frame;
		
		for (NSUInteger j = i + 1; j < n; j++) {
			NCPieChartTextLayer* second = layers[j];
			if (CGRectIntersectsRect(first.frame, second.frame)) {
				
				CGPoint p = second.position;
				p.y += CGRectGetMaxY(first.frame) - CGRectGetMinY(second.frame);
				int sign = p.x > self.bounds.size.width / 2 ? 1 : -1;
				if (first.radius > p.y - self.bounds.size.height / 2)
					p.x = self.bounds.size.width / 2 + sqrtf(pow(first.radius,2) - pow(p.y - self.bounds.size.height / 2, 2)) * sign;
				p.x = round(p.x);
				p.y = round(p.y);
				if (fpclassify(p.x) == FP_NAN)
					NSLog(@"123");

				second.position = p;
			}
		}
	}
	
	[CATransaction commit];
}

- (CGFloat) radius {
	CGRect bounds = self.bounds;
	UIFont* font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	
	CGFloat d = MIN(bounds.size.width * 2.0 / 4.0, bounds.size.height - font.lineHeight * 2);
	CGFloat radius = d / 2;
	return radius;
}


@end

@implementation NCPieChartSegmentLayer
@dynamic startAngle;
@dynamic endAngle;
@dynamic segment;

+ (BOOL) needsDisplayForKey:(NSString *)key {
	return [super needsDisplayForKey:key] || [key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"];
}

+ (id) defaultValueForKey:(NSString *)key {
	if ([key isEqualToString:@"startAngle"])
		return @(-M_PI_2);
	else if ([key isEqualToString:@"endAngle"])
		return @(-M_PI_2 + 0.001);
	else
		return [super defaultValueForKey:key];
}

- (id<CAAction>) actionForKey:(NSString *)event {
	if ([event isEqualToString:@"startAngle"] || [event isEqualToString:@"endAngle"]) {
		if (!self.presentationLayer)
			return nil;
		CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:event];
		animation.fromValue = [self.presentationLayer valueForKey:event];//[self.presentationLayer valueForKey:event] ?: [self.class defaultValueForKey:event];
		animation.duration = 1.0;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		return animation;
	}
	else
		return [super actionForKey:event];
}

- (id) init {
	if (self = [super init]) {
		self.contentsScale = [[UIScreen mainScreen] scale];
	}
	return self;
}

- (void) display {
	[super display];
}

- (void) drawInContext:(CGContextRef)ctx {
	float startAngle = self.startAngle;
	float endAngle = self.endAngle;
	float radius = self.bounds.size.width / 2;
	
	UIBezierPath* path = [UIBezierPath new];
	CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	[path moveToPoint:center];
	[path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:1];
	[path addLineToPoint:center];
	[path closePath];
	
	CGContextRef context = ctx;
	CGContextSetFillColorWithColor(context, self.segment.color.CGColor);
	CGContextAddPath(context, path.CGPath);
	CGContextFillPath(context);
}

@end

@implementation NCPieChartTextLayer
@dynamic radius;
@dynamic angle;
@dynamic value;
@dynamic segment;

+ (BOOL) needsDisplayForKey:(NSString *)key {
	return [super needsDisplayForKey:key] || [key isEqualToString:@"radius"] || [key isEqualToString:@"angle"] || [key isEqualToString:@"value"];
}

- (id) init {
	if (self = [super init]) {
		self.contentsScale = [[UIScreen mainScreen] scale];
	}
	return self;
}

- (void) display {
	[super display];
	[self.superlayer setNeedsLayout];
}

- (void) drawInContext:(CGContextRef)ctx {
	UIGraphicsPushContext(ctx);
	NSAttributedString* s = [self attributedString];
	NSStringDrawingContext* context = [NSStringDrawingContext new];
	context.minimumScaleFactor = 0.1;
	[s boundingRectWithSize:self.bounds.size options:NSStringDrawingUsesLineFragmentOrigin context:context];
	if (context.actualScaleFactor < 1.0)
		CGContextScaleCTM(ctx, context.actualScaleFactor, context.actualScaleFactor);
	CGSize size = s.size;
	size.width = ceil(size.width);
	size.height = ceil(size.height);
	[s drawInRect:(CGRect){.size = [s size]}];
	UIGraphicsPopContext();
}

- (CGSize) preferredFrameSize {
	CGSize size = [[self attributedString] size];
	size.width = ceil(size.width);
	size.height = ceil(size.height);
	return size;
}

- (NSAttributedString*) attributedString {
	NSString* text = [self.segment.numberFormatter stringFromNumber:@([(NCPieChartTextLayer*) self value] * self.segment.multiplier)];
	UIFont* font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
	NSAttributedString* s = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:self.segment.color, NSFontAttributeName:font}];
	return s;
}

+ (id) defaultValueForKey:(NSString *)key {
	if ([key isEqualToString:@"angle"])
		return @(-M_PI_2);
	else if ([key isEqualToString:@"value"])
		return @(0);
	else
		return [super defaultValueForKey:key];
}

- (id<CAAction>) actionForKey:(NSString *)event {
	if ([event isEqualToString:@"angle"] || [event isEqualToString:@"value"]) {
		if (!self.presentationLayer)
			return nil;
		CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:event];
		animation.fromValue = [self.presentationLayer valueForKey:event];
		animation.duration = 1.0;
		animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		return animation;
	}
	else
		return [super actionForKey:event];
}

@end

@interface NCPieChartView()
@end

@implementation NCPieChartView

+ (Class) layerClass {
	return [NCPieChartLayer class];
}

- (void) awakeFromNib {
	
}

- (void) addSegment:(NCPieChartSegment*) segment animated:(BOOL) animated {
	[(NCPieChartLayer*) self.layer addSegment:segment animated:animated];
}

- (void) clear {
	[(NCPieChartLayer*) self.layer clear];
}


@end
