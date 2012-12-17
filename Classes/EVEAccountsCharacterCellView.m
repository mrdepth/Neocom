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
	self.enableSwitch.alpha = editing ? 1.0 : 0;
	[UIView commitAnimations];
}

- (void)dealloc {
	[_portraitImageView release];
	[_corpImageView release];
	[_userNameLabel release];
	[_corpLabel release];
	[_trainingTimeLabel release];
	[_paidUntilLabel release];
	[_enableSwitch release];
	[_character release];
	[_wealthLabel release];
	[_locationLabel release];
    [super dealloc];
}

- (IBAction) onChangeEnableValue:(id) sender {
	self.character.enabled = self.enableSwitch.on;
}

- (void) setCharacter:(EVEAccountStorageCharacter *)value {
	[value retain];
	[_character release];
	_character = value;
	self.enableSwitch.on = self.character.enabled;
}

@end

@implementation EVEAccountsCharacterCellView(Private)

- (void) update {
}

@end
