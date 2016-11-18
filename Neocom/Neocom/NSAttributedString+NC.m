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


@end
