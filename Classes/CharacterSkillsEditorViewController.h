//
//  CharacterSkillsEditorViewController.h
//  EVEUniverse
//
//  Created by mr_depth on 27.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillLevelsViewController.h"
#import "Character.h"

@interface CharacterSkillsEditorViewController : UITableViewController<UITextFieldDelegate>
@property (nonatomic, strong) IBOutlet UITextField *characterNameTextField;
@property (nonatomic, strong) id<Character> character;

- (IBAction) onOptions:(id) sender;
- (IBAction) onDone:(id)sender;

@end
