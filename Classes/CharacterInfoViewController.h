//
//  CharacterInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EVEAccount;
@interface CharacterInfoViewController : UIViewController
@property (nonatomic, weak) IBOutlet UIImageView *portraitImageView;
@property (nonatomic, weak) IBOutlet UIImageView *corpImageView;
@property (nonatomic, weak) IBOutlet UIImageView *allianceImageView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *characterNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *corpLabel;
@property (weak, nonatomic) IBOutlet UILabel *allianceLabel;
@property (weak, nonatomic) IBOutlet UILabel *wealthLabel;
@property (weak, nonatomic) IBOutlet UILabel *skillsLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectCharacterLabel;
@property (nonatomic, strong) EVEAccount* account;
- (IBAction)onReloadPortrait:(id)sender;
@end
