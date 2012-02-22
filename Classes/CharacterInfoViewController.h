//
//  CharacterInfoViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 1/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "URLImageView.h"

@class CharacterInfoViewController;
@protocol CharacterInfoViewControllerDelegate

- (void) characterInfoViewController:(CharacterInfoViewController*) controller willChangeContentSize:(CGSize) size animated:(BOOL) animated;

@end

@class EVECharacterSheet;
@interface CharacterInfoViewController : UIViewController {
	URLImageView *portraitImageView;
	URLImageView *corpImageView;
	URLImageView *allianceImageView;
	UILabel *corpLabel;
	UILabel *allianceLabel;
	UILabel *skillsLabel;
	UILabel *wealthLabel;
	UILabel *serverStatusLabel;
	UILabel *onlineLabel;
	id<CharacterInfoViewControllerDelegate> delegate;
}
@property (nonatomic, retain) IBOutlet URLImageView *portraitImageView;
@property (nonatomic, retain) IBOutlet URLImageView *corpImageView;
@property (nonatomic, retain) IBOutlet URLImageView *allianceImageView;
@property (nonatomic, retain) IBOutlet UILabel *corpLabel;
@property (nonatomic, retain) IBOutlet UILabel *allianceLabel;
@property (nonatomic, retain) IBOutlet UILabel *skillsLabel;
@property (nonatomic, retain) IBOutlet UILabel *wealthLabel;
@property (nonatomic, retain) IBOutlet UILabel *serverStatusLabel;
@property (nonatomic, retain) IBOutlet UILabel *onlineLabel;
@property (nonatomic, assign) id<CharacterInfoViewControllerDelegate> delegate;
@end
