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
@interface POSStatsViewController : UIViewController<FittingSection>
@property (nonatomic, weak) IBOutlet POSFittingViewController *posFittingViewController;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;

@property (nonatomic, weak) IBOutlet ProgressLabel *shieldEMLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *shieldThermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *shieldKineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *shieldExplosiveLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *armorEMLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *armorThermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *armorKineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *armorExplosiveLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *hullEMLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *hullThermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *hullKineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *hullExplosiveLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *damagePatternEMLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *damagePatternThermalLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *damagePatternKineticLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *damagePatternExplosiveLabel;

@property (nonatomic, weak) IBOutlet UILabel *shieldHPLabel;
@property (nonatomic, weak) IBOutlet UILabel *armorHPLabel;
@property (nonatomic, weak) IBOutlet UILabel *hullHPLabel;
@property (nonatomic, weak) IBOutlet UILabel *ehpLabel;

@property (nonatomic, weak) IBOutlet UILabel *shieldRecharge;

@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;

@property (nonatomic, weak) IBOutlet UILabel *fuelTypeLabel;
@property (nonatomic, weak) IBOutlet UILabel *fuelCostLabel;
@property (nonatomic, weak) IBOutlet UIImageView *fuelImageView;
@property (nonatomic, weak) IBOutlet UILabel *infrastructureUpgradesCostLabel;
@property (nonatomic, weak) IBOutlet UILabel *posCostLabel;


@end