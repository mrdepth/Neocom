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
@interface MainMenuViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CharacterInfoViewControllerDelegate, UISplitViewControllerDelegate>
@property (nonatomic, weak) IBOutlet SBTableView *menuTableView;
@property (nonatomic, weak) IBOutlet CharacterInfoViewController *characterInfoViewController;
@property (nonatomic, weak) IBOutlet UIView *characterInfoView;
@property (nonatomic, strong) NSArray *menuItems;

- (IBAction)onFacebook:(id)sender;
@end
