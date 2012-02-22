//
//  DamagePatternsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DamagePatternsViewControllerDelegate.h"
#import "DamagePattern.h"

@interface DamagePatternsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate> {
	UITableView *tableView;
	id<DamagePatternsViewControllerDelegate> delegate;
	DamagePattern* currentDamagePattern;
@protected
	NSMutableArray *sections;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) IBOutlet id<DamagePatternsViewControllerDelegate> delegate;
@property (nonatomic, retain) DamagePattern* currentDamagePattern;

- (IBAction)onClose:(id)sender;

@end
