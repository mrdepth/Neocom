//
//  NCTableViewBackgroundLabel.m
//  Neocom
//
//  Created by Artem Shimanski on 18.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewBackgroundLabel.h"

@interface NCLabel()
@property (nonatomic, assign) CGFloat pointSize;
- (CGFloat) fontSizeWithContentSizeCategory:(UIContentSizeCategory) contentSizeCategory;
@end

@implementation NCTableViewBackgroundLabel

+ (instancetype) labelWithText:(NSString*) text {
	return [[self alloc] initWithText:text];
}

- (id) initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.pointSize = 15;
		self.numberOfLines = 0;
		self.font = [UIFont systemFontOfSize:[self fontSizeWithContentSizeCategory:[[UIApplication sharedApplication] preferredContentSizeCategory]]];
		self.textColor = [UIColor lightTextColor];
	}
	return self;
}


- (instancetype) initWithText:(NSString*) text {
	if (self = [self initWithFrame:CGRectZero]) {
		NSMutableParagraphStyle* paragraph = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		paragraph.firstLineHeadIndent = 20;
		paragraph.headIndent = 20;
		paragraph.tailIndent = -20;
		paragraph.alignment = NSTextAlignmentCenter;
		self.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName:paragraph}];
	}
	return self;
}

@end
