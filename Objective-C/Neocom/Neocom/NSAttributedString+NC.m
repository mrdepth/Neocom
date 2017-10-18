//
//  NSAttributedString+NC.m
//  Neocom
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NSAttributedString+NC.h"
#import "unitily.h"
#import "UIColor+CS.h"


@implementation NSAttributedString (NC)

- (NSAttributedString*) uppercaseString {
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:[self.string uppercaseString] attributes:nil];
	[self enumerateAttributesInRange:NSMakeRange(0, self.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
		[s addAttributes:attrs range:range];
	}];
	return s;
}

+ (instancetype) attributedStringWithSkillName:(NSString*) skillName level:(NSInteger) level {
	return [self attributedStringWithSkillName:skillName level:level rank:0];
}

+ (instancetype) attributedStringWithSkillName:(NSString*) skillName level:(NSInteger) level rank:(NSInteger) rank {
	NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:skillName attributes:nil];
	level = CLAMP(level, 0, 5);
	//[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %d", (int) level] attributes:@{NSForegroundColorAttributeName:[UIColor captionColor]}]];
	static const char* roman[]={"0","I","II","III","IV","V"};
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:@(roman[level])] attributes:@{NSForegroundColorAttributeName:[UIColor captionColor]}]];
	return s;
}

- (instancetype) attributedStringWithDefaultFont:(UIFont*) font textColor:(UIColor*) textColor {
	NSMutableAttributedString* s = [self mutableCopy];
	[self enumerateAttributesInRange:NSMakeRange(0, self.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		__block BOOL hasFont = NO;
		__block BOOL hasColor = NO;
		[attrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if ([key isEqualToString:@"UIFontDescriptorSymbolicTraits"]) {
				UIFontDescriptor* fontDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:[obj unsignedIntValue]];
				if (fontDescriptor) {
					UIFont* theFont = [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize];
					if (theFont) {
						[s addAttribute:NSFontAttributeName value:theFont range:range];
						hasFont = YES;
					}
				}
			}
			else if ([key isEqualToString:@"NSURL"]) {
				UIFontDescriptor* fontDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
				UIFont* theFont = fontDescriptor ? [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize] : font;
				[s addAttributes:@{NSForegroundColorAttributeName:[UIColor captionColor], NSFontAttributeName:theFont} range:range];
				hasFont = YES;
				hasColor = YES;
			}
			else if ([key isEqualToString:NSForegroundColorAttributeName])
				hasColor = YES;
		}];
		if (!hasFont) {
			UIFont* theFont = attrs[NSFontAttributeName];
			if (!theFont)
				[s addAttribute:NSFontAttributeName value:font range:range];
		}
		if (!hasColor)
			[s addAttribute:NSForegroundColorAttributeName value:textColor range:range];
	}];
	return s;
}

@end
