//
//  NCLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 20.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@interface NCLabel()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIFont* defualtFont;
@property (nonatomic, strong) UIColor* defualtTextColor;
@property (nonatomic, strong) UITapGestureRecognizer* recognizer;

@property (nonatomic, strong) NSTextStorage* textStorage;
@property (nonatomic, strong) NSTextContainer* textContainer;
@property (nonatomic, strong) NSLayoutManager* layoutManager;

- (void) onTap:(UITapGestureRecognizer*) recognizer;
- (NSURL*) urlAtPoint:(CGPoint) point;
@end

@implementation NCLabel

- (void) awakeFromNib {
	[super awakeFromNib];
	self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
	self.recognizer.delegate = self;
	[self addGestureRecognizer:self.recognizer];
	self.tintColor = [UIColor whiteColor];
	self.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
	
	self.defualtFont = self.font;
	self.defualtTextColor = self.textColor;
}

- (void) setAttributedText:(NSAttributedString *)attributedText {
	NSMutableAttributedString* s = [attributedText mutableCopy];
	[attributedText enumerateAttributesInRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		__block BOOL hasFont = NO;
		__block BOOL hasColor = NO;
		[attrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([key isEqualToString:@"UIFontDescriptorSymbolicTraits"]) {
				UIFontDescriptor* fontDescriptor = [self.defualtFont.fontDescriptor fontDescriptorWithSymbolicTraits:[obj unsignedIntValue]];
				if (fontDescriptor) {
					UIFont* font = [UIFont fontWithDescriptor:fontDescriptor size:self.defualtFont.pointSize];
					if (font) {
						[s addAttribute:NSFontAttributeName value:font range:range];
						hasFont = YES;
					}
				}
			}
			else if ([key isEqualToString:@"NSURL"]) {
				UIFontDescriptor* fontDescriptor = [self.defualtFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
				UIFont* font = fontDescriptor ? [UIFont fontWithDescriptor:fontDescriptor size:self.defualtFont.pointSize] : self.defualtFont;
				[s addAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:font} range:range];
				hasFont = YES;
				hasColor = YES;
			}
			else if ([key isEqualToString:NSForegroundColorAttributeName])
				hasColor = YES;
		}];
		if (!hasFont) {
			UIFont* font = attrs[NSFontAttributeName];
			if (!font)
				[s addAttribute:NSFontAttributeName value:self.defualtFont range:range];
		}
		if (!hasColor)
			[s addAttribute:NSForegroundColorAttributeName value:self.defualtTextColor range:range];
	}];
	
	NSMutableParagraphStyle* paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraph.lineBreakMode = NSLineBreakByWordWrapping;
	[s addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, s.string.length)];
//	[s addAttribute:NSKernAttributeName value:[NSNull null] range:NSMakeRange(0, s.string.length)];
	[super setAttributedText:s];
	
	if (s) {
		self.textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
		self.textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.bounds.size.width, 1024)];
		self.textContainer.lineFragmentPadding = 0;
		self.layoutManager = [[NSLayoutManager alloc] init];
		self.textContainer.maximumNumberOfLines = self.numberOfLines;
		[self.textStorage addLayoutManager:self.layoutManager];
		[self.layoutManager setTextContainer:self.textContainer forGlyphRange:NSMakeRange(0, self.layoutManager.numberOfGlyphs)];
		[self.layoutManager addTextContainer:self.textContainer];
		//self.layoutManager.usesFontLeading = NO;
		//[self invalidateIntrinsicContentSize];
	}
	else {
		self.textStorage = nil;
		self.textContainer = nil;
		self.layoutManager = nil;
	}
}

//- (void) setText:(NSString *)text {
//	[self setAttributedText:[[NSAttributedString alloc] initWithString:text attributes:nil]];
//}

///- (void) drawRect:(CGRect)rect {
//	[super drawRect:rect];
//	[self.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.layoutManager.numberOfGlyphs) atPoint:rect.origin];
//}

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

//- (CGSize) intrinsicContentSize {
//	[self.layoutManager ensureLayoutForTextContainer:self.textContainer];
//	return [self.layoutManager usedRectForTextContainer:self.textContainer].size;
//}

#pragma mark - Private

- (void) onTap:(UITapGestureRecognizer*) recognizer {
	NSURL *url = [self urlAtPoint:[recognizer locationInView:self]];
	if (url)
		[[UIApplication sharedApplication] openURL:url];
}

- (NSURL*) urlAtPoint:(CGPoint) point {
	NSUInteger i = [self.layoutManager characterIndexForPoint:point inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
	if (i != NSNotFound) {
		NSURL* url = [self.attributedText attributesAtIndex:i effectiveRange:NULL][@"NSURL"];
		return url;
	}
	else
		return nil;
}

@end
