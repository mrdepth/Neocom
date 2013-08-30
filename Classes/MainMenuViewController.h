//
//  MainMenuViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 9/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CharacterInfoViewController.h"

@interface MainMenuViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate>
@property (nonatomic, strong) IBOutlet CharacterInfoViewController *characterInfoViewController;
@property (nonatomic, weak) IBOutlet UIView *characterInfoView;
@property (nonatomic, strong) NSArray *menuItems;
@property (weak, nonatomic) IBOutlet UIView *tableHeaderContentView;
@property (weak, nonatomic) IBOutlet UILabel *onlineLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverTimeLabel;

- (IBAction)onFacebook:(id)sender;
- (IBAction)onChangeOnlineMode:(id)sender;
@end
