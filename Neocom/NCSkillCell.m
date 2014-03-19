//
//  NCSkillCell.m
//  Neocom
//
//  Created by Shimanski Artem on 19.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCSkillCell.h"

@interface NCImageView : UIImageView

@end

@implementation NCImageView

- (CGSize) intrinsicContentSize {
	if (!self.image)
		return CGSizeZero;
	else
		return self.image.size;
}

@end

@interface NCLabel : UILabel
@end

@implementation NCLabel

- (void) layoutSubviews {
	[super layoutSubviews];
	if (self.preferredMaxLayoutWidth != self.frame.size.width) {
		[self invalidateIntrinsicContentSize];
		self.preferredMaxLayoutWidth = self.frame.size.width;
		[self.superview setNeedsLayout];
		[self.superview layoutIfNeeded];
	}
}

@end

@implementation NCSkillCell

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

@end
