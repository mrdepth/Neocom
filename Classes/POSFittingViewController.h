//
//  POSFittingViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StructuresViewController.h"
#import "AssemblyLinesViewController.h"
#import "POSStatsViewController.h"
#import "FittingSection.h"
#import "AreaEffectsViewController.h"
#import "DamagePatternsViewController.h"
#import "EVECentralAPI.h"

#import "StructuresDataSource.h"

#import "NCItemsViewController.h"

#import "eufe.h"

@class POSFit;
@class DamagePattern;
@class EVEDBInvControlTowerResource;
@class PriceManager;
@interface POSFittingViewController : UIViewController<UIActionSheetDelegate,UITextFieldDelegate, AreaEffectsViewControllerDelegate, DamagePatternsViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UIView *sectionsView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *sectionSegmentControl;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, strong) IBOutlet UINavigationController *areaEffectsModalController;
@property (nonatomic, strong) IBOutlet AreaEffectsViewController* areaEffectsViewController;
@property (nonatomic, strong) IBOutlet StructuresViewController *structuresViewController;
@property (nonatomic, strong) IBOutlet AssemblyLinesViewController* assemblyLinesViewController;
@property (nonatomic, strong) IBOutlet POSStatsViewController *posStatsViewController;

@property (nonatomic, weak) IBOutlet UIView *shadeView;
@property (nonatomic, weak) IBOutlet UIToolbar *fitNameView;
@property (nonatomic, weak) IBOutlet UITextField *fitNameTextField;
@property (nonatomic, weak) IBOutlet UIView *statsSectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet StructuresDataSource *structuresDataSource;

@property (nonatomic, strong, readonly) NCItemsViewController* itemsViewController;

@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIPopoverController *areaEffectsPopoverController;

@property (nonatomic, strong) POSFit* fit;

@property (nonatomic, readonly) eufe::Engine* fittingEngine;
@property (nonatomic, strong) DamagePattern* damagePattern;

@property (nonatomic, strong) EVEDBInvControlTowerResource* posFuelRequirements;
@property (nonatomic, strong) PriceManager* priceManager;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) didChangeSection:(id) sender;
- (IBAction) onMenu:(id) sender;
- (IBAction) onDone:(id) sender;
- (IBAction) onBack:(id) sender;
- (void) update;

@end
