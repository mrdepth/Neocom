//
//  KillMailAttackerCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 12.11.12.
//
//

#import "KillMailAttackerCellView.h"

@implementation KillMailAttackerCellView

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

- (void)dealloc {
	[_portraitImageView release];
	[_shipImageView release];
	[_weaponImageView release];
	[_characterNameLabel release];
	[_corporationNameLabel release];
	[_damageDoneLabel release];
	[super dealloc];
}
@end
