//
//  NCLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 20.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@interface NCLabel()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UITapGestureRecognizer* recognizer;
- (void) onTap:(UITapGestureRecognizer*) recognizer;
- (NSURL*) urlAtPoint:(CGPoint) point;
@end

@implementation NCLabel

- (void) awakeFromNib {
	self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	self.recognizer.delegate = self;
	[self addGestureRecognizer:self.recognizer];
	self.tintColor = [UIColor whiteColor];
	self.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer == self.recognizer) {
		NSURL *url = [self urlAtPoint:[gestureRecognizer locationInView:self]];
		if (url)
			return YES;
		else
			return NO;
	}
	else	
		return YES;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if (otherGestureRecognizer == self.recognizer)
		return YES;
	else
		return NO;
}

#pragma mark - Private

- (void) onTap:(UITapGestureRecognizer*) recognizer {
	NSURL *url = [self urlAtPoint:[recognizer locationInView:self]];
	if (url)
		[[UIApplication sharedApplication] openURL:url];
}

- (NSURL*) urlAtPoint:(CGPoint) point {
	NSLayoutManager* manager = [[NSLayoutManager alloc] init];
	CGSize size = self.bounds.size;
	size.height += 10;
	NSTextContainer* container = [[NSTextContainer alloc] initWithSize:size];
	container.maximumNumberOfLines = self.numberOfLines;
	NSTextStorage* textStorage= [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
	[textStorage addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, textStorage.string.length)];
	[textStorage addLayoutManager:manager];
	[manager addTextContainer:container];
	
	NSUInteger i = [manager glyphIndexForPoint:point inTextContainer:container];
	if (i != NSNotFound) {
		NSURL* url = [self.attributedText attributesAtIndex:i effectiveRange:NULL][@"NSURL"];
		return url;
	}
	else
		return nil;
}

@end
