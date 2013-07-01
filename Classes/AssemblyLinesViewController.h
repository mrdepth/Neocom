//
//  AssemblyLinesViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FittingSection.h"

@class POSFittingViewController;
@interface AssemblyLinesViewController : UIViewController<FittingSection, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
