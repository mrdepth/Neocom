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
@interface SkillPlanViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
	UITableView* skillsTableView;
	UILabel *trainingTimeLabel;
	NSString* skillPlanPath;
	SkillPlannerImportViewController* skillPlannerImportViewController;
@private
	SkillPlan* skillPlan;
}
@property (nonatomic, retain) IBOutlet UITableView* skillsTableView;
@property (nonatomic, retain) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, retain) NSString* skillPlanPath;
@property (nonatomic, assign) SkillPlannerImportViewController* skillPlannerImportViewController;

- (IBAction)onImport:(id)sender;

@end
