//
//  KillboardCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 06.11.12.
//
//

#import "KillboardCellView.h"

@implementation KillboardCellView

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
	[_shipImageView release];
	[_shipLabel release];
	[_systemNameLabel release];
	[_piratesLabel release];
	[_characterNameLabel release];
	[_allianceNameLabel release];
	[_corporationNameLabel release];
	[super dealloc];
}

@end
