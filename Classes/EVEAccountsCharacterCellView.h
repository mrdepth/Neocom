//
//  EVEAccountsCharacterCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEAccountStorage.h"

@interface EVEAccountsCharacterCellView : UITableViewCell {
	UIImageView *portraitImageView;
	UIImageView *corpImageView;
	UILabel *userNameLabel;
	UILabel *corpLabel;
	UILabel *trainingTimeLabel;
	UILabel *paidUntilLabel;
	UISwitch *enableSwitch;
	EVEAccountStorageCharacter *character;
}
@property (nonatomic, retain) IBOutlet UIImageView *portraitImageView;
@property (nonatomic, retain) IBOutlet UIImageView *corpImageView;
@property (nonatomic, retain) IBOutlet UILabel *userNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *corpLabel;
@property (nonatomic, retain) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *paidUntilLabel;
@property (nonatomic, retain) IBOutlet UISwitch *enableSwitch;
@property (nonatomic, retain) EVEAccountStorageCharacter *character;

- (IBAction) onChangeEnableValue:(id) sender;

@end
