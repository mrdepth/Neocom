//
//  POSStatsViewController.h
//  EVEUniverse
//
//  Created by Mr. Depth on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLabel.h"
#import "FittingSection.h"

@class POSFittingViewController;
@interface POSStatsViewController : UIViewController<FittingSection> {
	POSFittingViewController *posFittingViewController;
	UIScrollView *scrollView;
	UIView *contentView;
	
	ProgressLabel *powerGridLabel;
	ProgressLabel *cpuLabel;
	
	ProgressLabel *shieldEMLabel;
	ProgressLabel *shieldThermalLabel;
	ProgressLabel *shieldKineticLabel;
	ProgressLabel *shieldExplosiveLabel;
	ProgressLabel *armorEMLabel;
	ProgressLabel *armorThermalLabel;
	ProgressLabel *armorKineticLabel;
	ProgressLabel *armorExplosiveLabel;
	ProgressLabel *hullEMLabel;
	ProgressLabel *hullThermalLabel;
	ProgressLabel *hullKineticLabel;
	ProgressLabel *hullExplosiveLabel;
	ProgressLabel *damagePatternEMLabel;
	ProgressLabel *damagePatternThermalLabel;
	ProgressLabel *damagePatternKineticLabel;
	ProgressLabel *damagePatternExplosiveLabel;
	
	UILabel *shieldHPLabel;
	UILabel *armorHPLabel;
	UILabel *hullHPLabel;
	UILabel *ehpLabel;
	
	UILabel *shieldRecharge;
	
	UILabel *weaponDPSLabel;
	
	UILabel *fuelTypeLabel;
	UILabel *fuelCostLabel;
	UIImageView *fuelImageView;
	UILabel *infrastructureUpgradesCostLabel;
	UILabel *posCostLabel;
}
@property (nonatomic, assign) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *contentView;

@property (nonatomic, retain) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *cpuLabel;

@property (nonatomic, retain) IBOutlet ProgressLabel *shieldEMLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *shieldThermalLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *shieldKineticLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *shieldExplosiveLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *armorEMLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *armorThermalLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *armorKineticLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *armorExplosiveLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *hullEMLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *hullThermalLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *hullKineticLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *hullExplosiveLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *damagePatternEMLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *damagePatternThermalLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *damagePatternKineticLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *damagePatternExplosiveLabel;

@property (nonatomic, retain) IBOutlet UILabel *shieldHPLabel;
@property (nonatomic, retain) IBOutlet UILabel *armorHPLabel;
@property (nonatomic, retain) IBOutlet UILabel *hullHPLabel;
@property (nonatomic, retain) IBOutlet UILabel *ehpLabel;

@property (nonatomic, retain) IBOutlet UILabel *shieldRecharge;

@property (nonatomic, retain) IBOutlet UILabel *weaponDPSLabel;

@property (nonatomic, retain) IBOutlet UILabel *fuelTypeLabel;
@property (nonatomic, retain) IBOutlet UILabel *fuelCostLabel;
@property (nonatomic, retain) IBOutlet UIImageView *fuelImageView;
@property (nonatomic, retain) IBOutlet UILabel *infrastructureUpgradesCostLabel;
@property (nonatomic, retain) IBOutlet UILabel *posCostLabel;


@end