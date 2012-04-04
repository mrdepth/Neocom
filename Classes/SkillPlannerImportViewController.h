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

@interface SkillPlannerImportViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, EUHTTPServerDelegate> {
	UITableView* plansTableView;
	id<SkillPlannerImportViewControllerDelegate> delegate;
@private
	NSMutableArray* rows;
	NSArray* addresses;
	EUHTTPServer* server;
}
@property (nonatomic, retain) IBOutlet UITableView* plansTableView;
@property (nonatomic, assign) id<SkillPlannerImportViewControllerDelegate> delegate;

- (IBAction)onClose:(id)sender;

@end
