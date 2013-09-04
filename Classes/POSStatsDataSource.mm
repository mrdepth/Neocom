//
//  POSStatsDataSource.m
//  EVEUniverse
//
//  Created by mr_depth on 16.08.13.
//
//

#import "POSStatsDataSource.h"
#import "POSFittingViewController.h"
#import "EUOperationQueue.h"
#import "eufe.h"
#import "NSString+Fitting.h"
#import "ItemInfo.h"
#import "POSFit.h"
#import "PriceManager.h"

#import "POSStatsBasicResourcesCell.h"
#import "POSDefenseOffenseHeaderCell.h"
#import "POSDefenseOffenseCell.h"
#import "ShipStatsResistancesHeaderCell.h"
#import "ShipStatsResistancesCell.h"
#import "UITableViewCell+Nib.h"
#import "NSNumberFormatter+Neocom.h"
#import "CollapsableTableHeaderView.h"
#import "UIView+Nib.h"

@interface POSBasicStats : NSObject
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
@property (nonatomic, strong) DamagePattern* damagePattern;

@end

@interface POSPriceStats : NSObject
@property (nonatomic, assign) int fuelConsumtion;
@property (nonatomic, assign) float fuelDailyCost;
@property (nonatomic, assign) float upgradesCost;
@property (nonatomic, assign) float upgradesDailyCost;
@property (nonatomic, assign) float posCost;
@end

@implementation POSBasicStats
@end

@implementation POSPriceStats
@end


@interface POSStatsDataSource()
@property (nonatomic, strong) POSBasicStats* basicStats;
@property (nonatomic, strong) POSPriceStats* priceStats;
@end


@implementation POSStatsDataSource

- (void) reload {
	POSBasicStats* basicStats = [POSBasicStats new];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsDataSource+reload" name:NSLocalizedString(@"Updating Stats", nil)];
	__weak EUOperation* weakOperation = operation;
	POSFittingViewController* aPosFittingViewController = self.posFittingViewController;
	
	[operation addExecutionBlock:^(void) {
		@synchronized(self.posFittingViewController) {
			
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			
			basicStats.totalPG = controlTower->getTotalPowerGrid();
			basicStats.usedPG = controlTower->getPowerGridUsed();
			
			basicStats.totalCPU = controlTower->getTotalCpu();
			basicStats.usedCPU = controlTower->getCpuUsed();
			
			basicStats.resistances = controlTower->getResistances();
			
			basicStats.hp = controlTower->getHitPoints();
			eufe::HitPoints effectiveHitPoints = controlTower->getEffectiveHitPoints();
			basicStats.ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
			
			basicStats.rtank = controlTower->getTank();
			basicStats.ertank = controlTower->getEffectiveTank();
			
			basicStats.weaponDPS = controlTower->getWeaponDps();
			basicStats.volleyDamage = controlTower->getWeaponVolley();
			
			basicStats.damagePattern = self.posFittingViewController.damagePattern;
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			/*self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			self.powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			self.cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			self.cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			
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
			
			self.shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.passiveShield, ertank.passiveShield];
			
			self.weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f\n%.0f",weaponDPS, volleyDamage];*/
			self.basicStats = basicStats;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
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
			return 2;
		case 3:
			return 3;
	}
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	GroupedCell* groupedCell = nil;
	
	if (indexPath.section == 0) {
		static NSString* cellIdentifier = @"POSStatsBasicResourcesCell";
		POSStatsBasicResourcesCell* cell = (POSStatsBasicResourcesCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell)
			cell = [POSStatsBasicResourcesCell cellWithNibName:@"POSStatsBasicResourcesCell" bundle:nil reuseIdentifier:cellIdentifier];
		groupedCell = cell;
		
		if (self.basicStats) {
			cell.powerGridLabel.text = [NSString stringWithTotalResources:self.basicStats.totalPG usedResources:self.basicStats.usedPG unit:@"MW"];
			cell.powerGridLabel.progress = self.basicStats.totalPG > 0 ? self.basicStats.usedPG / self.basicStats.totalPG : 0;
			cell.cpuLabel.text = [NSString stringWithTotalResources:self.basicStats.totalCPU usedResources:self.basicStats.usedCPU unit:@"tf"];
			cell.cpuLabel.progress = self.basicStats.usedCPU > 0 ? self.basicStats.usedCPU / self.basicStats.totalCPU : 0;
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
			groupedCell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
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
				float values[5] = {0};
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
			static NSString* cellIdentifier = @"POSDefenseOffenseHeaderCell";
			POSDefenseOffenseHeaderCell* cell = (POSDefenseOffenseHeaderCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [POSDefenseOffenseHeaderCell cellWithNibName:@"POSDefenseOffenseHeaderCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
		}
		else if (indexPath.row == 1) {
			static NSString* cellIdentifier = @"POSDefenseOffenseCell";
			POSDefenseOffenseCell* cell = (POSDefenseOffenseCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			if (!cell)
				cell = [POSDefenseOffenseCell cellWithNibName:@"POSDefenseOffenseCell" bundle:nil reuseIdentifier:cellIdentifier];
			groupedCell = cell;
			if (self.basicStats) {
				cell.shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", self.basicStats.rtank.passiveShield, self.basicStats.ertank.passiveShield];
				cell.weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f\n%.0f", self.basicStats.weaponDPS, self.basicStats.volleyDamage];
			}
		}
	}
	else if (indexPath.section == 3) {
		static NSString* cellIdentifier = @"Cell";
		groupedCell = (GroupedCell*) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!groupedCell)
			groupedCell = [[GroupedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];

		if (indexPath.row == 0) {
			if (self.priceStats) {
				groupedCell.imageView.image = [UIImage imageNamed:self.posFittingViewController.posFuelRequirements.resourceType.typeSmallImageName];
				groupedCell.textLabel.text = self.posFittingViewController.posFuelRequirements.resourceType.typeName;
				groupedCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
													self.priceStats.fuelConsumtion,
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.fuelDailyCost)]];
			}

		}
		else if (indexPath.row == 1) {
			if (self.priceStats) {
				groupedCell.imageView.image = [UIImage imageNamed:@"Icons/icon95_02.png"];
				groupedCell.textLabel.text = NSLocalizedString(@"Infrastructure Upgrades Cost", nil);
				groupedCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.upgradesCost)],
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.upgradesDailyCost)]];
			}
			
		}
		else if (indexPath.row == 2) {
			if (self.priceStats) {
				groupedCell.imageView.image = [UIImage imageNamed:@"Icons/icon07_12.png"];
				groupedCell.textLabel.text = NSLocalizedString(@"POS Cost", nil);
				groupedCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
													[NSNumberFormatter neocomLocalizedStringFromNumber:@(self.priceStats.posCost)]];
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
		return NSLocalizedString(@"Defense/Offense", nil);
	else if (section == 3)
		return NSLocalizedString(@"Cost", nil);
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
		return 34;
	}
	else if (indexPath.section == 1) {
		if (indexPath.row == 0 || indexPath.row == 5)
			return 30;
		else
			return 34;
	}
	else if (indexPath.section == 2) {
		if (indexPath.row == 0)
			return 30;
		else
			return 34;
	}
	else if (indexPath.section == 4)
		return 30;
	else
		return 40;
}


#pragma mark - Private

- (void) updatePrice {
	POSPriceStats* priceStats = [POSPriceStats new];
	
	EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsDataSource+updatePrice" name:NSLocalizedString(@"Updating Price", nil)];
	__weak EUOperation* weakOperation = operation;
	
	[operation addExecutionBlock:^(void) {
		NSMutableSet* types = [NSMutableSet set];
		NSMutableDictionary* infrastructureUpgrades = [NSMutableDictionary dictionary];
		
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
			priceStats.fuelConsumtion = self.posFittingViewController.posFuelRequirements.quantity;
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			
			[types addObject:self.posFittingViewController.fit];
			
			priceStats.upgradesDailyCost = 0;
			for (i = structuresList.begin(); i != end; i++) {
				ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:*i error:nil];
				if (itemInfo)
					[types addObject:itemInfo];
				
				if ((*i)->hasAttribute(1595)) { //anchoringRequiresSovUpgrade1
					NSInteger typeID = (NSInteger) (*i)->getAttribute(1595)->getValue();
					//NSString* key = [NSString stringWithFormat:@"%d", typeID];
					EVEDBInvType* upgrade = infrastructureUpgrades[@(typeID)];
					if (!upgrade) {
						upgrade = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
						if (upgrade) {
							[types addObject:upgrade];
							infrastructureUpgrades[@(typeID)] = upgrade;
							EVEDBDgmTypeAttribute* attribute = upgrade.attributesDictionary[@(1603)];//sovBillSystemCost
							priceStats.upgradesDailyCost += attribute.value;
						}
					}
				}
			}
		}
		[types addObject:self.posFittingViewController.posFuelRequirements.resourceType];
		
		NSDictionary* prices = [self.posFittingViewController.priceManager pricesWithTypes:[types allObjects]];
		
		float fuelPrice = [self.posFittingViewController.priceManager priceWithType:self.posFittingViewController.posFuelRequirements.resourceType];
		priceStats.fuelDailyCost = priceStats.fuelConsumtion * fuelPrice * 24;
		weakOperation.progress = 0.5;
		
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			for (i = structuresList.begin(); i != end; i++) {
				NSInteger typeID = (NSInteger) (*i)->getTypeID();
				priceStats.posCost += [prices[@(typeID)] floatValue];
			}
			priceStats.posCost += [prices[@(controlTower->getTypeID())] floatValue];
		}
		
		priceStats.upgradesCost = 0;
		prices = [self.posFittingViewController.priceManager pricesWithTypes:[infrastructureUpgrades allValues]];
		for (NSNumber* number in [prices allValues])
			priceStats.upgradesCost += [number floatValue];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			/*self.fuelCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
									   fuelConsumtion,
									   [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:fuelDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			
			self.infrastructureUpgradesCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
														 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesCost] numberStyle:NSNumberFormatterDecimalStyle],
														 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			self.posCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
									  [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:posCost] numberStyle:NSNumberFormatterDecimalStyle]];*/
			self.priceStats = priceStats;
			if (self.tableView.dataSource == self)
				[self.tableView reloadData];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}


@end
