//
//  EVEAccountsCharacterCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountsCharacterCellView.h"

@interface EVEAccountsCharacterCellView(Private)
- (void) update;
@end


@implementation EVEAccountsCharacterCellView
@synthesize portraitImageView;
@synthesize corpImageView;
@synthesize userNameLabel;
@synthesize corpLabel;
@synthesize trainingTimeLabel;
@synthesize paidUntilLabel;
@synthesize enableSwitch;
@synthesize character;

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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:YES];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.3];
	enableSwitch.alpha = editing ? 1.0 : 0;
	[UIView commitAnimations];
}

- (void)dealloc {
	[portraitImageView release];
	[corpImageView release];
	[userNameLabel release];
	[corpLabel release];
	[trainingTimeLabel release];
	[paidUntilLabel release];
	[enableSwitch release];
	[character release];
    [super dealloc];
}

- (IBAction) onChangeEnableValue:(id) sender {
	character.enabled = enableSwitch.on;
}

- (void) setCharacter:(EVEAccountStorageCharacter *)value {
	[value retain];
	[character release];
	character = value;
	enableSwitch.on = character.enabled;
}

@end

@implementation EVEAccountsCharacterCellView(Private)

- (void) update {
}

@end
