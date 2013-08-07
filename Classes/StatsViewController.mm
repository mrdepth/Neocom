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
#import "ShipFit.h"
#import "ItemInfo.h"
#import "PriceManager.h"

#import "eufe.h"

@interface StatsViewController()
- (void) updatePrice;
@end

@implementation StatsViewController



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

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
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
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Character* character = self.fittingViewController.fit.character;
			eufe::Ship* ship = character->getShip();
			
			totalPG = ship->getTotalPowerGrid();
			usedPG = ship->getPowerGridUsed();
			
			totalCPU = ship->getTotalCpu();
			usedCPU = ship->getCpuUsed();
			
			totalCalibration = ship->getTotalCalibration();
			usedCalibration = ship->getCalibrationUsed();
			
			weakOperation.progress = 0.25;
			
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

			weakOperation.progress = 0.5;
			
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

			weakOperation.progress = 0.75;
			
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
					sensorImage = [UIImage imageNamed:@"Gravimetric.png"];
					break;
				case eufe::Ship::SCAN_TYPE_LADAR:
					sensorImage = [UIImage imageNamed:@"Ladar.png"];
					break;
				case eufe::Ship::SCAN_TYPE_MAGNETOMETRIC:
					sensorImage = [UIImage imageNamed:@"Magnetometric.png"];
					break;
				case eufe::Ship::SCAN_TYPE_RADAR:
					sensorImage = [UIImage imageNamed:@"Radar.png"];
					break;
				default:
					sensorImage = [UIImage imageNamed:@"Multispectral.png"];
					break;
			}
			
			droneRange = character->getAttribute(eufe::DRONE_CONTROL_DISTANCE_ATTRIBUTE_ID)->getValue() / 1000;
			warpSpeed = ship->getWarpSpeed();

			damagePattern = self.fittingViewController.damagePattern;
			weakOperation.progress = 1.0;

		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			self.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			
			if (usedCalibration > totalCalibration)
				self.calibrationLabel.textColor = [UIColor redColor];
			else
				self.calibrationLabel.textColor = [UIColor whiteColor];
			
			self.dronesLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				self.dronesLabel.textColor = [UIColor redColor];
			else
				self.dronesLabel.textColor = [UIColor whiteColor];
			
			self.droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			self.droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			self.droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			self.droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			
			self.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			self.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			
			NSArray *resistanceLabels = [NSArray arrayWithObjects:self.shieldEMLabel, self.shieldThermalLabel, self.shieldKineticLabel, self.shieldExplosiveLabel,
										 self.armorEMLabel, self.armorThermalLabel, self.armorKineticLabel, self.armorExplosiveLabel,
										 self.hullEMLabel, self.hullThermalLabel, self.hullKineticLabel, self.hullExplosiveLabel,
										 self.damagePatternEMLabel, self.damagePatternThermalLabel, self.damagePatternKineticLabel, self.damagePatternExplosiveLabel, nil];
			
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
			
			self.shieldHPLabel.text = [NSString stringWithResource:hp.shield unit:nil];
			self.armorHPLabel.text = [NSString stringWithResource:hp.armor unit:nil];
			self.hullHPLabel.text = [NSString stringWithResource:hp.hull unit:nil];
			
			self.ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString stringWithResource:ehp unit:nil]];
			
			self.shieldReinforcedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair];
			self.shieldSustainedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.shieldRepair, estank.shieldRepair];
			self.armorReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair];
			self.armorSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.armorRepair, estank.armorRepair];
			self.hullReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair];
			self.hullSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.hullRepair, estank.hullRepair];
			self.shieldSustainedRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.passiveShield, estank.passiveShield];
			
			self.capacitorCapacityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString stringWithResource:capCapacity unit:@"GJ"]];
			if (capStable)
				self.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), capState];
			else
				self.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Lasts %@", nil), [NSString stringWithTimeLeft:capState]];
			self.capacitorRechargeTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:capacitorRechargeTime]];
			self.capacitorDeltaLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%.2f GJ/s", nil), delta >= 0.0 ? @"+" : @"", delta];
			
			self.weaponDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil),weaponDPS];
			self.droneDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil),droneDPS];
			self.volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f",volleyDamage];
			self.dpsLabel.text = [NSString stringWithFormat:@"%.0f",dps];
			
			self.targetsLabel.text = [NSString stringWithFormat:@"%d", targets];
			self.targetRangeLabel.text = [NSString stringWithFormat:@"%.1f km", targetRange];
			self.scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", scanRes];
			self.sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", sensorStr];
			self.speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", speed];
			self.alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", alignTime];
			self.signatureLabel.text = [NSString stringWithFormat:@"%.0f", signature];
			self.cargoLabel.text = [NSString stringWithResource:cargo unit:@"m3"];
			self.sensorImageView.image = sensorImage;

			self.droneRangeLabel.text = [NSString stringWithFormat:@"%.1f km", droneRange];
			self.warpSpeedLabel.text = [NSString stringWithFormat:@"%.2f AU/s", warpSpeed];

		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self updatePrice];
}

#pragma mark - Private

- (void) updatePrice {
	__block float shipPrice;
	__block float fittingsPrice;
	__block float totalPrice;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"StatsViewController+UpdatePrice" name:NSLocalizedString(@"Updating Price", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		NSCountedSet* types = [NSCountedSet set];
		ItemInfo* shipInfo = nil;
		
		@synchronized(self.fittingViewController) {
			eufe::Character* character = self.fittingViewController.fit.character;
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
		NSDictionary* prices = [self.fittingViewController.priceManager pricesWithTypes:[types allObjects]];
		shipPrice = [self.fittingViewController.priceManager priceWithType:shipInfo];
		fittingsPrice = 0;
		for (ItemInfo* itemInfo in types) {
			if (itemInfo != shipInfo) {
				int count = [types countForObject:itemInfo];
				fittingsPrice += [prices[@(itemInfo.typeID)] floatValue] * count;
			}
		}
		
		totalPrice = shipPrice + fittingsPrice;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.shipPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:shipPrice unit:nil]];
			self.fittingsPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:fittingsPrice unit:nil]];
			self.totalPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:totalPrice unit:nil]];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end