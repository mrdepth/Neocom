//
//  KillMailItemCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import "KillMailItemCellView.h"

@implementation KillMailItemCellView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) dealloc {
	[_iconImageView release];
	[_titleLabel release];
	[_qualityLabel release];
	[super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDestroyed:(BOOL)destroyed {
	_destroyed = destroyed;
	[(UIImageView*) self.backgroundView setImage:[UIImage imageNamed:destroyed ? @"cellBackground.png" : @"cellBackgroundDropped.png"]];
}

@end
