//
//  NCFittingPOSStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 02.04.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCFittingPOSStatsViewController.h"
#import "NCFittingPOSViewController.h"
#import "NCTableViewCell.h"
#import "NCFittingPOSResourcesCell.h"
#import "NCFittingPOSDefenseOffenseCell.h"
#import "NCFittingResistancesCell.h"
#import "NCFittingEHPCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCPriceManager.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingPOSStatsViewControllerRow : NSObject
@property (nonatomic, assign) BOOL isUpToDate;
@property (nonatomic, strong) NSDictionary* data;
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, copy) void (^configurationBlock)(id tableViewCell, NSDictionary* data);
@property (nonatomic, copy) void (^loadingBlock)(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data));
@end

@interface NCFittingPOSStatsViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCFittingPOSStatsViewControllerRow
@end

@implementation NCFittingPOSStatsViewControllerSection
@end





@interface NCFittingPOSStatsViewController()
@property (nonatomic, strong) NCDBInvControlTowerResource* posFuelRequirements;

@property (nonatomic, strong) NSArray* sections;
@end


@implementation NCFittingPOSStatsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	if (self.controller.engine) {
		if (self.sections) {
			for (NCFittingPOSStatsViewControllerSection* section in self.sections)
				for (NCFittingPOSStatsViewControllerRow* row in section.rows)
					row.isUpToDate = NO;
			completionBlock();
		}
		else {
			[self.controller.engine performBlock:^{
				NSMutableArray* sections = [NSMutableArray new];
				NCFittingPOSStatsViewControllerSection* section;
				NCFittingPOSStatsViewControllerRow* row;

				section = [NCFittingPOSStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resources", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];

					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingPOSResourcesCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingPOSResourcesCell* cell = (NCFittingPOSResourcesCell*) tableViewCell;
						cell.powerGridLabel.text = data[@"powerGrid"];
						cell.powerGridLabel.progress = [data[@"powerGridProgress"] floatValue];
						cell.cpuLabel.text = data[@"cpu"];
						cell.cpuLabel.progress = [data[@"cpuProgress"] floatValue];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								auto controlTower = controller.controller.engine.engine->getControlTower();
								float totalPG = controlTower->getTotalPowerGrid();
								float usedPG = controlTower->getPowerGridUsed();
								float totalCPU = controlTower->getTotalCpu();
								float usedCPU = controlTower->getCpuUsed();
								
								NSDictionary* data =
								@{@"powerGrid": [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"],
								  @"powerGridProgress": totalPG > 0 ? @(usedPG / totalPG) : @(0),
								  @"cpu": [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"],
								  @"cpuProgress": totalCPU > 0 ? @(usedCPU / totalCPU) : @(0)};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					section.rows = rows;
				}
				[sections addObject:section];

				section = [NCFittingPOSStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resistances", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingResistancesHeaderCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						completionBlock(nil);
					};
					[rows addObject:row];
					
					NSArray* images = @[@"shield", @"armor", @"hull", @"damagePattern"];
					for (int i = 0; i < 4; i++) {
						row = [NCFittingPOSStatsViewControllerRow new];
						row.cellIdentifier = @"NCFittingResistancesCell";
						row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
							NCFittingResistancesCell* cell = (NCFittingResistancesCell*) tableViewCell;
							NCProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
							NSArray* values = data[@"values"];
							NSArray* texts = data[@"texts"];
							for (int i = 0; i < 4; i++) {
								labels[i].progress = [values[i] floatValue];
								labels[i].text = texts[i];
							}
							cell.hpLabel.text = data[@"hp"];
							cell.categoryImageView.image = data[@"categoryImage"];
						};
						row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
							if (controller.controller.engine) {
								[controller.controller.engine performBlock:^{
									auto controlTower = controller.controller.engine.engine->getControlTower();
									NSMutableArray* values = [NSMutableArray new];
									NSMutableArray* texts = [NSMutableArray new];
									
									if (i < 3) {
										auto resistances = controlTower->getResistances();
										auto hp = controlTower->getHitPoints();
										
										for (int j = 0; j < 4; j++) {
											[values addObject:@(resistances.layers[i].resistances[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", resistances.layers[i].resistances[j] * 100]];
										}
										[values addObject:@(hp.layers[i])];
										[texts addObject:[NSString shortStringWithFloat:hp.layers[4] unit:nil]];
									}
									else {
										auto damagePattern = controlTower->getDamagePattern();
										for (int j = 0; j < 4; j++) {
											[values addObject:@(damagePattern.damageTypes[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", damagePattern.damageTypes[j] * 100]];
										}
										[values addObject:@(0)];
										[texts addObject:@""];
									}
									
									NSDictionary* data =
									@{@"values": values,
									  @"texts": texts,
									  @"categoryImage": [UIImage imageNamed:images[i]]};
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}
							else
								completionBlock(nil);
						};
						[rows addObject:row];
					}
					
					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingEHPCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingEHPCell* cell = (NCFittingEHPCell*) tableViewCell;
						cell.ehpLabel.text = data[@"ehp"];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								auto controlTower = controller.controller.engine.engine->getControlTower();
								auto effectiveHitPoints = controlTower->getEffectiveHitPoints();
								float ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
								
								NSDictionary* data =
								@{@"ehp": [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString shortStringWithFloat:ehp unit:nil]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingPOSStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Defense/Offense", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					
					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingPOSDefenseOffenseCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingPOSDefenseOffenseCell* cell = (NCFittingPOSDefenseOffenseCell*) tableViewCell;
						cell.shieldRecharge.text = data[@"shieldRecharge"];
						cell.effectiveShieldRecharge.text = data[@"effectiveShieldRecharge"];
						cell.weaponDPSLabel.text = data[@"weaponDPS"];
						cell.weaponVolleyLabel.text = data[@"weaponVolley"];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								auto controlTower = controller.controller.engine.engine->getControlTower();
								auto rtank = controlTower->getTank();
								auto ertank = controlTower->getEffectiveTank();
								float weaponDPS = controlTower->getWeaponDps();
								float volleyDamage = controlTower->getWeaponVolley();

								NSDictionary* data =
								@{@"shieldRecharge": [NSString stringWithFormat:@"%.1f", rtank.passiveShield],
								  @"effectiveShieldRecharge": [NSString stringWithFormat:@"%.1f", ertank.passiveShield],
								  @"weaponDPS": [NSString stringWithFormat:@"%.0f", weaponDPS],
								  @"weaponVolley": [NSString stringWithFormat:@"%.0f", volleyDamage]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					section.rows = rows;
				}
				[sections addObject:section];

				section = [NCFittingPOSStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Cost", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					
					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"Cell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
						cell.iconView.image = data[@"image"] ?: self.defaultTypeImage;
						cell.titleLabel.text = data[@"title"];
						cell.subtitleLabel.text = data[@"subtitle"];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								NSMutableDictionary* data = [NSMutableDictionary new];
								int32_t typeID = self.posFuelRequirements.resourceType.typeID;
								int32_t fuelConsumtion = self.posFuelRequirements.quantity;
								
								if (self.posFuelRequirements.resourceType.icon.image.image)
									data[@"image"] = self.posFuelRequirements.resourceType.icon.image.image;
								if (self.posFuelRequirements.resourceType.typeName)
									data[@"title"] = self.posFuelRequirements.resourceType.typeName;

								[[NCPriceManager sharedManager] requestPricesWithTypes:@[@(typeID)] completionBlock:^(NSDictionary *prices) {
									float fuelDailyCost = fuelConsumtion * [prices[@(typeID)] floatValue];
									data[@"subtitle"] = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
														 fuelConsumtion,
														 [NSNumberFormatter neocomLocalizedStringFromNumber:@(fuelDailyCost)]];
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"Cell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
						cell.iconView.image = data[@"image"] ?: self.defaultTypeImage;
						cell.titleLabel.text = data[@"title"];
						cell.subtitleLabel.text = data[@"subtitle"];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								NSMutableDictionary* data = [NSMutableDictionary new];
								auto controlTower = controller.controller.engine.engine->getControlTower();
								
								data[@"image"] = [[[self.controller.engine.databaseManagedObjectContext eveIconWithIconFile:@"95_02"] image] image];
								data[@"title"] = NSLocalizedString(@"Infrastructure Upgrades Cost", nil);

								NSMutableArray* infrastructureUpgrades = [NSMutableArray new];
								float upgradesDailyCost = 0;
								for (auto i: controlTower->getStructures()) {
									if (i->hasAttribute(1595)) { //anchoringRequiresSovUpgrade1
										int32_t typeID = (int32_t) i->getAttribute(1595)->getValue();
										if (![infrastructureUpgrades containsObject:@(typeID)]) {
											NCDBInvType* upgrade = [controller.controller.engine.databaseManagedObjectContext invTypeWithTypeID:typeID];
											if (upgrade) {
												[infrastructureUpgrades addObject:@(typeID)];
												NCDBDgmTypeAttribute* attribute = upgrade.attributesDictionary[@(1603)];
												upgradesDailyCost += attribute.value;
											}
										}
									}
									//															}
								}

								
								[[NCPriceManager sharedManager] requestPricesWithTypes:infrastructureUpgrades completionBlock:^(NSDictionary *prices) {
									float upgradesCost = 0;
									for (NSNumber* typeID in infrastructureUpgrades)
										upgradesCost += [prices[typeID] floatValue];
									
									data[@"subtitle"] = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
														 [NSNumberFormatter neocomLocalizedStringFromNumber:@(upgradesCost)],
														 [NSNumberFormatter neocomLocalizedStringFromNumber:@(upgradesDailyCost)]];
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];

					row = [NCFittingPOSStatsViewControllerRow new];
					row.cellIdentifier = @"Cell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
						cell.iconView.image = data[@"image"] ?: self.defaultTypeImage;
						cell.titleLabel.text = data[@"title"];
						cell.subtitleLabel.text = data[@"subtitle"];
					};
					row.loadingBlock = ^(NCFittingPOSStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						if (controller.controller.engine) {
							[controller.controller.engine performBlock:^{
								NSMutableDictionary* data = [NSMutableDictionary new];
								auto controlTower = controller.controller.engine.engine->getControlTower();
								
								data[@"image"] = [[[self.controller.engine.databaseManagedObjectContext eveIconWithIconFile:@"07_12"] image] image];
								data[@"title"] = NSLocalizedString(@"POS Cost", nil);
								
								NSMutableArray* types = [NSMutableArray new];
								[types addObject:@(controlTower->getTypeID())];
								
								for (auto i: controlTower->getStructures())
									[types addObject:@(i->getTypeID())];
								
								
								[[NCPriceManager sharedManager] requestPricesWithTypes:types completionBlock:^(NSDictionary *prices) {
									float posCost = 0;
									for (NSNumber* typeID in types)
										posCost += [prices[typeID] floatValue];
									
									data[@"subtitle"] = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
														 [NSNumberFormatter neocomLocalizedStringFromNumber:@(posCost)]];
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					section.rows = rows;
				}
				[sections addObject:section];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					self.sections = sections;
					completionBlock();
				});

			}];
		}
	}
	else
		completionBlock();
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections[section] rows] count];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.sections[section] title];
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 4)
		[self.controller performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingPOSStatsViewControllerRow* row = [self.sections[indexPath.section] rows][indexPath.row];
	return row.cellIdentifier;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingPOSStatsViewControllerRow* row = [self.sections[indexPath.section] rows][indexPath.row];
	if (!row.isUpToDate) {
		row.isUpToDate = YES;
		row.loadingBlock(self, ^(NSDictionary* data) {
			dispatch_async(dispatch_get_main_queue(), ^{
				row.data = data;
				if (data)
					[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			});
		});
	}
	if (row.data)
		row.configurationBlock(tableViewCell, row.data);
}

#pragma mark - Private

- (NCDBInvControlTowerResource*) posFuelRequirements {
	if (!_posFuelRequirements) {
		[self.controller.engine performBlockAndWait:^{
			NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:self.controller.fit.typeID];
			for (NCDBInvControlTowerResource* resource in type.controlTower.resources) {
				if (resource.minSecurityLevel == 0.0 && resource.purpose.purposeID == 1) {
					_posFuelRequirements = resource;
					break;
				}
			}
		}];
	}
	return _posFuelRequirements;
}

@end
