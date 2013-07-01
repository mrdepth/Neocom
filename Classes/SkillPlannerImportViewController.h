//
//  SkillPlannerImportViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SkillPlannerImportViewControllerDelegate.h"
#import "EUHTTPServer.h"

@interface SkillPlannerImportViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, EUHTTPServerDelegate>
@property (nonatomic, weak) IBOutlet UITableView* plansTableView;
@property (nonatomic, weak) id<SkillPlannerImportViewControllerDelegate> delegate;

- (IBAction)onClose:(id)sender;

@end
