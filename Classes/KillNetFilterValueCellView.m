//
//  KillNetFilterValueCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 13.11.12.
//
//

#import "KillNetFilterValueCellView.h"

@implementation KillNetFilterValueCellView

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
	[_titleLabel release];
	[_valueLabel release];
	[super dealloc];
}
@end
