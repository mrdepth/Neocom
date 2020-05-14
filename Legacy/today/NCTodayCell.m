//
//  NCTodayCell.m
//  Neocom
//
//  Created by Артем Шиманский on 28.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTodayCell.h"
#import <NotificationCenter/NotificationCenter.h>

@implementation NCTodayCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	UIView* view = [[UIView alloc] initWithFrame:self.bounds];
	view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
	self.selectedBackgroundView = view;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
