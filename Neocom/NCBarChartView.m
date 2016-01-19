//
//  NCBarChartView.m
//  Neocom
//
//  Created by Артем Шиманский on 18.01.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCBarChartView.h"

@implementation NCBarChartSegment;
@end

@interface NCBarChartView()
@property (nonatomic, strong) NSMutableArray* segments;

@end

@implementation NCBarChartView

- (id) init {
	if (self = [super init]) {
		self.segments = [NSMutableArray new];
	}
	return self;
}

- (void) awakeFromNib {
	self.segments = [NSMutableArray new];
	self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
	self.layer.borderWidth = 1.0;
}

- (void) addSegment:(NCBarChartSegment*) segment {
	[self.segments addObject:segment];
	[self setNeedsDisplay];
}

- (void) addSegments:(NSArray*) segments {
	[self.segments addObjectsFromArray:segments];
	[self setNeedsDisplay];
}


- (void) clear {
	[self.segments removeAllObjects];
	[self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	NSUInteger n = self.segments.count;
	for (NSUInteger i = 0; i < n; i++) {
		NCBarChartSegment* segment = _segments[i];
		CGFloat x = segment.x * rect.size.width;
		CGFloat w = segment.w * rect.size.width;
		
		CGFloat h0 = segment.h0 * w;
		CGFloat h1 = segment.h1 * w;
		
		while (i < n - 1 && w < 5) {
			NCBarChartSegment* segment = _segments[++i];
			CGFloat ww = segment.w *rect.size.width;
			w += ww;
			h0 += segment.h0 * ww;
			h1 += segment.h1 * ww;
		}
		
		h0 = (h0 / w) * rect.size.height;
		h1 = (h1 / w) * rect.size.height;

		CGFloat dx = 0;
		if (w >= 5) {
			w -= 2;
			dx = 1;
		}

		if (h0 > 0) {
			CGContextSetFillColorWithColor(context, segment.color0.CGColor);
			CGContextFillRect(context, CGRectMake(x + dx, rect.size.height - h0 , w, h0));
		}
		if (h1 > 0) {
			CGContextSetFillColorWithColor(context, segment.color1.CGColor);
			CGContextFillRect(context, CGRectMake(x + dx, rect.size.height - h0 - h1, w, h1));
		}
	}
}

@end
