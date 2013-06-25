//
//  NAPISearchSwitchCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 18.06.13.
//
//

#import "NAPISearchSwitchCellView.h"

@implementation NAPISearchSwitchCellView

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

- (IBAction)onSwitch:(id)sender {
	[self.delegate switchCellViewDidSwitch:self];
}

@end
