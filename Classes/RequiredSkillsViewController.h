//
//  RequiredSkillsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ShipFit;
@class SkillPlan;
@interface RequiredSkillsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView* skillsTableView;
@property (weak, nonatomic) IBOutlet UILabel *trainingTimeLabel;
@property (nonatomic, strong) ShipFit* fit;

- (IBAction)onClose:(id)sender;
- (IBAction)onAddToSkillPlan:(id)sender;

@end
