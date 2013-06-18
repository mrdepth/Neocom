//
//  EVEAccountsCharacterCellView.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EVEAccountStorage.h"

@interface EVEAccountsCharacterCellView : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *portraitImageView;
@property (nonatomic, weak) IBOutlet UIImageView *corpImageView;
@property (nonatomic, weak) IBOutlet UILabel *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *corpLabel;
@property (nonatomic, weak) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *paidUntilLabel;
@property (nonatomic, weak) IBOutlet UISwitch *enableSwitch;
@property (nonatomic, retain) EVEAccountStorageCharacter *character;
@property (weak, nonatomic) IBOutlet UILabel *wealthLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

- (IBAction) onChangeEnableValue:(id) sender;

@end
