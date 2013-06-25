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
@interface SkillPlanViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) IBOutlet UITableView* skillsTableView;
@property (nonatomic, retain) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, retain) NSString* skillPlanPath;
@property (nonatomic, assign) SkillPlannerImportViewController* skillPlannerImportViewController;
@property (nonatomic, retain) SkillPlan* skillPlan;


- (IBAction)onImport:(id)sender;

@end
