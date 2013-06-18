//
//  EVEAccountsCharacterCellView.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EVEAccountsCharacterCellView.h"

@interface EVEAccountsCharacterCellView()
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

- (IBAction) onChangeEnableValue:(id) sender {
	self.character.enabled = self.enableSwitch.on;
}

- (void) setCharacter:(EVEAccountStorageCharacter *)value {
	_character = value;
	self.enableSwitch.on = self.character.enabled;
}

#pragma mark - Private

- (void) update {
}

@end
