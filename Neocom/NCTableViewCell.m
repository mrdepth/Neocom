//
//  NCTableViewCell.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@implementation NCTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews {
	if (self.imageView.image)
		self.separatorInset = UIEdgeInsetsMake(0, 15 + 32 + 8, 0, 0);
	else
		self.separatorInset = UIEdgeInsetsMake(-1, -1, -1, -1);
	
	[super layoutSubviews];
	
	if (self.imageView.image) {
		self.imageView.frame = CGRectMake(15, self.imageView.center.y - 16, 32, 32);
		CGRect frame = self.textLabel.frame;
		CGFloat right = CGRectGetMaxX(frame);
		frame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8;
		frame.size.width = right - frame.origin.x;
		self.textLabel.frame = frame;
		if (self.detailTextLabel.text) {
			frame = self.detailTextLabel.frame;
			frame.origin.x = self.textLabel.frame.origin.x;
			frame.size.width = self.textLabel.frame.size.width;
			self.detailTextLabel.frame = frame;
		}
	}
}

@end
