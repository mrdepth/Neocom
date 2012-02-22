//
//  RSSFeedCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RSSFeedCellView.h"


@implementation RSSFeedCellView
@synthesize titleLabel;
@synthesize dateLabel;
@synthesize descriptionLabel;

- (void) layoutSubviews {
	[super layoutSubviews];
	CGRect r = [descriptionLabel textRectForBounds:CGRectMake(0, 0, descriptionLabel.frame.size.width, 70) limitedToNumberOfLines:0];
	descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x,
										descriptionLabel.frame.origin.y,
										descriptionLabel.frame.size.width,
										r.size.height);
	self.contentView.frame = CGRectMake(self.contentView.frame.origin.x,
										self.contentView.frame.origin.y,
										self.contentView.frame.size.width,
										descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height + 2);
}

- (void) dealloc {
	[titleLabel release];
	[dateLabel release];
	[descriptionLabel release];
	[super dealloc];
}

@end
