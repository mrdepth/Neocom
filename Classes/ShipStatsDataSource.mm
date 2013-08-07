//
//  ShipStatsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 07.08.13.
//
//

#import "ShipStatsDataSource.h"
#import "FittingViewController.h"
#import "UITableViewCell+Nib.h"
#import "EUOperationQueue.h"
#import "PriceManager.h"
#import "ShipStatsBasicResourcesCell.h"
#import "ShipStatsWeaponResourcesCell.h"
#import "ShipStatsResistancesHeaderCell.h"
#import "ShipStatsResistancesCell.h"
#import "ShipStatsCapacitorCell.h"
#import "ShipStatsTankHeaderCell.h"
#import "ShipStatsTankCell.h"
#import "ShipStatsFirepowerCell.h"
#import "ShipStatsMiscCell.h"
#import "ShipStatsPriceCell.h"
#import "NSString+Fitting.h"
#import "NSString+TimeLeft.h"
#import "NSNumberFormatter+Neocom.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface ShipBasicStats : NSObject
@property (nonatomic, assign) float totalPG;
@property (nonatomic, assign) float usedPG;
@property (nonatomic, assign) float totalCPU;
@property (nonatomic, assign) float usedCPU;
@property (nonatomic, assign) float totalCalibration;
@property (nonatomic, assign) float usedCalibration;
@property (nonatomic, assign) int usedTurretHardpoints;
@property (nonatomic, assign) int totalTurretHardpoints;
@property (nonatomic, assign) int usedMissileHardpoints;
@property (nonatomic, assign) int totalMissileHardpoints;

@property (nonatomic, assign) float totalDB;
@property (nonatomic, assign) float usedDB;
@property (nonatomic, assign) float totalBandwidth;
@property (nonatomic, assign) float usedBandwidth;
@property (nonatomic, assign) int maxActiveDrones;
@property (nonatomic, assign) int activeDrones;
@property (nonatomic, assign) eufe::Resistances resistances;
@property (nonatomic, assign) eufe::HitPoints hp;
@property (nonatomic, assign) float ehp;
@property (nonatomic, assign) eufe::Tank rtank;
@property (nonatomic, assign) eufe::Tank stank;
@property (nonatomic, assign) eufe::Tank ertank;
@property (nonatomic, assign) eufe::Tank estank;

@property (nonatomic, assign) float capCapacity;
@property (nonatomic, assign) BOOL capStable;
@property (nonatomic, assign) float capState;
@property (nonatomic, assign) float capacitorRechargeTime;
@property (nonatomic, assign) float delta;

@property (nonatomic, assign) float weaponDPS;
@property (nonatomic, assign) float droneDPS;
@property (nonatomic, assign) float volleyDamage;
@property (nonatomic, assign) float dps;

@property (nonatomic, assign) int targets;
@property (nonatomic, assign) float targetRange;
@property (nonatomic, assign) float scanRes;
@property (nonatomic, assign) float sensorStr;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) float alignTime;
@property (nonatomic, assign) float signature;
@property (nonatomic, assign) float cargo;
@property (nonatomic, strong) UIImage *sensorImage;
@property (nonatomic, strong) DamagePattern* damagePattern;
@property (nonatomic, assign) float droneRange;
@property (nonatomic, assign) float warpSpeed;

@end

@interface ShipPriceStats : NSObject
@property (nonatomic, assign) float shipPrice;
@property (nonatomic, assign) float fittingsPrice;
@property (nonatomic, assign) float totalPrice;
@end

@implementation ShipBasicStats
@end

@implementation ShipPriceStats
@end


@interface ShipStatsDataSource()
@property (nonatomic, strong) ShipBasicStats* basicStats;
@property (nonatomic, strong) ShipPriceStats* priceStats;
@end


@implementation ShipStatsDataSource


- (void) reload {
	ShipBasicStats* stats = [ShipBasicStats new];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"StatsViewController+reload" name:NSLocalizedString(@"Updating Stats", nil)];
	__weak EUOperation* weakOperation = operation;
	[operation addExecutionBlock:^(void) {
		@synchronized(self.fittingViewController) {
			eufe::Character* character = self.fittingViewController.fit.character;
			eufe::Ship* ship = character->getShip();
			
			stats.totalPG = ship->getTotalPowerGrid();
			stats.usedPG = ship->getPowerGridUsed();
			
			stats.totalCPU = ship->getTotalCpu();
			stats.usedCPU = ship->getCpuUsed();
			
			stats.totalCalibration = ship->getTotalCalibration();
			stats.usedCalibration = ship->getCalibrationUsed();
			
			weakOperation.progress = 0.25;
			
			stats.maxActiveDrones = ship->getMaxActiveDrones();
			stats.activeDrones = ship->getActiveDrones();
			
			
			stats.totalBandwidth = ship->getTotalDroneBandwidth();
			stats.usedBandwidth = ship->getDroneBandwidthUsed();
			
			stats.totalDB = ship->getTotalDroneBay();
			stats.usedDB = ship->getDroneBayUsed();
			
			stats.usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
			stats.totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
			stats.usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			stats.totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			
			stats.resistances = ship->getResistances();
			
			weakOperation.progress = 0.5;
			
			stats.hp = ship->getHitPoints();
			eufe::HitPoints effectiveHitPoints = ship->getEffectiveHitPoints();
			stats.ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
			
			stats.rtank = ship->getTank();
			stats.stank = ship->getSustainableTank();
			stats.ertank = ship->getEffectiveTank();
			stats.estank = ship->getEffectiveSustainableTank();
			
			stats.capCapacity = ship->getCapCapacity();
			stats.capStable = ship->isCapStable();
			stats.capState = stats.capStable ? ship->getCapStableLevel() * 100.0 : ship->getCapLastsTime();
			stats.capacitorRechargeTime = ship->getAttribute(eufe::RECHARGE_RATE_ATTRIBUTE_ID)->getValue() / 1000.0;
			stats.delta = ship->getCapRecharge() - ship->getCapUsed();
			
			stats.weaponDPS = ship->getWeaponDps();
			stats.droneDPS = ship->getDroneDps();
			stats.volleyDamage = ship->getWeaponVolley() + ship->getDroneVolley();
			stats.dps = stats.weaponDPS + stats.droneDPS;
			
			weakOperation.progress = 0.75;
			
			stats.targets = ship->getMaxTargets();
			stats.targetRange = ship->getMaxTargetRange() / 1000.0;
			stats.scanRes = ship->getScanResolution();
			stats.sensorStr = ship->getScanStrength();
			stats.speed = ship->getVelocity();
			stats.alignTime = ship->getAlignTime();
			stats.signature =ship->getSignatureRadius();
			stats.cargo =ship->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue();
			
			switch(ship->getScanType()) {
				case eufe::Ship::SCAN_TYPE_GRAVIMETRIC:
					stats.sensorImage = [UIImage imageNamed:@"Gravimetric.png"];
					break;
				case eufe::Ship::SCAN_TYPE_LADAR:
					stats.sensorImage = [UIImage imageNamed:@"Ladar.png"];
					break;
				case eufe::Ship::SCAN_TYPE_MAGNETOMETRIC:
					stats.sensorImage = [UIImage imageNamed:@"Magnetometric.png"];
					break;
				case eufe::Ship::SCAN_TYPE_RADAR:
					stats.sensorImage = [UIImage imageNamed:@"Radar.png"];
					break;
				default:
					stats.sensorImage = [UIImage imageNamed:@"Multispectral.png"];
					break;
			}
			
			stats.droneRange = character->getAttribute(eufe::DRONE_CONTROL_DISTANCE_ATTRIBUTE_ID)->getValue() / 1000;
			stats.warpSpeed = ship->getWarpSpeed();
			
			stats.damagePattern = self.fittingViewController.damagePattern;
			weakOperation.progress = 1.0;
			
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.basicStats = stats;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];

			/*self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
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
			self.warpSpeedLabel.text = [NSString stringWithFormat:@"%.2f AU/s", warpSpeed];*/
			
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self updatePrice];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 7;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 2;
		case 1:
			return 6;
		case 2:
			return 1;
		case 3:
			return 3;
		case 4:
			return 1;
		case 5:
			return 1;
		case 6:
			return 1;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GroupedCell* groupedCell = nil;
	
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsWeaponResourcesCell";
			ShipStatsWeaponResourcesCell* cell = (ShipStatsWeaponResourcesCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsWeaponResourcesCell cellWithNibName:@"ShipStatsWeaponResourcesCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				cell.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", self.basicStats.usedTurretHardpoints, self.basicStats.totalTurretHardpoints];
				cell.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", self.basicStats.usedMissileHardpoints, self.basicStats.totalMissileHardpoints];
				
				cell.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) self.basicStats.usedCalibration, (int) self.basicStats.totalCalibration];
				if (self.basicStats.usedCalibration > self.basicStats.totalCalibration)
					cell.calibrationLabel.textColor = [UIColor redColor];
				else
					cell.calibrationLabel.textColor = [UIColor whiteColor];
				
				cell.dronesLabel.text = [NSString stringWithFormat:@"%d/%d", self.basicStats.activeDrones, self.basicStats.maxActiveDrones];
				if (self.basicStats.activeDrones > self.basicStats.maxActiveDrones)
					cell.dronesLabel.textColor = [UIColor redColor];
				else
					cell.dronesLabel.textColor = [UIColor whiteColor];
			}
		}
		else if (indexPath.row == 1) {
			static NSString* cellIdentifier = @"ShipStatsBasicResourcesCell";
			ShipStatsBasicResourcesCell* cell = (ShipStatsBasicResourcesCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsBasicResourcesCell cellWithNibName:@"ShipStatsBasicResourcesCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				cell.powerGridLabel.text = [NSString stringWithTotalResources:self.basicStats.totalPG usedResources:self.basicStats.usedPG unit:@"MW"];
				cell.powerGridLabel.progress = self.basicStats.totalPG > 0 ? self.basicStats.usedPG / self.basicStats.totalPG : 0;
				cell.cpuLabel.text = [NSString stringWithTotalResources:self.basicStats.totalCPU usedResources:self.basicStats.usedCPU unit:@"tf"];
				cell.cpuLabel.progress = self.basicStats.usedCPU > 0 ? self.basicStats.usedCPU / self.basicStats.totalCPU : 0;
				
				cell.droneBandwidthLabel.text = [NSString stringWithTotalResources:self.basicStats.totalBandwidth usedResources:self.basicStats.usedBandwidth unit:@"Mbit/s"];
				cell.droneBandwidthLabel.progress = self.basicStats.totalBandwidth > 0 ? self.basicStats.usedBandwidth / self.basicStats.totalBandwidth : 0;
				cell.droneBayLabel.text = [NSString stringWithTotalResources:self.basicStats.totalDB usedResources:self.basicStats.usedDB unit:@"m3"];
				cell.droneBayLabel.progress = self.basicStats.totalDB > 0 ? self.basicStats.usedDB / self.basicStats.totalDB : 0;
			}
		}
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsResistancesHeaderCell";
			ShipStatsResistancesHeaderCell* cell = (ShipStatsResistancesHeaderCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsResistancesHeaderCell cellWithNibName:@"ShipStatsResistancesHeaderCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
		}
		else if (indexPath.row == 5) {
			static NSString* cellIdentifier = @"EHPCell";
			groupedCell = (ShipStatsResistancesHeaderCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!groupedCell)
				groupedCell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			groupedCell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString stringWithResource:self.basicStats.ehp unit:nil]];
		}
		else {
			static NSString* cellIdentifier = @"ShipStatsResistancesCell";
			ShipStatsResistancesCell* cell = (ShipStatsResistancesCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsResistancesCell cellWithNibName:@"ShipStatsResistancesCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				float values[5];
				NSString* imageName = nil;
				if (indexPath.row == 1) {
					values[0] = self.basicStats.resistances.shield.em;
					values[1] = self.basicStats.resistances.shield.thermal;
					values[2] = self.basicStats.resistances.shield.kinetic;
					values[3] = self.basicStats.resistances.shield.explosive;
					values[4] = self.basicStats.hp.shield;
					imageName = @"shield.png";
				}
				else if (indexPath.row == 2) {
					values[0] = self.basicStats.resistances.armor.em;
					values[1] = self.basicStats.resistances.armor.thermal;
					values[2] = self.basicStats.resistances.armor.kinetic;
					values[3] = self.basicStats.resistances.armor.explosive;
					values[4] = self.basicStats.hp.armor;
					imageName = @"armor.png";
				}
				else if (indexPath.row == 3) {
					values[0] = self.basicStats.resistances.hull.em;
					values[1] = self.basicStats.resistances.hull.thermal;
					values[2] = self.basicStats.resistances.hull.kinetic;
					values[3] = self.basicStats.resistances.hull.explosive;
					values[4] = self.basicStats.hp.hull;
					imageName = @"hull.png";
				}
				else if (indexPath.row == 4) {
					values[0] = self.basicStats.damagePattern.emAmount;
					values[1] = self.basicStats.damagePattern.thermalAmount;
					values[2] = self.basicStats.damagePattern.kineticAmount;
					values[3] = self.basicStats.damagePattern.explosiveAmount;
					values[4] = 0;
					imageName = @"damagePattern.png";
				}
				
				ProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
				for (int i = 0; i < 4; i++) {
					labels[i].progress = values[i];
					labels[i].text = [NSString stringWithFormat:@"%.1f%%", values[i] * 100];
				}
				cell.hpLabel.text = values[4] > 0 ? [NSString stringWithResource:values[4] unit:nil] : nil;
				cell.categoryImageView.image = [UIImage imageNamed:imageName];
			}
		}
	}
	else if (indexPath.section == 2) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsCapacitorCell";
			ShipStatsCapacitorCell* cell = (ShipStatsCapacitorCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsCapacitorCell cellWithNibName:@"ShipStatsCapacitorCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				cell.capacitorCapacityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString stringWithResource:self.basicStats.capCapacity unit:@"GJ"]];
				if (self.basicStats.capStable)
					cell.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), self.basicStats.capState];
				else
					cell.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Lasts %@", nil), [NSString stringWithTimeLeft:self.basicStats.capState]];
				cell.capacitorRechargeTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:self.basicStats.capacitorRechargeTime]];
				cell.capacitorDeltaLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%.2f GJ/s", nil), self.basicStats.delta >= 0.0 ? @"+" : @"", self.basicStats.delta];
			}
		}
	}
	else if (indexPath.section == 3) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsTankHeaderCell";
			ShipStatsTankHeaderCell* cell = (ShipStatsTankHeaderCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsTankHeaderCell cellWithNibName:@"ShipStatsTankHeaderCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
		}
		else {
			static NSString* cellIdentifier = @"ShipStatsTankCell";
			ShipStatsTankCell* cell = (ShipStatsTankCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsTankCell cellWithNibName:@"ShipStatsTankCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				if (indexPath.row == 1) {
					cell.categoryLabel.text = NSLocalizedString(@"Reinforced", nil);
					cell.shieldRecharge.text = nil;
					cell.shieldBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.rtank.shieldRepair, self.basicStats.ertank.shieldRepair];
					cell.armorRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.rtank.armorRepair, self.basicStats.ertank.armorRepair];
					cell.hullRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.rtank.hullRepair, self.basicStats.ertank.hullRepair];
				}
				else {
					cell.categoryLabel.text = NSLocalizedString(@"Sustained", nil);
					cell.shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.stank.passiveShield, self.basicStats.estank.passiveShield];
					cell.shieldBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.stank.shieldRepair, self.basicStats.estank.shieldRepair];
					cell.armorRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.stank.armorRepair, self.basicStats.estank.armorRepair];
					cell.hullRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.stank.hullRepair, self.basicStats.estank.hullRepair];
				}
			}
		}
	}
	else if (indexPath.section == 4) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsFirepowerCell";
			ShipStatsFirepowerCell* cell = (ShipStatsFirepowerCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsFirepowerCell cellWithNibName:@"ShipStatsFirepowerCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				cell.weaponDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil), self.basicStats.weaponDPS];
				cell.droneDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%.0f DPS", nil), self.basicStats.droneDPS];
				cell.volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f", self.basicStats.volleyDamage];
				cell.dpsLabel.text = [NSString stringWithFormat:@"%.0f", self.basicStats.dps];
			}
		}
	}
	else if (indexPath.section == 5) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsMiscCell";
			ShipStatsMiscCell* cell = (ShipStatsMiscCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsMiscCell cellWithNibName:@"ShipStatsMiscCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.basicStats) {
				cell.targetsLabel.text = [NSString stringWithFormat:@"%d", self.basicStats.targets];
				cell.targetRangeLabel.text = [NSString stringWithFormat:@"%.1f km", self.basicStats.targetRange];
				cell.scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", self.basicStats.scanRes];
				cell.sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", self.basicStats.sensorStr];
				cell.speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", self.basicStats.speed];
				cell.alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", self.basicStats.alignTime];
				cell.signatureLabel.text = [NSString stringWithFormat:@"%.0f", self.basicStats.signature];
				cell.cargoLabel.text = [NSString stringWithResource:self.basicStats.cargo unit:@"m3"];
				cell.sensorImageView.image = self.basicStats.sensorImage;
				cell.droneRangeLabel.text = [NSString stringWithFormat:@"%.1f km", self.basicStats.droneRange];
				cell.warpSpeedLabel.text = [NSString stringWithFormat:@"%.2f AU/s", self.basicStats.warpSpeed];
			}
		}
	}
	else if (indexPath.section == 6) {
		if (indexPath.row == 0) {
			static NSString* cellIdentifier = @"ShipStatsPriceCell";
			ShipStatsPriceCell* cell = (ShipStatsPriceCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [ShipStatsPriceCell cellWithNibName:@"ShipStatsPriceCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			
			if (self.priceStats) {
				cell.shipPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:self.priceStats.shipPrice unit:nil]];
				cell.fittingsPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:self.priceStats.fittingsPrice unit:nil]];
				cell.totalPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:self.priceStats.totalPrice unit:nil]];
			}
		}
	}
	
	groupedCell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	int groupStyle = 0;
	if (indexPath.row == 0)
		groupStyle |= GroupedCellGroupStyleTop;
	if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1)
		groupStyle |= GroupedCellGroupStyleBottom;
	groupedCell.groupStyle = static_cast<GroupedCellGroupStyle>(groupStyle);
	return groupedCell;
	
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0)
		return NSLocalizedString(@"Resources", nil);
	else if (section == 1)
		return NSLocalizedString(@"Resistances", nil);
	else if (section == 2)
		return NSLocalizedString(@"Capacitor", nil);
	else if (section == 3)
		return NSLocalizedString(@"Recharge Rates (HP/s) / (EHP/s )", nil);
	else if (section == 4)
		return NSLocalizedString(@"Firepower", nil);
	else if (section == 5)
		return NSLocalizedString(@"Misc", nil);
	else if (section == 6)
		return NSLocalizedString(@"Price", nil);
	else
		return nil;
}

#pragma mark -
#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		CollapsableTableHeaderView* view = [CollapsableTableHeaderView viewWithNibName:@"CollapsableTableHeaderView" bundle:nil];
		view.titleLabel.text = title;
		view.collapsImageView.hidden = YES;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self tableView:tableView titleForHeaderInSection:section] ? 22 : 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0)
			return 40;
		else
			return 65;
	}
	else if (indexPath.section == 1)
		return 40;
	else if (indexPath.section == 2)
		return 40;
	else if (indexPath.section == 3)
		return 40;
	else if (indexPath.section == 4)
		return 50;
	else if (indexPath.section == 5)
		return 140;
	else
		return 40;
}

#pragma mark - Private

- (void) updatePrice {
	ShipPriceStats* stats = [ShipPriceStats new];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"ShipStatsDataSource+UpdatePrice" name:NSLocalizedString(@"Updating Price", nil)];
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
		stats.shipPrice = [self.fittingViewController.priceManager priceWithType:shipInfo];
		CGFloat fittingsPrice = 0;
		for (ItemInfo* itemInfo in types) {
			if (itemInfo != shipInfo) {
				int count = [types countForObject:itemInfo];
				fittingsPrice += [prices[@(itemInfo.typeID)] floatValue] * count;
			}
		}
		stats.fittingsPrice = fittingsPrice;
		stats.totalPrice = stats.shipPrice + stats.fittingsPrice;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.priceStats = stats;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
			/*self.shipPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:shipPrice unit:nil]];
			self.fittingsPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:fittingsPrice unit:nil]];
			self.totalPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString stringWithResource:totalPrice unit:nil]];*/
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


@end
