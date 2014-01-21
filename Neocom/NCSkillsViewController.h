//
//  NCSkillsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

typedef NS_ENUM(NSInteger, NCSkillsViewControllerMode) {
	NCSkillsViewControllerModeTrainingQueue,
	NCSkillsViewControllerModeKnownSkills,
	NCSkillsViewControllerModeAllSkills,
	NCSkillsViewControllerModeNotKnownSkills,
	NCSkillsViewControllerModeCanTrainSkills
};

@interface NCSkillsViewController : NCTableViewController
@property (nonatomic, assign) NCSkillsViewControllerMode mode;

- (IBAction)onChangeMode:(id)sender;
- (IBAction)onAction:(id)sender;

@end
