//
//  SkillPlanViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillPlannerImportViewControllerDelegate.h"

@class SkillPlan;
@class SkillPlannerImportViewController;
@interface SkillPlanViewController : UITableViewController<UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView* skillsTableView;
@property (nonatomic, weak) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, strong) NSString* skillPlanPath;
@property (nonatomic, weak) SkillPlannerImportViewController* skillPlannerImportViewController;
@property (nonatomic, strong) SkillPlan* skillPlan;


- (IBAction)onImport:(id)sender;

@end
