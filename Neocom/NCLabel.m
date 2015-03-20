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

- (void) setAttributedText:(NSAttributedString *)attributedText {
	NSMutableAttributedString* s = [attributedText mutableCopy];
	[attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		__block BOOL hasFont = NO;
		[attrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([key isEqualToString:@"UIFontDescriptorSymbolicTraits"]) {
				UIFontDescriptor* fontDescriptor = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:[obj unsignedIntValue]];
				if (fontDescriptor) {
					UIFont* font = [UIFont fontWithDescriptor:fontDescriptor size:self.font.pointSize];
					if (font) {
						[s addAttribute:NSFontAttributeName value:font range:range];
						hasFont = YES;
					}
				}
			}
			else if ([key isEqualToString:@"NSURL"]) {
				UIFontDescriptor* fontDescriptor = [self.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
				UIFont* font = fontDescriptor ? [UIFont fontWithDescriptor:fontDescriptor size:self.font.pointSize] : self.font;
				[s addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:font} range:range];
				hasFont = YES;
			}
		}];
		if (!hasFont) {
			UIFont* font = attrs[NSFontAttributeName];
			if (!font)
				[s addAttribute:NSFontAttributeName value:self.font range:range];
		}
	}];
	
	NSMutableParagraphStyle* paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.lineBreakMode = self.lineBreakMode;
//	[s addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, s.string.length)];
//	[s addAttribute:NSKernAttributeName value:[NSNull null] range:NSMakeRange(0, s.string.length)];
	[super setAttributedText:s];
}

- (void) drawRect:(CGRect)rect {
//	[super drawRect:rect];
	NSLayoutManager* manager = [[NSLayoutManager alloc] init];
	CGSize size = self.bounds.size;
	size.height *= 2;
	NSTextContainer* container = [[NSTextContainer alloc] initWithSize:size];
	NSTextStorage* textStorage= [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
	[manager addTextContainer:container];
	[textStorage addLayoutManager:manager];
	
	container.maximumNumberOfLines = self.numberOfLines;
	
	
	[textStorage addLayoutManager:manager];
	[manager addTextContainer:container];
	
	//rect.size = [manager usedRectForTextContainer:container].size;
	
	//[textStorage drawWithRect:rect options:0 context:nil];
	[textStorage drawInRect:rect];
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
	size.height *= 2;
	NSTextContainer* container = [[NSTextContainer alloc] initWithSize:size];
	NSTextStorage* textStorage= [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
	[manager addTextContainer:container];
	[textStorage addLayoutManager:manager];

	container.maximumNumberOfLines = self.numberOfLines;
	
	
//	[textStorage addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, textStorage.string.length)];
//	[textStorage addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, textStorage.string.length)];
	
	
	
	CGFloat f = 0;
	//NSUInteger i = [manager glyphIndexForPoint:point inTextContainer:container fractionOfDistanceThroughGlyph:&f];
	NSUInteger i = [manager characterIndexForPoint:point inTextContainer:container fractionOfDistanceBetweenInsertionPoints:&f];
	NSLog(@"%f", f);
	CGRect r = [manager usedRectForTextContainer:container];
	CGRect r2 = [self textRectForBounds:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height * 2) limitedToNumberOfLines:0];
	if (i != NSNotFound) {
		NSLog(@"%@", [textStorage.string substringFromIndex:i]);
		NSURL* url = [self.attributedText attributesAtIndex:i effectiveRange:NULL][@"NSURL"];
		return url;
	}
	else
		return nil;
}

@end
