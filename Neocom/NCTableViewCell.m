//
//  NCTableViewCell.m
//  Neocom
//
//  Created by Артем Шиманский on 11.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "NCLabel.h"

@interface NCTableViewCell()
@property (nonatomic, strong) NSLayoutConstraint* imageViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint* imageViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint* indentationConstraint;
@end

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

/*- (void) layoutSubviews {
	CGFloat indentation = self.indentationLevel * self.indentationWidth;
	if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
		if (self.imageView.image)
			self.separatorInset = UIEdgeInsetsMake(0, indentation + 15 + 32 + 8, 0, 0);
		else
			self.separatorInset = UIEdgeInsetsMake(-1, -1, -1, -1);
	}
	
	[super layoutSubviews];
	
	if (self.imageView.image) {
		self.imageView.frame = CGRectMake(indentation + 15, self.imageView.center.y - 16, 32, 32);
		CGRect frame = self.textLabel.frame;
		frame.origin.x = CGRectGetMaxX(self.imageView.frame) + 8;
		if (self.accessoryType != UITableViewCellAccessoryNone && self.accessoryView != nil)
			frame.size.width = self.contentView.frame.size.width - 2 - frame.origin.x;
		else
			frame.size.width = self.contentView.frame.size.width - 15 - frame.origin.x;
		
		self.textLabel.frame = frame;
		if (self.detailTextLabel.text) {
			frame = self.detailTextLabel.frame;
			frame.origin.x = self.textLabel.frame.origin.x;
			if (self.accessoryType != UITableViewCellAccessoryNone && self.accessoryView != nil)
				frame.size.width = self.contentView.frame.size.width - 2 - frame.origin.x;
			else
				frame.size.width = self.contentView.frame.size.width - 15 - frame.origin.x;
			self.detailTextLabel.frame = frame;
		}
	}
}

*/

- (void) prepareForReuse {
	[super prepareForReuse];
	[self setNeedsUpdateConstraints];
}

- (void) updateConstraints {
	if (self.iconView.image) {
		self.indentationConstraint.constant = 15 + self.indentationLevel * self.indentationWidth;
	}
	else {
		self.indentationConstraint.constant = 15 - 8 + self.indentationLevel * self.indentationWidth;
	}
	self.imageViewWidthConstraint.constant = self.iconView.image ? 32.0 : 0;
	[super updateConstraints];
}

- (void) layoutSubviews {
	//self.imageViewHeightConstraint.constant = self.iconView.image ? 32.0 : 0;
	[super layoutSubviews];
/*	//[self.contentView setNeedsLayout];
	[self.contentView layoutIfNeeded];
	self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.bounds.size.width;
	self.subtitleLabel.preferredMaxLayoutWidth = self.titleLabel.bounds.size.width;*/
	
	if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
		self.separatorInset = UIEdgeInsetsMake(0, self.titleLabel.frame.origin.x, 0, 0);
	}

}

- (void) awakeFromNib {
	self.titleLabel = [[NCLabel alloc] initWithFrame:CGRectZero];
	self.subtitleLabel = [[NCLabel alloc] initWithFrame:CGRectZero];
	self.iconView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.titleLabel.backgroundColor = [UIColor clearColor];
	self.subtitleLabel.backgroundColor = [UIColor clearColor];
	
	self.titleLabel.font = [UIFont systemFontOfSize:15];
	self.titleLabel.textColor = [UIColor whiteColor];
	self.subtitleLabel.font = [UIFont systemFontOfSize:12];
	self.subtitleLabel.textColor = [UIColor lightTextColor];
	
	self.titleLabel.numberOfLines = 0;
	self.subtitleLabel.numberOfLines = 0;
	
	[self.contentView addSubview:self.titleLabel];
	[self.contentView addSubview:self.subtitleLabel];
	[self.contentView addSubview:self.iconView];
	
	UIImageView* iconView = self.iconView;
	UILabel* titleLabel = self.titleLabel;
	UILabel* subtitleLabel = self.subtitleLabel;
	iconView.translatesAutoresizingMaskIntoConstraints = NO;
	titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
	NSDictionary* bindings = NSDictionaryOfVariableBindings(iconView, titleLabel, subtitleLabel);
	
	self.imageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:iconView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:nil
																 attribute:0
																multiplier:1
																  constant:32];
	self.imageViewHeightConstraint = [NSLayoutConstraint constraintWithItem:iconView
																 attribute:NSLayoutAttributeHeight
																 relatedBy:NSLayoutRelationEqual
																	toItem:nil
																 attribute:0
																multiplier:1
																  constant:32];
	self.imageViewHeightConstraint.priority = 999;
//	self.imageViewWidthConstraint.priority = UILayoutPriorityRequired;
//	self.imageViewHeightConstraint.priority = UILayoutPriorityRequired;
	
	[iconView addConstraint:self.imageViewWidthConstraint];
	[iconView addConstraint:self.imageViewHeightConstraint];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:iconView
															   attribute:NSLayoutAttributeCenterY
															   relatedBy:NSLayoutRelationEqual
																  toItem:self.contentView
															   attribute:NSLayoutAttributeCenterY
															  multiplier:1
																constant:0]];
	
	self.indentationConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"|-15-[iconView]"
																		 options:0
																		 metrics:nil
																		   views:bindings][0];
	[self.contentView addConstraint:self.indentationConstraint];
	
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[iconView]-8-[titleLabel]-8@900-|"
																options:0
																metrics:nil
																  views:bindings]];

	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=2)-[iconView]-(>=2)-|"
																			 options:0
																			 metrics:nil
																			   views:bindings]];

	[titleLabel setContentHuggingPriority:249 forAxis:UILayoutConstraintAxisVertical];
	[titleLabel setContentCompressionResistancePriority:800 forAxis:UILayoutConstraintAxisVertical];

	
	[titleLabel setContentHuggingPriority:750 forAxis:UILayoutConstraintAxisHorizontal];
	[subtitleLabel setContentHuggingPriority:750 forAxis:UILayoutConstraintAxisHorizontal];

	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-2-[titleLabel]-0-[subtitleLabel]-2-|"
																			 options:0
																			 metrics:nil
																			   views:bindings]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel
																 attribute:NSLayoutAttributeLeading
																 relatedBy:NSLayoutRelationEqual
																	toItem:titleLabel
																 attribute:NSLayoutAttributeLeading
																multiplier:1
																  constant:0]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel
																 attribute:NSLayoutAttributeTrailing
																 relatedBy:NSLayoutRelationEqual
																	toItem:titleLabel
																 attribute:NSLayoutAttributeTrailing
																multiplier:1
																  constant:0]];
}

@end
