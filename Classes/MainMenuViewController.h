//
//  MainMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterInfoViewController.h"

@class SBTableView;
@interface MainMenuViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CharacterInfoViewControllerDelegate> {
	SBTableView *menuTableView;
	NSArray *menuItems;
	CharacterInfoViewController *characterInfoViewController;
	UIView *characterInfoView;
@private
	NSInteger numberOfUnreadMessages;
}
@property (nonatomic, retain) IBOutlet SBTableView *menuTableView;
@property (nonatomic, retain) IBOutlet CharacterInfoViewController *characterInfoViewController;
@property (nonatomic, retain) IBOutlet UIView *characterInfoView;
@property (nonatomic, retain) NSArray *menuItems;
@end
