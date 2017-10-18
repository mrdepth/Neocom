//
//  NCLabel.m
//  Neocom
//
//  Created by Artem Shimanski on 14.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCLabel.h"

@interface NCLabel()
@property (nonatomic, assign) CGFloat pointSize;
- (CGFloat) fontSizeWithContentSizeCategory:(UIContentSizeCategory) contentSizeCategory;
@end

@implementation NCLabel

- (void) awakeFromNib {
	[super awakeFromNib];
	self.pointSize = self.font.pointSize;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeContentSizeCategory:) name:UIContentSizeCategoryDidChangeNotification object:nil];
	self.font = [self.font fontWithSize:[self fontSizeWithContentSizeCategory:[[UIApplication sharedApplication] preferredContentSizeCategory]]];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - Private

- (void) didChangeContentSizeCategory:(NSNotification*) not {
	self.font = [self.font fontWithSize:[self fontSizeWithContentSizeCategory:[[UIApplication sharedApplication] preferredContentSizeCategory]]];
	[self invalidateIntrinsicContentSize];
}

- (CGFloat) fontSizeWithContentSizeCategory:(UIContentSizeCategory) contentSizeCategory {
	CGFloat p = self.pointSize;
	if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraSmall])
		p -= 2;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategorySmall])
		p -= 1;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryLarge])
		p += 1;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraLarge])
		p += 3;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraLarge])
		p += 5;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge])
		p += 5;
	else if ([contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityMedium] ||
			 [contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityLarge] ||
			 [contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityMedium] ||
			 [contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge] ||
			 [contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge] ||
			 [contentSizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge])
		p += 5;
	return MAX(p, 11);
}

@end
