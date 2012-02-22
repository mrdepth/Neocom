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
@interface CharacterSkillsEditorViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, SkillLevelsViewControllerDelegate, UITextFieldDelegate> {
	UITableView *skillsTableView;
	UINavigationController *modalController;
	UIView *shadowView;
	UIToolbar *characterNameToolbar;
	UITextField *characterNameTextField;
	UIPopoverController *popoverController;
	Character *character;
@private
	NSArray *sections;
	NSMutableDictionary* groups;
	NSIndexPath *modifiedIndexPath;
}
@property (nonatomic, retain) IBOutlet UITableView *skillsTableView;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) IBOutlet UIView *shadowView;
@property (nonatomic, retain) IBOutlet UIToolbar *characterNameToolbar;
@property (nonatomic, retain) IBOutlet UITextField *characterNameTextField;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) Character *character;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) onOptions:(id) sender;
- (IBAction) onDone:(id)sender;

@end
