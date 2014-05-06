//
//  NCFittingPOSStatsDataSource.m
//  Neocom
//
//  Created by Shimanski Artem on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSStatsDataSource.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NCFittingPOSResourcesCell.h"
#import "NCFittingPOSDefenseOffenseCell.h"
#import "NCFittingResistancesCell.h"
#import "NCFittingEHPCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingPOSStructuresTableHeaderView.h"
#import "NCPriceManager.h"
#import "NCTableViewHeaderView.h"


@interface NCFittingPOSStatsDataSourcePOSStats : NSObject
@property (nonatomic, assign) float totalPG;
@property (nonatomic, assign) float usedPG;
@property (nonatomic, assign) float totalCPU;
@property (nonatomic, assign) float usedCPU;
@property (nonatomic, assign) eufe::Resistances resistances;
@property (nonatomic, assign) eufe::HitPoints hp;
@property (nonatomic, assign) float ehp;
@property (nonatomic, assign) eufe::Tank rtank;
@property (nonatomic, assign) eufe::Tank ertank;

@property (nonatomic, assign) float weaponDPS;
@property (nonatomic, assign) float volleyDamage;
@property (nonatomic, strong) NCDamagePattern* damagePattern;
@end

@interface NCFittingPOSStatsDataSourcePriceStats : NSObject
@property (nonatomic, assign) int fuelConsumtion;
@property (nonatomic, assign) float fuelDailyCost;
@property (nonatomic, assign) float upgradesCost;
@property (nonatomic, assign) float upgradesDailyCost;
@property (nonatomic, assign) float posCost;
@end

@implementation NCFittingPOSStatsDataSourcePOSStats
@end

@implementation NCFittingPOSStatsDataSourcePriceStats
@end


@interface NCFittingPOSStatsDataSource()
@property (nonatomic, strong) NCFittingPOSStatsDataSourcePOSStats* posStats;
@property (nonatomic, strong) NCFittingPOSStatsDataSourcePriceStats* priceStats;
@property (nonatomic, strong) NCPriceManager* priceManager;
@property (nonatomic, strong) EVEDBInvControlTowerResource* posFuelRequirements;
@end


@implementation NCFittingPOSStatsDataSource

- (id) init {
	if (self = [super init]) {
		self.priceManager = [NCPriceManager new];
	}
	return self;
}

- (void) reload {
	NCFittingPOSStatsDataSourcePOSStats* stats = [NCFittingPOSStatsDataSourcePOSStats new];
	
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
															
															stats.totalPG = controlTower->getTotalPowerGrid();
															stats.usedPG = controlTower->getPowerGridUsed();
															
															stats.totalCPU = controlTower->getTotalCpu();
															stats.usedCPU = controlTower->getCpuUsed();
															
															stats.resistances = controlTower->getResistances();
															
															stats.hp = controlTower->getHitPoints();
															eufe::HitPoints effectiveHitPoints = controlTower->getEffectiveHitPoints();
															stats.ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
															
															stats.rtank = controlTower->getTank();
															stats.ertank = controlTower->getEffectiveTank();
															
															stats.weaponDPS = controlTower->getWeaponDps();
															stats.volleyDamage = controlTower->getWeaponVolley();
															
															stats.damagePattern = self.controller.damagePattern;
														}
													}
										completionHandler:^(NCTask *task) {
											if (![task isCancelled]) {
												self.posStats = stats;
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
    return 4;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 1;
		case 1:
			return 6;
		case 2:
			return 1;
		case 3:
			return 3;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		
		NCFittingPOSResourcesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingPOSResourcesCell"];
		
		if (self.posStats) {
			cell.powerGridLabel.text = [NSString stringWithTotalResources:self.posStats.totalPG usedResources:self.posStats.usedPG unit:@"MW"];
			cell.powerGridLabel.progress = self.posStats.totalPG > 0 ? self.posStats.usedPG / self.posStats.totalPG : 0;
			cell.cpuLabel.text = [NSString stringWithTotalResources:self.posStats.totalCPU usedResources:self.posStats.usedCPU unit:@"tf"];
			cell.cpuLabel.progress = self.posStats.usedCPU > 0 ? self.posStats.usedCPU / self.posStats.totalCPU : 0;
		}
		return cell;
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0) {
			UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingResistancesHeaderCell"];
			return cell;
		}
		else if (indexPath.row == 5) {
			NCFittingEHPCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingEHPCell"];
			cell.ehpLabel.text = [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString shortStringWithFloat:self.posStats.ehp unit:nil]];
			return cell;
		}
		else {
			NCFittingResistancesCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingResistancesCell"];
			if (self.posStats) {
				float values[5] = {0};
				NSString* imageName = nil;
				if (indexPath.row == 1) {
					values[0] = self.posStats.resistances.shield.em;
					values[1] = self.posStats.resistances.shield.thermal;
					values[2] = self.posStats.resistances.shield.kinetic;
					values[3] = self.posStats.resistances.shield.explosive;
					values[4] = self.posStats.hp.shield;
					imageName = @"shield.png";
				}
				else if (indexPath.row == 2) {
					values[0] = self.posStats.resistances.armor.em;
					values[1] = self.posStats.resistances.armor.thermal;
					values[2] = self.posStats.resistances.armor.kinetic;
					values[3] = self.posStats.resistances.armor.explosive;
					values[4] = self.posStats.hp.armor;
					imageName = @"armor.png";
				}
				else if (indexPath.row == 3) {
					values[0] = self.posStats.resistances.hull.em;
					values[1] = self.posStats.resistances.hull.thermal;
					values[2] = self.posStats.resistances.hull.kinetic;
					values[3] = self.posStats.resistances.hull.explosive;
					values[4] = self.posStats.hp.hull;
					imageName = @"hull.png";
				}
				else if (indexPath.row == 4) {
					if (self.posStats.damagePattern) {
						values[0] = self.posStats.damagePattern.em;
						values[1] = self.posStats.damagePattern.thermal;
						values[2] = self.posStats.damagePattern.kinetic;
						values[3] = self.posStats.damagePattern.explosive;
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
		NCFittingPOSDefenseOffenseCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NCFittingPOSDefenseOffenseCell"];
		if (self.posStats) {
			cell.shieldRecharge.text = [NSString stringWithFormat:@"%.1f", self.posStats.rtank.passiveShield];
			cell.effectiveShieldRecharge.text = [NSString stringWithFormat:@"%.1f", self.posStats.ertank.passiveShield];
			cell.weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f", self.posStats.weaponDPS];
			cell.weaponVolleyLabel.text = [NSString stringWithFormat:@"%.0f", self.posStats.volleyDamage];
		}
		return cell;
	}
	else if (indexPath.section == 3) {
		NCTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
		cell.accessoryView = nil;
		
		if (indexPath.row == 0) {
			if (self.priceStats) {
				cell.iconView.image = [UIImage imageNamed:self.posFuelRequirements.resourceType.typeSmallImageName];
				cell.titleLabel.text = self.posFuelRequirements.resourceType.typeName;
				cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
													self.priceStats.fuelConsumtion,
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.fuelDailyCost)]];
			}
			
		}
		else if (indexPath.row == 1) {
			if (self.priceStats) {
				cell.iconView.image = [UIImage imageNamed:@"Icons/icon95_02.png"];
				cell.titleLabel.text = NSLocalizedString(@"Infrastructure Upgrades Cost", nil);
				cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.upgradesCost)],
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.upgradesDailyCost)]];
			}
			
		}
		else if (indexPath.row == 2) {
			if (self.priceStats) {
				cell.iconView.image = [UIImage imageNamed:@"Icons/icon07_12.png"];
				cell.titleLabel.text = NSLocalizedString(@"POS Cost", nil);
				cell.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.posCost)]];
			}
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
		return NSLocalizedString(@"Defense/Offense", nil);
	else if (section == 3)
		return NSLocalizedString(@"Cost", nil);
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
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	return title ? 44 : 0;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 41;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSMutableDictionary* heights = nil;
	if (!heights)
		heights = [NSMutableDictionary new];
	NSNumber* height = heights[indexPath];
	if (height)
		return [height floatValue];
	
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	cell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
	[cell layoutIfNeeded];
	
	height = @([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.5);
	heights[indexPath] = height;
	return [height floatValue];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 4)
		[self.controller performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Private

- (void) updatePrice {
	NCFittingPOSStatsDataSourcePriceStats* stats = [NCFittingPOSStatsDataSourcePriceStats new];
	
	
	[[self.controller taskManager] addTaskWithIndentifier:NCTaskManagerIdentifierAuto
													title:NCTaskManagerDefaultTitle
													block:^(NCTask *task) {
														@synchronized(self.controller) {
															NSMutableSet* types = [NSMutableSet set];
															NSMutableDictionary* infrastructureUpgrades = [NSMutableDictionary dictionary];
															eufe::ControlTower* controlTower = self.controller.engine->getControlTower();
															EVEDBInvControlTowerResource* resource = self.posFuelRequirements;
															stats.fuelConsumtion = resource.quantity;
															
															[types addObject:@(controlTower->getTypeID())];
															[types addObject:@(resource.resourceTypeID)];
															
															float upgradesDailyCost = 0;
															for (auto i: controlTower->getStructures()) {
																[types addObject:@(i->getTypeID())];
																if (i->hasAttribute(1595)) { //anchoringRequiresSovUpgrade1
																	int32_t typeID = (int32_t) i->getAttribute(1595)->getValue();
																	EVEDBInvType* upgrade = infrastructureUpgrades[@(typeID)];
																	if (!upgrade) {
																		upgrade = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
																		if (upgrade) {
																			[types addObject:@(typeID)];
																			infrastructureUpgrades[@(typeID)] = upgrade;
																			[types addObject:@(typeID)];
																			EVEDBDgmTypeAttribute* attribute = upgrade.attributesDictionary[@(1603)];//sovBillSystemCost
																			upgradesDailyCost += attribute.value;
																		}
																	}
																}
															}
															
															NSDictionary* prices = [self.priceManager pricesWithTypes:[types allObjects]];
															
															__block float upgradesCost = 0;
															__block float posCost = 0;
															[prices enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, EVECentralMarketStatType* obj, BOOL *stop) {
																NSInteger typeID = [key integerValue];
																if (typeID == resource.resourceTypeID)
																	stats.fuelDailyCost = stats.fuelConsumtion * obj.sell.percentile * 24;
																else if (infrastructureUpgrades[key] != nil)
																	upgradesCost += obj.sell.percentile;
																else
																	posCost += obj.sell.percentile;
															}];
															
															stats.posCost = posCost;
															stats.upgradesCost = upgradesCost;
															stats.upgradesDailyCost = upgradesDailyCost;
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

- (EVEDBInvControlTowerResource*) posFuelRequirements {
	if (!_posFuelRequirements) {
		for (EVEDBInvControlTowerResource* resource in self.controller.fit.type.resources) {
			if (resource.minSecurityLevel == 0.0 && resource.purposeID == 1) {
				_posFuelRequirements = resource;
				break;
			}
		}
	}
	return _posFuelRequirements;
}

@end
