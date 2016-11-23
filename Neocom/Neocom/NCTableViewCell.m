//
//  NCTableViewCell.m
//  Neocom
//
//  Created by Artem Shimanski on 16.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"
#import "UIColor+CS.h"

@implementation NCTableViewCell
@synthesize binder = _binder;

- (void)awakeFromNib {
    [super awakeFromNib];
	self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.backgroundColor = [UIColor separatorColor];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	if (selected && !self.selectedBackgroundView) {
	}
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (ASBinder*) binder {
	if (!_binder) {
		_binder = [[ASBinder alloc] initWithTarget:self];
	}
	return _binder;
}

@end
