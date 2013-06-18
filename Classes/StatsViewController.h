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
@property (nonatomic, assign) IBOutlet FittingViewController *fittingViewController;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *contentView;

@property (nonatomic, retain) IBOutlet ProgressLabel *powerGridLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *cpuLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *droneBayLabel;
@property (nonatomic, retain) IBOutlet ProgressLabel *droneBandwidthLabel;
@property (nonatomic, retain) IBOutlet UILabel *calibrationLabel;
@property (nonatomic, retain) IBOutlet UILabel *turretsLabel;
@property (nonatomic, retain) IBOutlet UILabel *launchersLabel;
@property (nonatomic, retain) IBOutlet UILabel *dronesLabel;

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

@property (nonatomic, retain) IBOutlet UILabel *shieldSustainedRecharge;
@property (nonatomic, retain) IBOutlet UILabel *shieldReinforcedBoost;
@property (nonatomic, retain) IBOutlet UILabel *shieldSustainedBoost;
@property (nonatomic, retain) IBOutlet UILabel *armorReinforcedRepair;
@property (nonatomic, retain) IBOutlet UILabel *armorSustainedRepair;
@property (nonatomic, retain) IBOutlet UILabel *hullReinforcedRepair;
@property (nonatomic, retain) IBOutlet UILabel *hullSustainedRepair;

@property (nonatomic, retain) IBOutlet UILabel *capacitorCapacityLabel;
@property (nonatomic, retain) IBOutlet UILabel *capacitorStateLabel;
@property (nonatomic, retain) IBOutlet UILabel *capacitorRechargeTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *capacitorDeltaLabel;

@property (nonatomic, retain) IBOutlet UILabel *weaponDPSLabel;
@property (nonatomic, retain) IBOutlet UILabel *droneDPSLabel;
@property (nonatomic, retain) IBOutlet UILabel *volleyDamageLabel;
@property (nonatomic, retain) IBOutlet UILabel *dpsLabel;

@property (nonatomic, retain) IBOutlet UILabel *targetsLabel;
@property (nonatomic, retain) IBOutlet UILabel *targetRangeLabel;
@property (nonatomic, retain) IBOutlet UILabel *scanResLabel;
@property (nonatomic, retain) IBOutlet UILabel *sensorStrLabel;
@property (nonatomic, retain) IBOutlet UILabel *speedLabel;
@property (nonatomic, retain) IBOutlet UILabel *alignTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *signatureLabel;
@property (nonatomic, retain) IBOutlet UILabel *cargoLabel;
@property (nonatomic, retain) IBOutlet UIImageView *sensorImageView;
@property (nonatomic, retain) IBOutlet UILabel *droneRangeLabel;
@property (nonatomic, retain) IBOutlet UILabel *warpSpeedLabel;

@property (nonatomic, retain) IBOutlet UILabel *shipPriceLabel;
@property (nonatomic, retain) IBOutlet UILabel *fittingsPriceLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalPriceLabel;



@end
