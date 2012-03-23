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

#import "eufe.h"

@class POSFit;
@class DamagePattern;
@class EVEDBInvControlTowerResource;
@class PriceManager;
@interface POSFittingViewController : UIViewController<UIActionSheetDelegate,UITextFieldDelegate, AreaEffectsViewControllerDelegate, DamagePatternsViewControllerDelegate> {
	UIView *sectionsView;
	UISegmentedControl *sectionSegmentControl;
	UINavigationController *modalController;
	UINavigationController *areaEffectsModalController;
	AreaEffectsViewController* areaEffectsViewController;
	StructuresViewController *structuresViewController;
	AssemblyLinesViewController* assemblyLinesViewController;
	POSStatsViewController *posStatsViewController;
	
	UIView *shadeView;
	UIToolbar *fitNameView;
	UITextField *fitNameTextField;
	UIView *statsSectionView;
	UIPopoverController *popoverController;
	UIPopoverController *areaEffectsPopoverController;
	POSFit* fit;
	
	eufe::Engine* fittingEngine;
	DamagePattern* damagePattern;
	
	EVEDBInvControlTowerResource* posFuelRequirements;
	PriceManager* priceManager;
@private
	UIViewController<FittingSection> *currentSection;
	NSInteger currentSectionIndex;
	UIActionSheet *actionSheet;
}
@property (nonatomic, retain) IBOutlet UIView *sectionsView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *sectionSegmentControl;
@property (nonatomic, retain) IBOutlet UINavigationController *modalController;
@property (nonatomic, retain) IBOutlet UINavigationController *areaEffectsModalController;
@property (nonatomic, retain) IBOutlet AreaEffectsViewController* areaEffectsViewController;
@property (nonatomic, retain) IBOutlet StructuresViewController *structuresViewController;
@property (nonatomic, retain) IBOutlet AssemblyLinesViewController* assemblyLinesViewController;
@property (nonatomic, retain) IBOutlet POSStatsViewController *posStatsViewController;

@property (nonatomic, retain) IBOutlet UIView *shadeView;
@property (nonatomic, retain) IBOutlet UIToolbar *fitNameView;
@property (nonatomic, retain) IBOutlet UITextField *fitNameTextField;
@property (nonatomic, retain) IBOutlet UIView *statsSectionView;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIPopoverController *areaEffectsPopoverController;

@property (nonatomic, retain) POSFit* fit;

@property (nonatomic, readonly) eufe::Engine* fittingEngine;
@property (nonatomic, retain) DamagePattern* damagePattern;

@property (nonatomic, retain) EVEDBInvControlTowerResource* posFuelRequirements;
@property (nonatomic, retain) PriceManager* priceManager;

- (IBAction) didCloseModalViewController:(id) sender;
- (IBAction) didChangeSection:(id) sender;
- (IBAction) onMenu:(id) sender;
- (IBAction) onDone:(id) sender;
- (IBAction) onBack:(id) sender;
- (void) update;

@end
