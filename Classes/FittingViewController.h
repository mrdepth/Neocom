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

#import "eufe.h"

@class EVEFittingFit;
@class Fit;
@class DamagePattern;
@interface FittingViewController : UIViewController<UIActionSheetDelegate,
													UITextFieldDelegate,
													BrowserViewControllerDelegate,
													AreaEffectsViewControllerDelegate,
													CharactersViewControllerDelegate,
													DamagePatternsViewControllerDelegate,
													FitsViewControllerDelegate,
													TargetsViewControllerDelegate> {
	UIView *sectionsView;
	UISegmentedControl *sectionSegmentControl;
	UINavigationController *modalController;
	UINavigationController *targetsModalController;
	UINavigationController *areaEffectsModalController;
	TargetsViewController* targetsViewController;
	AreaEffectsViewController* areaEffectsViewController;
	ModulesViewController *modulesViewController;
	DronesViewController *dronesViewController;
	ImplantsViewController *implantsViewController;
	StatsViewController *statsViewController;
	FleetViewController *fleetViewController;

	UIView *shadeView;
	UIToolbar *fitNameView;
	UITextField *fitNameTextField;
	UIView *statsSectionView;
	UIPopoverController *popoverController;
	UIPopoverController *targetsPopoverController;
	UIPopoverController *areaEffectsPopoverController;
	Fit* fit;

	eufe::Engine* fittingEngine;
	NSMutableArray* fits;
	DamagePattern* damagePattern;
@private
	UIViewController<FittingSection> *currentSection;
	NSInteger currentSectionIndex;
	UIActionSheet *actionSheet;
}
@property (nonatomic, retain) IBOutlet UIView *sectionsView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *sectionSegmentControl;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) IBOutlet UINavigationController *targetsModalController;
@property (nonatomic, retain) IBOutlet UINavigationController *areaEffectsModalController;
@property (nonatomic, retain) IBOutlet TargetsViewController* targetsViewController;
@property (nonatomic, retain) IBOutlet AreaEffectsViewController* areaEffectsViewController;
@property (nonatomic, retain) IBOutlet ModulesViewController *modulesViewController;
@property (nonatomic, retain) IBOutlet DronesViewController *dronesViewController;
@property (nonatomic, retain) IBOutlet ImplantsViewController *implantsViewController;
@property (nonatomic, retain) IBOutlet StatsViewController *statsViewController;
@property (nonatomic, retain) IBOutlet FleetViewController *fleetViewController;

@property (nonatomic, retain) IBOutlet UIView *shadeView;
@property (nonatomic, retain) IBOutlet UIToolbar *fitNameView;
@property (nonatomic, retain) IBOutlet UITextField *fitNameTextField;
@property (nonatomic, retain) IBOutlet UIView *statsSectionView;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIPopoverController *targetsPopoverController;
@property (nonatomic, retain) UIPopoverController *areaEffectsPopoverController;

@property (nonatomic, retain) Fit* fit;

@property (nonatomic, readonly) eufe::Engine* fittingEngine;
@property (nonatomic, retain, readonly) NSMutableArray* fits;
@property (nonatomic, retain) DamagePattern* damagePattern;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) didChangeSection:(id) sender;
- (IBAction) onMenu:(id) sender;
- (IBAction) onDone:(id) sender;
- (IBAction) onBack:(id) sender;
- (void) update;
- (void) addFleetMember;
- (void) selectCharacterForFit:(Fit*) fit;

@end
