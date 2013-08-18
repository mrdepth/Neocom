//
//  POSFittingViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DamagePatternsViewController.h"
#import "EVECentralAPI.h"

#import "StructuresDataSource.h"
#import "AssemblyLinesDataSource.h"
#import "POSStatsDataSource.h"

#import "NCItemsViewController.h"

#import "eufe.h"

@class POSFit;
@class DamagePattern;
@class EVEDBInvControlTowerResource;
@class PriceManager;
@interface POSFittingViewController : UIViewController<UITextFieldDelegate, DamagePatternsViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UISegmentedControl *sectionSegmentControl;

@property (nonatomic, strong) IBOutlet UITextField *fitNameTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet StructuresDataSource *structuresDataSource;
@property (strong, nonatomic) IBOutlet AssemblyLinesDataSource *assemblyLinesDataSource;
@property (strong, nonatomic) IBOutlet POSStatsDataSource *statsDataSource;

@property (nonatomic, strong, readonly) NCItemsViewController* itemsViewController;

@property (nonatomic, strong) POSFit* fit;

@property (nonatomic, readonly) eufe::Engine* fittingEngine;
@property (nonatomic, strong) DamagePattern* damagePattern;

@property (nonatomic, strong) EVEDBInvControlTowerResource* posFuelRequirements;
@property (nonatomic, strong) PriceManager* priceManager;

- (IBAction) didChangeSection:(id) sender;
- (IBAction) onMenu:(id) sender;
- (IBAction) onBack:(id) sender;
- (void) update;

@end
