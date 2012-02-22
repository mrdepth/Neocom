//
//  APIKeysKeyCellView.m
//  EVEUniverse
//
//  Created by Shimanski on 9/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "APIKeysKeyCellView.h"


@implementation APIKeysKeyCellView
@synthesize nameLabel;
@synthesize keyIDLabel;
@synthesize vCodeLabel;
@synthesize checkmarkImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}


- (void)dealloc {
    [super dealloc];
}


@end
