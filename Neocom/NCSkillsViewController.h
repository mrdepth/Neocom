//
//  NCSkillsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_ENUM(NSInteger, NCSkillsViewControllerMode) {
	NCSkillsViewControllerModeKnownSkills,
	NCSkillsViewControllerModeAllSkills,
	NCSkillsViewControllerModeNotKnownSkills,
	NCSkillsViewControllerModeCanTrainSkills
};

@interface NCSkillsViewController : NCTableViewController
@property (nonatomic, assign) NCSkillsViewControllerMode mode;
@property (nonatomic, weak) IBOutlet UISegmentedControl* modeSegmentedControl;

- (IBAction)onChangeMode:(id)sender;

@end
