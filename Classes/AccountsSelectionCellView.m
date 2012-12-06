//
//  AccountsSelectionCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 20.11.12.
//
//

#import "AccountsSelectionCellView.h"

@implementation AccountsSelectionCellView

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
    [_corpImageView release];
    [_characterNameLabel release];
    [_corpNameLabel release];
    [super dealloc];
}
@end
