//
//  RSSFeedCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSFeedCellView.h"


@implementation RSSFeedCellView
- (void) layoutSubviews {
	[super layoutSubviews];
	CGRect r = [self.descriptionLabel textRectForBounds:CGRectMake(0, 0, self.descriptionLabel.frame.size.width, 70) limitedToNumberOfLines:0];
	self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x,
										self.descriptionLabel.frame.origin.y,
										self.descriptionLabel.frame.size.width,
										r.size.height);
	self.contentView.frame = CGRectMake(self.contentView.frame.origin.x,
										self.contentView.frame.origin.y,
										self.contentView.frame.size.width,
										self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 3);
}

@end
