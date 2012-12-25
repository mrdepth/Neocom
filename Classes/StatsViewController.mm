//
//  StatsViewController.m
//  EVEUniverse
//
//  Created by Artem Shimanski on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StatsViewController.h"
#import "FittingViewController.h"
#import "NSString+Fitting.h"
#import "NSString+TimeLeft.h"
#import "EUOperationQueue.h"
#import "Fit.h"
#import "ItemInfo.h"
#import "PriceManager.h"

#import "eufe.h"

@interface StatsViewController(Private)
- (void) updatePrice;
@end

@implementation StatsViewController
@synthesize fittingViewController;
@synthesize scrollView;
@synthesize contentView;

@synthesize powerGridLabel;
@synthesize cpuLabel;
@synthesize droneBayLabel;
@synthesize droneBandwidthLabel;
@synthesize calibrationLabel;
@synthesize turretsLabel;
@synthesize launchersLabel;
@synthesize dronesLabel;

@synthesize shieldEMLabel;
@synthesize shieldThermalLabel;
@synthesize shieldKineticLabel;
@synthesize shieldExplosiveLabel;
@synthesize armorEMLabel;
@synthesize armorThermalLabel;
@synthesize armorKineticLabel;
@synthesize armorExplosiveLabel;
@synthesize hullEMLabel;
@synthesize hullThermalLabel;
@synthesize hullKineticLabel;
@synthesize hullExplosiveLabel;
@synthesize damagePatternEMLabel;
@synthesize damagePatternThermalLabel;
@synthesize damagePatternKineticLabel;
@synthesize damagePatternExplosiveLabel;

@synthesize shieldHPLabel;
@synthesize armorHPLabel;
@synthesize hullHPLabel;
@synthesize ehpLabel;

@synthesize shieldSustainedRecharge;
@synthesize shieldReinforcedBoost;
@synthesize shieldSustainedBoost;
@synthesize armorReinforcedRepair;
@synthesize armorSustainedRepair;
@synthesize hullReinforcedRepair;
@synthesize hullSustainedRepair;

@synthesize capacitorCapacityLabel;
@synthesize capacitorStateLabel;
@synthesize capacitorRechargeTimeLabel;
@synthesize capacitorDeltaLabel;

@synthesize weaponDPSLabel;
@synthesize droneDPSLabel;
@synthesize volleyDamageLabel;
@synthesize dpsLabel;

@synthesize targetsLabel;
@synthesize targetRangeLabel;
@synthesize scanResLabel;
@synthesize sensorStrLabel;
@synthesize speedLabel;
@synthesize alignTimeLabel;
@synthesize signatureLabel;
@synthesize cargoLabel;
@synthesize sensorImageView;
@synthesize droneRangeLabel;
@synthesize warpSpeedLabel;

@synthesize shipPriceLabel;
@synthesize fittingsPriceLabel;
@synthesize totalPriceLabel;


// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self.scrollView addSubview:self.contentView];
	self.scrollView.contentSize = self.contentView.frame.size;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.scrollView = nil;
	self.contentView = nil;
	
	self.powerGridLabel = nil;
	self.cpuLabel = nil;
	self.droneBayLabel = nil;
	self.droneBandwidthLabel = nil;
	self.calibrationLabel = nil;
	self.turretsLabel = nil;
	self.launchersLabel = nil;
	self.dronesLabel = nil;
	
	self.shieldEMLabel = nil;
	self.shieldThermalLabel = nil;
	self.shieldKineticLabel = nil;
	self.shieldExplosiveLabel = nil;
	self.armorEMLabel = nil;
	self.armorThermalLabel = nil;
	self.armorKineticLabel = nil;
	self.armorExplosiveLabel = nil;
	self.hullEMLabel = nil;
	self.hullThermalLabel = nil;
	self.hullKineticLabel = nil;
	self.hullExplosiveLabel = nil;
	self.damagePatternEMLabel = nil;
	self.damagePatternThermalLabel = nil;
	self.damagePatternKineticLabel = nil;
	self.damagePatternExplosiveLabel = nil;
	
	self.shieldHPLabel = nil;
	self.armorHPLabel = nil;
	self.hullHPLabel = nil;
	self.ehpLabel = nil;
	
	self.shieldSustainedRecharge = nil;
	self.shieldReinforcedBoost = nil;
	self.shieldSustainedBoost = nil;
	self.armorReinforcedRepair = nil;
	self.armorSustainedRepair = nil;
	self.hullReinforcedRepair = nil;
	self.hullSustainedRepair = nil;
	
	self.capacitorCapacityLabel = nil;
	self.capacitorStateLabel = nil;
	self.capacitorRechargeTimeLabel = nil;
	self.capacitorDeltaLabel = nil;
	
	self.weaponDPSLabel = nil;
	self.droneDPSLabel = nil;
	self.volleyDamageLabel = nil;
	self.dpsLabel = nil;
	
	self.targetsLabel = nil;
	self.targetRangeLabel = nil;
	self.scanResLabel = nil;
	self.sensorStrLabel = nil;
	self.speedLabel = nil;
	self.alignTimeLabel = nil;
	self.signatureLabel = nil;
	self.cargoLabel = nil;
	self.sensorImageView = nil;
	self.droneRangeLabel = nil;
	self.warpSpeedLabel = nil;
	
	self.shipPriceLabel = nil;
	self.fittingsPriceLabel = nil;
	self.totalPriceLabel = nil;

}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self update];
}


- (void)dealloc {
	[scrollView release];
	[contentView release];
	
	[powerGridLabel release];
	[cpuLabel release];
	[droneBayLabel release];
	[droneBandwidthLabel release];
	[calibrationLabel release];
	[turretsLabel release];
	[launchersLabel release];
	[dronesLabel release];
	
	[shieldEMLabel release];
	[shieldThermalLabel release];
	[shieldKineticLabel release];
	[shieldExplosiveLabel release];
	[armorEMLabel release];
	[armorThermalLabel release];
	[armorKineticLabel release];
	[armorExplosiveLabel release];
	[hullEMLabel release];
	[hullThermalLabel release];
	[hullKineticLabel release];
	[hullExplosiveLabel release];
	[damagePatternEMLabel release];
	[damagePatternThermalLabel release];
	[damagePatternKineticLabel release];
	[damagePatternExplosiveLabel release];
	
	[shieldHPLabel release];
	[armorHPLabel release];
	[hullHPLabel release];
	[ehpLabel release];
	
	[shieldSustainedRecharge release];
	[shieldReinforcedBoost release];
	[shieldSustainedBoost release];
	[armorReinforcedRepair release];
	[armorSustainedRepair release];
	[hullReinforcedRepair release];
	[hullSustainedRepair release];
	
	[capacitorCapacityLabel release];
	[capacitorStateLabel release];
	[capacitorRechargeTimeLabel release];
	[capacitorDeltaLabel release];
	
	[weaponDPSLabel release];
	[droneDPSLabel release];
	[volleyDamageLabel release];
	[dpsLabel release];
	
	[targetsLabel release];
	[targetRangeLabel release];
	[scanResLabel release];
	[sensorStrLabel release];
	[speedLabel release];
	[alignTimeLabel release];
	[signatureLabel release];
	[cargoLabel release];
	[sensorImageView release];
	[droneRangeLabel release];
	[warpSpeedLabel release];
	
	[shipPriceLabel release];
	[fittingsPriceLabel release];
	[totalPriceLabel release];

    [super dealloc];
}


#pragma mark FittingSection

- (void) update {
	__block float totalPG;
	__block float usedPG;
	__block float totalCPU;
	__block float usedCPU;
	__block float totalCalibration;
	__block float usedCalibration;
	__block int usedTurretHardpoints;
	__block int totalTurretHardpoints;
	__block int usedMissileHardpoints;
	__block int totalMissileHardpoints;
	
	__block float totalDB;
	__block float usedDB;
	__block float totalBandwidth;
	__block float usedBandwidth;
	__block int maxActiveDrones;
	__block int activeDrones;
	__block eufe::Resistances resistances;
	__block eufe::HitPoints hp;
	__block float ehp;
	__block eufe::Tank rtank;
	__block eufe::Tank stank;
	__block eufe::Tank ertank;
	__block eufe::Tank estank;
	
	__block float capCapacity;
	__block BOOL capStable;
	__block float capState;
	__block float capacitorRechargeTime;
	__block float delta;
	
	__block float weaponDPS;
	__block float droneDPS;
	__block float volleyDamage;
	__block float dps;
	
	__block int targets;
	__block float targetRange;
	__block float scanRes;
	__block float sensorStr;
	__block float speed;
	__block float alignTime;
	__block float signature;
	__block float cargo;
	__block UIImage *sensorImage = nil;
	__block DamagePattern* damagePattern = nil;
	__block float droneRange;
	__block float warpSpeed;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"StatsViewController+Update" name:NSLocalizedString(@"Updating Stats", nil)];
	FittingViewController* aFittingViewController = fittingViewController;

	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			eufe::Character* character = aFittingViewController.fit.character;
			eufe::Ship* ship = character->getShip();
			
			totalPG = ship->getTotalPowerGrid();
			usedPG = ship->getPowerGridUsed();
			
			totalCPU = ship->getTotalCpu();
			usedCPU = ship->getCpuUsed();
			
			totalCalibration = ship->getTotalCalibration();
			usedCalibration = ship->getCalibrationUsed();
			
			operation.progress = 0.25;
			
			maxActiveDrones = ship->getMaxActiveDrones();
			activeDrones = ship->getActiveDrones();
			
			
			totalBandwidth = ship->getTotalDroneBandwidth();
			usedBandwidth = ship->getDroneBandwidthUsed();
			
			totalDB = ship->getTotalDroneBay();
			usedDB = ship->getDroneBayUsed();
			
			usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
			totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
			usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			
			resistances = ship->getResistances();

			operation.progress = 0.5;
			
			hp = ship->getHitPoints();
			eufe::HitPoints effectiveHitPoints = ship->getEffectiveHitPoints();
			ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
			
			rtank = ship->getTank();
			stank = ship->getSustainableTank();
			ertank = ship->getEffectiveTank();
			estank = ship->getEffectiveSustainableTank();
			
			capCapacity = ship->getCapCapacity();
			capStable = ship->isCapStable();
			capState = capStable ? ship->getCapStableLevel() * 100.0 : ship->getCapLastsTime();
			capacitorRechargeTime = ship->getAttribute(eufe::RECHARGE_RATE_ATTRIBUTE_ID)->getValue() / 1000.0;
			delta = ship->getCapRecharge() - ship->getCapUsed();
			
			weaponDPS = ship->getWeaponDps();
			droneDPS = ship->getDroneDps();
			volleyDamage = ship->getWeaponVolley() + ship->getDroneVolley();
			dps = weaponDPS + droneDPS;

			operation.progress = 0.75;
			
			targets = ship->getMaxTargets();
			targetRange = ship->getMaxTargetRange() / 1000.0;
			scanRes = ship->getScanResolution();
			sensorStr = ship->getScanStrength();
			speed = ship->getVelocity();
			alignTime = ship->getAlignTime();
			signature =ship->getSignatureRadius();
			cargo =ship->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue();
			
			switch(ship->getScanType()) {
				case eufe::Ship::SCAN_TYPE_GRAVIMETRIC:
					sensorImage = [[UIImage imageNamed:@"Gravimetric.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_LADAR:
					sensorImage = [[UIImage imageNamed:@"Ladar.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_MAGNETOMETRIC:
					sensorImage = [[UIImage imageNamed:@"Magnetometric.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_RADAR:
					sensorImage = [[UIImage imageNamed:@"Radar.png"] retain];
					break;
				default:
					sensorImage = [[UIImage imageNamed:@"Multispectral.png"] retain];
					break;
			}
			
			droneRange = character->getAttribute(eufe::DRONE_CONTROL_DISTANCE_ATTRIBUTE_ID)->getValue() / 1000;
			warpSpeed = ship->getWarpSpeed();

			damagePattern = [aFittingViewController.damagePattern retain];
			operation.progress = 1.0;

		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			
			if (usedCalibration > totalCalibration)
				calibrationLabel.textColor = [UIColor redColor];
			else
				calibrationLabel.textColor = [UIColor whiteColor];
			
			dronesLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				dronesLabel.textColor = [UIColor redColor];
			else
				dronesLabel.textColor = [UIColor whiteColor];
			
			droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			
			turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			
			NSArray *resistanceLabels = [NSArray arrayWithObjects:shieldEMLabel, shieldThermalLabel, shieldKineticLabel, shieldExplosiveLabel,
										 armorEMLabel, armorThermalLabel, armorKineticLabel, armorExplosiveLabel,
										 hullEMLabel, hullThermalLabel, hullKineticLabel, hullExplosiveLabel,
										 damagePatternEMLabel, damagePatternThermalLabel, damagePatternKineticLabel, damagePatternExplosiveLabel, nil];
			
			float resistanceValues[] = {resistances.shield.em, resistances.shield.thermal, resistances.shield.kinetic, resistances.shield.explosive,
										resistances.armor.em, resistances.armor.thermal, resistances.armor.kinetic, resistances.armor.explosive,
										resistances.hull.em, resistances.hull.thermal, resistances.hull.kinetic, resistances.hull.explosive,
										damagePattern.emAmount, damagePattern.thermalAmount, damagePattern.kineticAmount, damagePattern.explosiveAmount};
			for (int i = 0; i < 16; i++) {
				ProgressLabel *label = [resistanceLabels objectAtIndex:i];
				float resist = resistanceValues[i];
				label.progress = resist;
				label.text = [NSString stringWithFormat:@"%.1f%%", resist * 100];
			}
			
			shieldHPLabel.text = [NSString stringWithResource:hp.shield unit:nil];
			armorHPLabel.text = [NSString stringWithResource:hp.armor unit:nil];
			hullHPLabel.text = [NSString stringWithResource:hp.hull unit:nil];
			
			ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString stringWithResource:ehp unit:nil]];
			
			shieldReinforcedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair];
			shieldSustainedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.shieldRepair, estank.shieldRepair];
			armorReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair];
			armorSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.armorRepair, estank.armorRepair];
			hullReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair];
			hullSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.hullRepair, estank.hullRepair];
			shieldSustainedRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.passiveShield, estank.passiveShield];
			
			capacitorCapacityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString stringWithResource:capCapacity unit:@"GJ"]];
			if (capStable)
				capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), capState];
			else
				capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Lasts %@", nil), [NSString stringWithTimeLeft:capState]];
			capacitorRechargeTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:capacitorRechargeTime]];
			capacitorDeltaLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%.2f GJ/s", nil), delta >= 0.0 ? @"+" : @"", delta];
			
			weaponDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil),weaponDPS];
			droneDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil),droneDPS];
			volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f",volleyDamage];
			dpsLabel.text = [NSString stringWithFormat:@"%.0f",dps];
			
			targetsLabel.text = [NSString stringWithFormat:@"%d", targets];
			targetRangeLabel.text = [NSString stringWithFormat:@"%.1f km", targetRange];
			scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", scanRes];
			sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", sensorStr];
			speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", speed];
			alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", alignTime];
			signatureLabel.text = [NSString stringWithFormat:@"%.0f", signature];
			cargoLabel.text = [NSString stringWithResource:cargo unit:@"m3"];
			sensorImageView.image = sensorImage;

			droneRangeLabel.text = [NSString stringWithFormat:@"%.1f km", droneRange];
			warpSpeedLabel.text = [NSString stringWithFormat:@"%.2f AU/s", warpSpeed];

		}
		[sensorImage release];
		[damagePattern release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self updatePrice];
}

@end

@implementation StatsViewController(Private)

- (void) updatePrice {
	__block float shipPrice;
	__block float fittingsPrice;
	__block float totalPrice;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"StatsViewController+UpdatePrice" name:NSLocalizedString(@"Updating Price", nil)];
	FittingViewController* aFittingViewController = fittingViewController;
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSCountedSet* types = [NSCountedSet set];
		ItemInfo* shipInfo = nil;
		
		@synchronized(fittingViewController) {
			eufe::Character* character = aFittingViewController.fit.character;
			eufe::Ship* ship = character->getShip();
			
			shipInfo = [ItemInfo itemInfoWithItem:ship error:nil];
			[types addObject:shipInfo];
			
			const eufe::ModulesList& modulesList = ship->getModules();
			eufe::ModulesList::const_iterator i, end = modulesList.end();
			
			for (i = modulesList.begin(); i != end; i++) {
				ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:*i error:nil];
				if (itemInfo)
					[types addObject:itemInfo];
			}

			const eufe::DronesList& dronesList = ship->getDrones();
			eufe::DronesList::const_iterator j, endj = dronesList.end();
			
			for (j = dronesList.begin(); j != endj; j++) {
				ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:*j error:nil];
				if (itemInfo)
					[types addObject:itemInfo];
			}
		}
		NSDictionary* prices = [aFittingViewController.priceManager pricesWithTypes:[types allObjects]];
		shipPrice = [aFittingViewController.priceManager priceWithType:shipInfo];
		fittingsPrice = 0;
		for (ItemInfo* itemInfo in types) {
			if (itemInfo != shipInfo) {
				int count = [types countForObject:itemInfo];
				NSString* key = [NSString stringWithFormat:@"%d", itemInfo.typeID];
				fittingsPrice += [[prices valueForKey:key] floatValue] * count;
			}
		}
		
		totalPrice = shipPrice + fittingsPrice;
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			shipPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:shipPrice unit:nil]];
			fittingsPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:fittingsPrice unit:nil]];
			totalPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:totalPrice unit:nil]];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end