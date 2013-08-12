//
//  FittingViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModulesViewController.h"
#import "DronesViewController.h"
#import "ImplantsViewController.h"
#import "StatsViewController.h"
#import "FleetViewController.h"
#import "BrowserViewController.h"
#import "FittingSection.h"
#import "AreaEffectsViewController.h"
#import "CharactersViewController.h"
#import "DamagePatternsViewController.h"
#import "FitsViewController.h"
#import "TargetsViewController.h"
#import "FittingVariationsViewController.h"
#import "ModulesDataSource.h"
#import "DronesDataSource.h"
#import "ImplantsDataSource.h"
#import "FleetDataSource.h"
#import "ShipStatsDataSource.h"
#import "NCItemsViewController.h"

#import "eufe.h"
#import "ShipFit.h"
#import "ItemInfo.h"

@class EVEFittingFit;
@class ShipFit;
@class DamagePattern;
@class PriceManager;
@interface FittingViewController : UIViewController<UIActionSheetDelegate,
													UITextFieldDelegate,
													BrowserViewControllerDelegate,
													AreaEffectsViewControllerDelegate,
													DamagePatternsViewControllerDelegate,
													FitsViewControllerDelegate,
													MFMailComposeViewControllerDelegate,
													FittingVariationsViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIView *sectionsView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *sectionSegmentControl;
@property (nonatomic, strong) IBOutlet UINavigationController *modalController;
@property (nonatomic, strong) IBOutlet UINavigationController *targetsModalController;
@property (nonatomic, strong) IBOutlet UINavigationController *areaEffectsModalController;
@property (nonatomic, strong) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, strong) IBOutlet AreaEffectsViewController* areaEffectsViewController;
@property (nonatomic, strong) IBOutlet ModulesViewController *modulesViewController;
@property (nonatomic, strong) IBOutlet DronesViewController *dronesViewController;
@property (nonatomic, strong) IBOutlet ImplantsViewController *implantsViewController;
@property (nonatomic, strong) IBOutlet StatsViewController *statsViewController;
@property (nonatomic, strong) IBOutlet FleetViewController *fleetViewController;
@property (nonatomic, strong) IBOutlet FittingItemsViewController *fittingItemsViewController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet ModulesDataSource *modulesDataSource;
@property (strong, nonatomic) IBOutlet DronesDataSource *dronesDataSource;
@property (strong, nonatomic) IBOutlet ImplantsDataSource *implantsDataSource;
@property (strong, nonatomic) IBOutlet FleetDataSource *fleetDataSource;
@property (strong, nonatomic) IBOutlet ShipStatsDataSource *shipStatsDataSource;

@property (nonatomic, weak) IBOutlet UIView *shadeView;
@property (nonatomic, weak) IBOutlet UIToolbar *fitNameView;
@property (nonatomic, strong) IBOutlet UITextField *fitNameTextField;
@property (nonatomic, weak) IBOutlet UIView *statsSectionView;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIPopoverController *targetsPopoverController;
@property (nonatomic, strong) UIPopoverController *areaEffectsPopoverController;
@property (nonatomic, strong) UIPopoverController *variationsPopoverController;

@property (nonatomic, strong) ShipFit* fit;

@property (nonatomic, readonly) eufe::Engine* fittingEngine;
@property (nonatomic, strong, readonly) NSMutableArray* fits;
@property (nonatomic, strong) DamagePattern* damagePattern;
@property (nonatomic, strong) PriceManager* priceManager;

@property (nonatomic, strong, readonly) NCItemsViewController* itemsViewController;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) didChangeSection:(id) sender;
- (IBAction) onMenu:(id) sender;
- (IBAction) onDone:(id) sender;
- (IBAction) onBack:(id) sender;
- (void) update;
- (void) addFleetMember;
- (void) selectCharacterForFit:(ShipFit*) fit;

@end
