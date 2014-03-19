//
//  NCFittingShipStatsDataSource.m
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipStatsDataSource.h"
#import "NCFittingShipViewController.h"
#import "NCFittingShipWeaponsCell.h"
#import "NCFittingShipResourcesCell.h"
#import "NCFittingResistancesCell.h"
#import "NCFittingEHPCell.h"
#import "NCFittingShipCapacitorCell.h"
#import "NCFittingShipFirepowerCell.h"
#import "NCFittingShipTankCell.h"
#import "NCFittingShipMiscCell.h"
#import "NCFittingShipPriceCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCPriceManager.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingShipStatsDataSourceShipStats : NSObject
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
@property (nonatomic, strong) NCDamagePattern* damagePattern;
@property (nonatomic, assign) float droneRange;
@property (nonatomic, assign) float warpSpeed;

@end

@interface NCFittingShipStatsDataSourcePriceStats : NSObject
@property (nonatomic, assign) float shipPrice;
@property (nonatomic, assign) float fittingsPrice;
@property (nonatomic, assign) float totalPrice;
@end

@implementation NCFittingShipStatsDataSourceShipStats
@end

@implementation NCFittingShipStatsDataSourcePriceStats
@end


@interface NCFittingShipStatsDataSource()
@property (nonatomic, strong) NCFittingShipStatsDataSourceShipStats* shipStats;
@property (nonatomic, strong) NCFittingShipStatsDataSourcePriceStats* priceStats;
@property (nonatomic, strong) NCPriceManager* priceManager;
@end


@implementation NCFittingShipStatsDataSource

- (id) init {
	if (self = [super init]) {
		self.priceManager = [NCPriceManager new];
	}
	return self;
}

- (void) reload {
	NCFittingShipStatsDataSourceShipStats* stats = [NCFittingShipStatsDataSourceShipStats new];
	if (self.tableView.dataSource == self)
		[self.tableView reloadData];

	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															eufe::Character* character = self.controller.fit.pilot;
															if (!character)
																return;
															eufe::Ship* ship = character->getShip();
															
															stats.totalPG = ship->getTotalPowerGrid();
															stats.usedPG = ship->getPowerGridUsed();
															
															stats.totalCPU = ship->getTotalCpu();
															stats.usedCPU = ship->getCpuUsed();
															
															stats.totalCalibration = ship->getTotalCalibration();
															stats.usedCalibration = ship->getCalibrationUsed();
															
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
															
															stats.damagePattern = self.controller.damagePattern;
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.shipStats = stats;
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
											}
										}];
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
	}
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		if (indexPath.row == 0) {
			NCFittingShipWeaponsCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipWeaponsCell"];
			
			if (self.shipStats) {
				cell.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", self.shipStats.usedTurretHardpoints, self.shipStats.totalTurretHardpoints];
				cell.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", self.shipStats.usedMissileHardpoints, self.shipStats.totalMissileHardpoints];
				
				cell.calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) self.shipStats.usedCalibration, (int) self.shipStats.totalCalibration];
				if (self.shipStats.usedCalibration > self.shipStats.totalCalibration)
					cell.calibrationLabel.textColor = [UIColor redColor];
				else
					cell.calibrationLabel.textColor = [UIColor whiteColor];
				
				cell.dronesLabel.text = [NSString stringWithFormat:@"%d/%d", self.shipStats.activeDrones, self.shipStats.maxActiveDrones];
				if (self.shipStats.activeDrones > self.shipStats.maxActiveDrones)
					cell.dronesLabel.textColor = [UIColor redColor];
				else
					cell.dronesLabel.textColor = [UIColor whiteColor];
			}
			return cell;
		}
		else {
			NCFittingShipResourcesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipResourcesCell"];
			
			if (self.shipStats) {
				cell.powerGridLabel.text = [NSString stringWithTotalResources:self.shipStats.totalPG usedResources:self.shipStats.usedPG unit:@"MW"];
				cell.powerGridLabel.progress = self.shipStats.totalPG > 0 ? self.shipStats.usedPG / self.shipStats.totalPG : 0;
				cell.cpuLabel.text = [NSString stringWithTotalResources:self.shipStats.totalCPU usedResources:self.shipStats.usedCPU unit:@"tf"];
				cell.cpuLabel.progress = self.shipStats.usedCPU > 0 ? self.shipStats.usedCPU / self.shipStats.totalCPU : 0;
				
				cell.droneBandwidthLabel.text = [NSString stringWithTotalResources:self.shipStats.totalBandwidth usedResources:self.shipStats.usedBandwidth unit:@"Mbit/s"];
				cell.droneBandwidthLabel.progress = self.shipStats.totalBandwidth > 0 ? self.shipStats.usedBandwidth / self.shipStats.totalBandwidth : 0;
				cell.droneBayLabel.text = [NSString stringWithTotalResources:self.shipStats.totalDB usedResources:self.shipStats.usedDB unit:@"m3"];
				cell.droneBayLabel.progress = self.shipStats.totalDB > 0 ? self.shipStats.usedDB / self.shipStats.totalDB : 0;
			}
			return cell;
		}
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingResistancesHeaderCell"];
			return cell;
		}
		else if (indexPath.row == 5) {
			NCFittingEHPCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingEHPCell"];
			cell.ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString shortStringWithFloat:self.shipStats.ehp unit:nil]];
			return cell;
		}
		else {
			NCFittingResistancesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingResistancesCell"];
			if (self.shipStats) {
				float values[5] = {0};
				NSString* imageName = nil;
				if (indexPath.row == 1) {
					values[0] = self.shipStats.resistances.shield.em;
					values[1] = self.shipStats.resistances.shield.thermal;
					values[2] = self.shipStats.resistances.shield.kinetic;
					values[3] = self.shipStats.resistances.shield.explosive;
					values[4] = self.shipStats.hp.shield;
					imageName = @"shield.png";
				}
				else if (indexPath.row == 2) {
					values[0] = self.shipStats.resistances.armor.em;
					values[1] = self.shipStats.resistances.armor.thermal;
					values[2] = self.shipStats.resistances.armor.kinetic;
					values[3] = self.shipStats.resistances.armor.explosive;
					values[4] = self.shipStats.hp.armor;
					imageName = @"armor.png";
				}
				else if (indexPath.row == 3) {
					values[0] = self.shipStats.resistances.hull.em;
					values[1] = self.shipStats.resistances.hull.thermal;
					values[2] = self.shipStats.resistances.hull.kinetic;
					values[3] = self.shipStats.resistances.hull.explosive;
					values[4] = self.shipStats.hp.hull;
					imageName = @"hull.png";
				}
				else if (indexPath.row == 4) {
					if (self.shipStats.damagePattern) {
						values[0] = self.shipStats.damagePattern.em;
						values[1] = self.shipStats.damagePattern.thermal;
						values[2] = self.shipStats.damagePattern.kinetic;
						values[3] = self.shipStats.damagePattern.explosive;
					}
					else {
						values[0] = 0.25;
						values[1] = 0.25;
						values[2] = 0.25;
						values[3] = 0.25;
					}
					values[4] = 0;
					imageName = @"damagePattern.png";
				}
				
				NCProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
				for (int i = 0; i < 4; i++) {
					labels[i].progress = values[i];
					labels[i].text = [NSString stringWithFormat:@"%.1f%%", values[i] * 100];
				}
				cell.hpLabel.text = values[4] > 0 ? [NSString shortStringWithFloat:values[4] unit:nil] : nil;
				cell.categoryImageView.image = [UIImage imageNamed:imageName];
			}
			return cell;
		}
	}
	else if (indexPath.section == 2) {
		NCFittingShipCapacitorCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipCapacitorCell"];
		if (self.shipStats) {
			cell.capacitorCapacityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString shortStringWithFloat:self.shipStats.capCapacity unit:@"GJ"]];
			if (self.shipStats.capStable)
				cell.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), self.shipStats.capState];
			else
				cell.capacitorStateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Lasts: %@", nil), [NSString stringWithTimeLeft:self.shipStats.capState]];
			cell.capacitorRechargeTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:self.shipStats.capacitorRechargeTime]];
			cell.capacitorDeltaLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%@", nil), self.shipStats.delta >= 0.0 ? @"+" : @"", [NSString shortStringWithFloat:self.shipStats.delta unit:@"GJ/s"]];
		}
		return cell;
	}
	else if (indexPath.section == 3) {
		if (indexPath.row == 0) {
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipTankHeaderCell"];
			return cell;
		}
		else {
			NCFittingShipTankCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipTankCell"];
			
			if (self.shipStats) {
				if (indexPath.row == 1) {
					cell.categoryLabel.text = NSLocalizedString(@"Reinforced", nil);
					cell.shieldRecharge.text = nil;
					cell.shieldBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.rtank.shieldRepair, self.shipStats.ertank.shieldRepair];
					cell.armorRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.rtank.armorRepair, self.shipStats.ertank.armorRepair];
					cell.hullRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.rtank.hullRepair, self.shipStats.ertank.hullRepair];
				}
				else {
					cell.categoryLabel.text = NSLocalizedString(@"Sustained", nil);
					cell.shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.stank.passiveShield, self.shipStats.estank.passiveShield];
					cell.shieldBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.stank.shieldRepair, self.shipStats.estank.shieldRepair];
					cell.armorRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.stank.armorRepair, self.shipStats.estank.armorRepair];
					cell.hullRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.shipStats.stank.hullRepair, self.shipStats.estank.hullRepair];
				}
			}
			return cell;
		}
	}
	else if (indexPath.section == 4) {
		NCFittingShipFirepowerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipFirepowerCell"];
		
		if (self.shipStats) {
			cell.weaponDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.shipStats.weaponDPS)]];
			cell.droneDPSLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.shipStats.droneDPS)]];
			cell.volleyDamageLabel.text = [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.shipStats.volleyDamage)];
			cell.dpsLabel.text = [NSString stringWithFormat:@"%@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(self.shipStats.dps)]];
		}
		return cell;
	}
	else if (indexPath.section == 5) {
		NCFittingShipMiscCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipMiscCell"];
		if (self.shipStats) {
			cell.targetsLabel.text = [NSString stringWithFormat:@"%d", self.shipStats.targets];
			cell.targetRangeLabel.text = [NSString stringWithFormat:@"%.1f km", self.shipStats.targetRange];
			cell.scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", self.shipStats.scanRes];
			cell.sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", self.shipStats.sensorStr];
			cell.speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", self.shipStats.speed];
			cell.alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", self.shipStats.alignTime];
			cell.signatureLabel.text = [NSString stringWithFormat:@"%.0f", self.shipStats.signature];
			cell.cargoLabel.text = [NSString shortStringWithFloat:self.shipStats.cargo unit:@"m3"];
			cell.sensorImageView.image = self.shipStats.sensorImage;
			cell.droneRangeLabel.text = [NSString stringWithFormat:@"%.1f km", self.shipStats.droneRange];
			cell.warpSpeedLabel.text = [NSString stringWithFormat:@"%.2f AU/s", self.shipStats.warpSpeed];
		}
		return cell;
	}
	else if (indexPath.section == 6) {
		NCFittingShipPriceCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingShipPriceCell"];
		if (self.priceStats) {
			cell.shipPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:self.priceStats.shipPrice unit:nil]];
			cell.fittingsPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:self.priceStats.fittingsPrice unit:nil]];
			cell.totalPriceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:self.priceStats.totalPrice unit:nil]];
		}
		return cell;
	}
	else
		return nil;
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

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		view.textLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell setNeedsLayout];
	[cell layoutIfNeeded];
	return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 4)
		[self.controller performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
}


#pragma mark - Private

- (void) updatePrice {
	NCFittingShipStatsDataSourcePriceStats* stats = [NCFittingShipStatsDataSourcePriceStats new];
	
	
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															NSCountedSet* types = [NSCountedSet set];

															eufe::Character* character = self.controller.fit.pilot;
															eufe::Ship* ship = character->getShip();
															
															[types addObject:@(ship->getTypeID())];
															
															for (auto i: ship->getModules())
																[types addObject:@(i->getTypeID())];
															
															for (auto i: ship->getDrones())
																[types addObject:@(i->getTypeID())];
															
															NSDictionary* prices = [self.priceManager pricesWithTypes:[types allObjects]];
															__block float shipPrice = 0;
															__block float fittingsPrice = 0;
															
															[prices enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, EVECentralMarketStatType* obj, BOOL *stop) {
																NSInteger typeID = [key integerValue];
																if (typeID == ship->getTypeID())
																	shipPrice = obj.sell.percentile;
																else
																	fittingsPrice += obj.sell.percentile * [types countForObject:key];
															}];
															
															stats.shipPrice = shipPrice;
															stats.fittingsPrice = fittingsPrice;
															stats.totalPrice = stats.shipPrice + stats.fittingsPrice;
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.priceStats = stats;
												if (self.tableView.dataSource == self)
													[self.tableView reloadData];
											}
										}];
}


@end
