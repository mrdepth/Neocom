//
//  MainMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterInfoViewController.h"

@interface MainMenuViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, CharacterInfoViewControllerDelegate, UISplitViewControllerDelegate>
@property (nonatomic, weak) IBOutlet CharacterInfoViewController *characterInfoViewController;
@property (nonatomic, weak) IBOutlet UIView *characterInfoView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *onlineModeSegmentedControl;
@property (nonatomic, strong) NSArray *menuItems;

- (IBAction)onFacebook:(id)sender;
- (IBAction)onChangeOnlineMode:(id)sender;
@end
