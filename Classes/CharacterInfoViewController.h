//
//  CharacterInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CharacterInfoViewController;
@protocol CharacterInfoViewControllerDelegate

- (void) characterInfoViewController:(CharacterInfoViewController*) controller willChangeContentSize:(CGSize) size animated:(BOOL) animated;

@end

@class EVECharacterSheet;
@interface CharacterInfoViewController : UIViewController
@property (nonatomic, weak) IBOutlet UIImageView *portraitImageView;
@property (nonatomic, weak) IBOutlet UIImageView *corpImageView;
@property (nonatomic, weak) IBOutlet UIImageView *allianceImageView;
@property (nonatomic, weak) IBOutlet UILabel *corpLabel;
@property (nonatomic, weak) IBOutlet UILabel *allianceLabel;
@property (nonatomic, weak) IBOutlet UILabel *skillsLabel;
@property (nonatomic, weak) IBOutlet UILabel *wealthLabel;
@property (nonatomic, weak) IBOutlet UILabel *serverStatusLabel;
@property (nonatomic, weak) IBOutlet UILabel *onlineLabel;
@property (nonatomic, weak) id<CharacterInfoViewControllerDelegate> delegate;
- (IBAction)onReloadPortrait:(id)sender;
@end
