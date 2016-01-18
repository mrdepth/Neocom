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
	for (NCBarChartSegment* segment in self.segments) {
		CGContextMoveToPoint(context, segment.x * rect.size.width, rect.size.height);
		CGFloat w = segment.w * rect.size.width;
		if (w > 2)
			w -= 2;
		CGFloat h0 = segment.h0 * rect.size.height;
		CGFloat h1 = segment.h1 * rect.size.height;
		if (h0 > 0) {
			CGContextSetFillColorWithColor(context, segment.color0.CGColor);
			CGContextFillRect(context, CGRectMake(segment.x * rect.size.width, rect.size.height - h0, w, h0));
		}
		if (h1 > 0) {
			CGContextSetFillColorWithColor(context, segment.color1.CGColor);
			CGContextFillRect(context, CGRectMake(segment.x * rect.size.width, rect.size.height - h0 - h1, w, h1));
		}
	}
}

@end
