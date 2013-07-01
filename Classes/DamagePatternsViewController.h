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

@interface DamagePatternsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet id<DamagePatternsViewControllerDelegate> delegate;
@property (nonatomic, strong) DamagePattern* currentDamagePattern;

- (IBAction)onClose:(id)sender;

@end
