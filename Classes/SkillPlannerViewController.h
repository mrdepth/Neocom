//
//  SkillPlannerViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 1/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillPlannerImportViewController.h"

@class SkillPlan;
@interface SkillPlannerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, SkillPlannerImportViewControllerDelegate> {
	UITableView* skillsTableView;
	UILabel *trainingTimeLabel;
@private
	SkillPlan* skillPlan;
	NSIndexPath* modifiedIndexPath;
}
@property (nonatomic, retain) IBOutlet UITableView* skillsTableView;
@property (retain, nonatomic) IBOutlet UILabel *trainingTimeLabel;

@end
