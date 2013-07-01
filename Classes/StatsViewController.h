//
//  StatsViewController.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressLabel.h"
#import "FittingSection.h"

@class FittingViewController;
@interface StatsViewController : UIViewController<FittingSection>
@property (nonatomic, weak) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, weak) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet ProgressLabel *droneBandwidthLabel;
@property (nonatomic, weak) IBOutlet UILabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet UILabel *turretsLabel;
@property (nonatomic, weak) IBOutlet UILabel *launchersLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesLabel;

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

@property (nonatomic, weak) IBOutlet UILabel *shieldSustainedRecharge;
@property (nonatomic, weak) IBOutlet UILabel *shieldReinforcedBoost;
@property (nonatomic, weak) IBOutlet UILabel *shieldSustainedBoost;
@property (nonatomic, weak) IBOutlet UILabel *armorReinforcedRepair;
@property (nonatomic, weak) IBOutlet UILabel *armorSustainedRepair;
@property (nonatomic, weak) IBOutlet UILabel *hullReinforcedRepair;
@property (nonatomic, weak) IBOutlet UILabel *hullSustainedRepair;

@property (nonatomic, weak) IBOutlet UILabel *capacitorCapacityLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorStateLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorRechargeTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *capacitorDeltaLabel;

@property (nonatomic, weak) IBOutlet UILabel *weaponDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *droneDPSLabel;
@property (nonatomic, weak) IBOutlet UILabel *volleyDamageLabel;
@property (nonatomic, weak) IBOutlet UILabel *dpsLabel;

@property (nonatomic, weak) IBOutlet UILabel *targetsLabel;
@property (nonatomic, weak) IBOutlet UILabel *targetRangeLabel;
@property (nonatomic, weak) IBOutlet UILabel *scanResLabel;
@property (nonatomic, weak) IBOutlet UILabel *sensorStrLabel;
@property (nonatomic, weak) IBOutlet UILabel *speedLabel;
@property (nonatomic, weak) IBOutlet UILabel *alignTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *signatureLabel;
@property (nonatomic, weak) IBOutlet UILabel *cargoLabel;
@property (nonatomic, weak) IBOutlet UIImageView *sensorImageView;
@property (nonatomic, weak) IBOutlet UILabel *droneRangeLabel;
@property (nonatomic, weak) IBOutlet UILabel *warpSpeedLabel;

@property (nonatomic, weak) IBOutlet UILabel *shipPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *fittingsPriceLabel;
@property (nonatomic, weak) IBOutlet UILabel *totalPriceLabel;



@end
