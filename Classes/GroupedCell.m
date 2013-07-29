//
//  GroupedCell.m
//  EVEUniverse
//
//  Created by mr_depth on 20.07.13.
//
//

#import "GroupedCell.h"

@implementation GroupedCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.textLabel.textColor = [UIColor whiteColor];
		self.textLabel.shadowColor = [UIColor blackColor];
		self.textLabel.font = [UIFont systemFontOfSize:12];
		self.textLabel.backgroundColor = [UIColor clearColor];
		
		self.detailTextLabel.textColor = [UIColor lightTextColor];
		self.detailTextLabel.shadowColor = [UIColor blackColor];
		self.detailTextLabel.font = [UIFont systemFontOfSize:12];
		self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setGroupStyle:(GroupedCellGroupStyle)groupStyle {
	_groupStyle = groupStyle;
	UIImage* backgroundImage = nil;
	UIImage* selectedBackgroundImage = nil;
	UIEdgeInsets edgeInsets;
	
	if (groupStyle == GroupedCellGroupStyleTop) {
		backgroundImage = [UIImage imageNamed:@"cellGroupedTop.png"];
		selectedBackgroundImage = [UIImage imageNamed:@"cellGroupedTopSelected.png"];
		edgeInsets = UIEdgeInsetsMake(backgroundImage.size.height * 2.0 / 3.0 - 1, backgroundImage.size.width / 2.0 - 1, backgroundImage.size.height / 3.0, backgroundImage.size.width / 2.0);
	}
	else if (groupStyle == GroupedCellGroupStyleBottom) {
		backgroundImage = [UIImage imageNamed:@"cellGroupedBottom.png"];
		selectedBackgroundImage = [UIImage imageNamed:@"cellGroupedBottomSelected.png"];
		edgeInsets = UIEdgeInsetsMake(backgroundImage.size.height / 3.0 - 1, backgroundImage.size.width / 2.0 - 1, backgroundImage.size.height * 2.0 / 3.0, backgroundImage.size.width / 2.0);
	}
	else if (groupStyle == GroupedCellGroupStyleMiddle) {
		backgroundImage = [UIImage imageNamed:@"cellGroupedMiddle.png"];
		selectedBackgroundImage = [UIImage imageNamed:@"cellGroupedMiddleSelected.png"];
		edgeInsets = UIEdgeInsetsMake(backgroundImage.size.height / 2.0 - 1, backgroundImage.size.width / 2.0 - 1, backgroundImage.size.height / 2.0, backgroundImage.size.width / 2.0);
	}
	else {
		backgroundImage = [UIImage imageNamed:@"cellGrouped.png"];
		selectedBackgroundImage = [UIImage imageNamed:@"cellGroupedSelected.png"];
		edgeInsets = UIEdgeInsetsMake(backgroundImage.size.height / 2.0 - 1, backgroundImage.size.width / 2.0 - 1, backgroundImage.size.height / 2.0, backgroundImage.size.width / 2.0);
	}

	backgroundImage = [backgroundImage resizableImageWithCapInsets:edgeInsets];
	selectedBackgroundImage = [selectedBackgroundImage resizableImageWithCapInsets:edgeInsets];

	self.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
	self.selectedBackgroundView = [[UIImageView alloc] initWithImage:selectedBackgroundImage];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	if (self.imageView.image) {
		CGFloat indentationOffset = self.indentationLevel * 10;
		self.imageView.frame = CGRectMake(4 + indentationOffset, 4, 32, 32);
		self.imageView.contentMode = self.imageView.image.size.width < 32 && self.imageView.image.size.height < 32 ? UIViewContentModeCenter : UIViewContentModeScaleAspectFit;
		
		if (self.textLabel.text.length > 0) {
			CGRect frame = self.textLabel.frame;
			CGFloat maxX = CGRectGetMaxX(frame);
			frame.origin.x = 40 + indentationOffset;
			frame.size.width = maxX - frame.origin.x;
			self.textLabel.frame = frame;
		}
		if (self.detailTextLabel.text.length > 0) {
			CGRect frame = self.detailTextLabel.frame;
			CGFloat maxX = CGRectGetMaxX(frame);
			frame.origin.x = 40 + indentationOffset;
			frame.size.width = maxX - frame.origin.x;
			self.detailTextLabel.frame = frame;
		}
		
	}
}

@end
