//
//  CharacterSkillsEditorViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillLevelsViewController.h"

@class Character;
@interface CharacterSkillsEditorViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, SkillLevelsViewControllerDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *skillsTableView;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, weak) IBOutlet UIView *shadowView;
@property (nonatomic, weak) IBOutlet UIToolbar *characterNameToolbar;
@property (nonatomic, weak) IBOutlet UITextField *characterNameTextField;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) Character *character;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onOptions:(id) sender;
- (IBAction) onDone:(id)sender;

@end
