//
//  NCFittingShipModulesViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 12.06.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCFittingShipModulesViewController.h"
#import "NCFittingShipViewController.h"
#import "UIView+Nib.h"
#import "NSString+Neocom.h"
#import <algorithm>
#import "NCTableViewCell.h"
#import "NCFittingShipModuleCell.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCFittingSectionGenericHeaderView.h"
#import "UIActionSheet+Block.h"
#import "NCFittingSectionHiSlotHeaderView.h"

#define ActionButtonOffline NSLocalizedString(@"Put Offline", nil)
#define ActionButtonOnline NSLocalizedString(@"Put Online", nil)
#define ActionButtonOverheatOn NSLocalizedString(@"Enable Overheating", nil)
#define ActionButtonOverheatOff NSLocalizedString(@"Disable Overheating", nil)
#define ActionButtonActivate NSLocalizedString(@"Activate", nil)
#define ActionButtonDeactivate NSLocalizedString(@"Deactivate", nil)
#define ActionButtonAmmo NSLocalizedString(@"Ammo", nil)
#define ActionButtonCancel NSLocalizedString(@"Cancel", nil)
#define ActionButtonDelete NSLocalizedString(@"Delete", nil)
#define ActionButtonChangeState NSLocalizedString(@"Change State", nil)
#define ActionButtonUnloadAmmo NSLocalizedString(@"Unload Ammo", nil)
#define ActionButtonShowModuleInfo NSLocalizedString(@"Show Module Info", nil)
#define ActionButtonShowAmmoInfo NSLocalizedString(@"Show Ammo Info", nil)
#define ActionButtonSetTarget NSLocalizedString(@"Set Target", nil)
#define ActionButtonClearTarget NSLocalizedString(@"Clear Target", nil)
#define ActionButtonVariations NSLocalizedString(@"Variations", nil)
#define ActionButtonAllSimilarModules NSLocalizedString(@"All Similar Modules", nil)
#define ActionButtonAffectingSkills NSLocalizedString(@"Affecting Skills", nil)

@interface NCFittingShipModulesViewControllerRow : NSObject<NSCopying>
@property (nonatomic, assign) std::shared_ptr<eufe::Module> module;

@property (nonatomic, assign) BOOL isUpToDate;

@property (nonatomic, strong) NSString* typeName;
@property (nonatomic, strong) UIColor* typeNameColor;
@property (nonatomic, strong) UIImage* typeImage;
@property (nonatomic, strong) NSString* chargeText;
@property (nonatomic, strong) NSString* optimalText;
@property (nonatomic, strong) UIColor* trackingColor;
@property (nonatomic, strong) NSAttributedString* trackingText;
@property (nonatomic, strong) NSString* lifeTimeText;
@property (nonatomic, strong) UIImage* stateImage;
@property (nonatomic, strong) UIImage* targetImage;

@property (nonatomic, assign) float trackingSpeed;
@property (nonatomic, assign) float orbitRadius;
@end

@implementation NCFittingShipModulesViewControllerRow

- (id) copyWithZone:(NSZone *)zone {
	NCFittingShipModulesViewControllerRow* other = [NCFittingShipModulesViewControllerRow new];
	other.module = self.module;
	other.isUpToDate = self.isUpToDate;
	other.typeName = self.typeName;
	other.typeNameColor = self.typeNameColor;
	other.typeImage = self.typeImage;
	other.chargeText = self.chargeText;
	other.optimalText = self.optimalText;
	other.trackingColor = self.trackingColor;
	other.trackingText = self.trackingText;
	other.lifeTimeText = self.lifeTimeText;
	other.stateImage = self.stateImage;
	other.targetImage = self.targetImage;
	other.trackingSpeed = self.trackingSpeed;
	other.orbitRadius = self.orbitRadius;
	return other;
}

@end

@interface NCFittingShipModulesViewControllerSection : NSObject
@property (nonatomic, strong) NSArray* rows;
@property (nonatomic, assign) eufe::Module::Slot slot;
@property (nonatomic, assign) int numberOfSlots;
@end

@implementation NCFittingShipModulesViewControllerSection

@end

@interface NCFittingShipModulesViewController()
@property (nonatomic, assign) int usedTurretHardpoints;
@property (nonatomic, assign) int totalTurretHardpoints;
@property (nonatomic, assign) int usedMissileHardpoints;
@property (nonatomic, assign) int totalMissileHardpoints;

@property (nonatomic, strong) NSArray* sections;

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath;

@end

@implementation NCFittingShipModulesViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"NCFittingSectionHiSlotHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NCFittingSectionHiSlotHeaderView"];
}

- (void) reloadWithCompletionBlock:(void(^)()) completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		NSMutableArray* sections = [NSMutableArray new];
		NSArray* oldSections = self.sections;
		[self.controller.engine performBlock:^{
			float usedTurretHardpoints;
			float totalTurretHardpoints;
			float usedMissileHardpoints;
			float totalMissileHardpoints;
			NSMutableDictionary* oldRows = [NSMutableDictionary new];
			for (NCFittingShipModulesViewControllerSection* section in oldSections)
				for (NCFittingShipModulesViewControllerRow* row in section.rows)
					oldRows[@((uintptr_t) row.module.get())] = row;
			
			
			auto ship = pilot->getShip();
			
			eufe::Module::Slot slots[] = {eufe::Module::SLOT_MODE, eufe::Module::SLOT_HI, eufe::Module::SLOT_MED, eufe::Module::SLOT_LOW, eufe::Module::SLOT_RIG, eufe::Module::SLOT_SUBSYSTEM};
			int n = sizeof(slots) / sizeof(eufe::Module::Slot);
			
			for (int i = 0; i < n; i++) {
				int numberOfSlots = ship->getNumberOfSlots(slots[i]);
				eufe::ModulesList modules;
				ship->getModules(slots[i], std::inserter(modules, modules.end()));
				if (numberOfSlots > 0 || modules.size() > 0) {
					NCFittingShipModulesViewControllerSection* section = [NCFittingShipModulesViewControllerSection new];
					section.slot = slots[i];
					section.numberOfSlots = numberOfSlots;
					NSMutableArray* rows = [NSMutableArray new];
					
					for (auto module: modules) {
						NCFittingShipModulesViewControllerRow* row = [oldRows[@((uintptr_t) module.get())] copy] ?: [NCFittingShipModulesViewControllerRow new];
						row.module = module;
						row.isUpToDate = NO;
						[rows addObject:row];
					}
					section.rows = rows;
					[sections addObject:section];
				}
			}
			
			usedTurretHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_TURRET);
			totalTurretHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_TURRET);
			usedMissileHardpoints = ship->getUsedHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			totalMissileHardpoints = ship->getNumberOfHardpoints(eufe::Module::HARDPOINT_LAUNCHER);
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.sections = sections;
				
				self.usedTurretHardpoints = usedTurretHardpoints;
				self.totalTurretHardpoints = totalTurretHardpoints;
				self.usedMissileHardpoints = usedMissileHardpoints;
				self.totalMissileHardpoints = totalMissileHardpoints;
				completionBlock();
			});
		}];
	}
	else
		completionBlock();
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
	//return self.view.window ? self.sections.count : 0;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
	NCFittingShipModulesViewControllerSection* section = self.sections[sectionIndex];
	if (!section)
		return 0;
	else
		return std::max(section.numberOfSlots, static_cast<int>(section.rows.count));
}

#pragma mark - Table view delegate

- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex {
	NCFittingShipModulesViewControllerSection* section = self.sections[sectionIndex];
	
	if (section.slot == eufe::Module::SLOT_HI) {
		NCFittingSectionHiSlotHeaderView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionHiSlotHeaderView"];
		header.turretsLabel.text = [NSString stringWithFormat:@"%d/%d", self.usedTurretHardpoints, self.totalTurretHardpoints];
		header.launchersLabel.text = [NSString stringWithFormat:@"%d/%d", self.usedMissileHardpoints, self.totalMissileHardpoints];
		return header;
	}
	else {
		NCFittingSectionGenericHeaderView* header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCFittingSectionGenericHeaderView"];
		switch (section.slot) {
			case eufe::Module::SLOT_MED:
				header.imageView.image = [UIImage imageNamed:@"slotMed.png"];
				header.titleLabel.text = NSLocalizedString(@"Med slots", nil);
				break;
			case eufe::Module::SLOT_LOW:
				header.imageView.image = [UIImage imageNamed:@"slotLow.png"];
				header.titleLabel.text = NSLocalizedString(@"Low slots", nil);
				break;
			case eufe::Module::SLOT_RIG:
				header.imageView.image = [UIImage imageNamed:@"slotRig.png"];
				header.titleLabel.text = NSLocalizedString(@"Rig slots", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				header.imageView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				header.titleLabel.text = NSLocalizedString(@"Subsystem slots", nil);
				break;
			case eufe::Module::SLOT_MODE:
			default:
				header.imageView.image = nil;
				header.titleLabel.text = NSLocalizedString(@"Tactical Mode", nil);
		}
		return header;
	}
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 44;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesViewControllerSection* section = self.sections[indexPath.section];
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row >= section.rows.count || section.slot == eufe::Module::SLOT_MODE) {
		//auto ship = self.controller.fit.pilot->getShip();
//
		__block NSString* title;
		NCDBEufeItemCategory* category;
		switch (section.slot) {
			case eufe::Module::SLOT_HI:
				title = NSLocalizedString(@"Hi slot", nil);
				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotHi size:0 race:nil];
				break;
			case eufe::Module::SLOT_MED:
				title = NSLocalizedString(@"Med slot", nil);
				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotMed size:0 race:nil];
				break;
			case eufe::Module::SLOT_LOW:
				title = NSLocalizedString(@"Low slot", nil);
				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotLow size:0 race:nil];
				break;
			case eufe::Module::SLOT_RIG: {
				title = NSLocalizedString(@"Rigs", nil);
				__block int32_t size = 0;
				[self.controller.engine performBlockAndWait:^{
					auto ship = self.controller.fit.pilot->getShip();
					size = ship->getAttribute(1547)->getValue();
				}];

				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotRig size:size race:nil];
				break;
			}
			case eufe::Module::SLOT_SUBSYSTEM: {
				__block NSManagedObjectID* raceObjectID;
				[self.controller.engine performBlockAndWait:^{
					auto ship = self.controller.fit.pilot->getShip();
					NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:ship->getTypeID()];
					int32_t raceID = static_cast<int32_t>(ship->getAttribute(eufe::RACE_ID_ATTRIBUTE_ID)->getValue());
					switch(raceID) {
						case 1: //Caldari
							title = NSLocalizedString(@"Caldari Subsystems", nil);
							break;
						case 2: //Minmatar
							title = NSLocalizedString(@"Minmatar Subsystems", nil);
							break;
						case 4: //Amarr
							title = NSLocalizedString(@"Amarr Subsystems", nil);
							break;
						case 8: //Gallente
							title = NSLocalizedString(@"Gallente Subsystems", nil);
							break;
					}
					raceObjectID = type.race.objectID;
				}];
				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotSubsystem size:0 race:[self.databaseManagedObjectContext objectWithID:raceObjectID]];
				break;
			}
			case eufe::Module::SLOT_MODE:
				title = NSLocalizedString(@"Tactical Mode", nil);
				category = [self.databaseManagedObjectContext categoryWithSlot:NCDBEufeItemSlotMode size:self.controller.fit.typeID race:nil];
				break;
			default:
				return;
		}
		self.controller.typePickerViewController.title = title;
		[self.controller.typePickerViewController presentWithCategory:category
													 inViewController:self.controller
															 fromRect:cell.bounds
															   inView:cell
															 animated:YES
													completionHandler:^(NCDBInvType *type) {
														int32_t typeID = type.typeID;
														[self.controller.engine performBlockAndWait:^{
															auto ship = self.controller.fit.pilot->getShip();
															if (section.slot == eufe::Module::SLOT_MODE) {
																eufe::ModulesList modes;
																ship->getModules(eufe::Module::SLOT_MODE, std::inserter(modes, modes.end()));
																for (auto i:modes)
																	ship->removeModule(i);
															}
															ship->addModule(typeID);
														}];
														[self.controller reload];
														if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
															[self.controller dismissAnimated];
													}];
	}
	else {
		[self performActionForRowAtIndexPath:indexPath];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NCTableViewController

- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingShipModulesViewControllerSection* section = self.sections[indexPath.section];
	NCFittingShipModulesViewControllerRow* row = indexPath.row < section.rows.count ? section.rows[indexPath.row] : nil;
	if (!row.typeName)
		return @"Cell";
	else
		return @"NCFittingShipModuleCell";
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell*) tableViewCell forRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingShipModulesViewControllerSection* section = self.sections[indexPath.section];
	NCFittingShipModulesViewControllerRow* row = indexPath.row < section.rows.count ? section.rows[indexPath.row] : nil;
	if (!row.typeName) {
		NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
		cell.subtitleLabel.text = nil;
		cell.accessoryView = nil;
		switch (section.slot) {
			case eufe::Module::SLOT_HI:
				cell.iconView.image = [UIImage imageNamed:@"slotHigh.png"];
				cell.titleLabel.text = NSLocalizedString(@"High slot", nil);
				break;
			case eufe::Module::SLOT_MED:
				cell.iconView.image = [UIImage imageNamed:@"slotMed.png"];
				cell.titleLabel.text = NSLocalizedString(@"Med slot", nil);
				break;
			case eufe::Module::SLOT_LOW:
				cell.iconView.image = [UIImage imageNamed:@"slotLow.png"];
				cell.titleLabel.text = NSLocalizedString(@"Low slot", nil);
				break;
			case eufe::Module::SLOT_RIG:
				cell.iconView.image = [UIImage imageNamed:@"slotRig.png"];
				cell.titleLabel.text = NSLocalizedString(@"Rig slot", nil);
				break;
			case eufe::Module::SLOT_SUBSYSTEM:
				cell.iconView.image = [UIImage imageNamed:@"slotSubsystem.png"];
				cell.titleLabel.text = NSLocalizedString(@"Subsystem slot", nil);
				break;
			case eufe::Module::SLOT_MODE:
				cell.iconView.image = [UIImage imageNamed:@"ships.png"];
				cell.titleLabel.text = NSLocalizedString(@"Tactical mode", nil);
				break;
			default:
				cell.iconView.image = nil;
				cell.titleLabel.text = nil;
		}
	}
	else {
		NCFittingShipModuleCell* cell = (NCFittingShipModuleCell*) tableViewCell;

		cell.typeNameLabel.text = row.typeName;
		cell.typeNameLabel.textColor = row.typeNameColor;
		cell.typeImageView.image = row.typeImage;
		cell.chargeLabel.text = row.chargeText;
		cell.optimalLabel.text = row.optimalText;
		if (!row.trackingText && row.trackingSpeed > 0) {
			NSMutableAttributedString* s = [NSMutableAttributedString new];
			
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@ rad/sec (", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.trackingSpeed)]]
																	  attributes:nil]];
			NSTextAttachment* icon;
			icon = [NSTextAttachment new];
			icon.image = [UIImage imageNamed:@"targetingRange.png"];
			icon.bounds = CGRectMake(0, -7 -cell.trackingLabel.font.descender, 15, 15);
			[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
			[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"%@+ m)", nil),
																				  [NSNumberFormatter neocomLocalizedStringFromNumber:@(row.orbitRadius)]]
																	  attributes:nil]];
			row.trackingText = s;
		}
		cell.trackingLabel.attributedText = row.trackingText;
		cell.trackingLabel.textColor = row.trackingColor;
		cell.lifetimeLabel.text = row.lifeTimeText;
		cell.stateImageView.image = row.stateImage;
		cell.targetImageView.image = row.targetImage;
	}
	if (row.module && !row.isUpToDate) {
		row.isUpToDate = YES;
		[self.controller.engine performBlock:^{
			auto ship = self.controller.fit.pilot->getShip();
			auto module = row.module;
			NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:module->getTypeID()];
			row.typeName = type.typeName;
			row.typeNameColor = module->isEnabled() ? [UIColor whiteColor] : [UIColor redColor];
			row.typeImage = type.icon ? type.icon.image.image : self.defaultTypeImage;
			
			auto charge = module->getCharge();
			if (charge) {
				float volume = charge->getAttribute(eufe::VOLUME_ATTRIBUTE_ID)->getValue();
				float capacity = module->getAttribute(eufe::CAPACITY_ATTRIBUTE_ID)->getValue();
				NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:charge->getTypeID()];
				if (volume > 0 && volume > 0)
					row.chargeText = [NSString stringWithFormat:@"%@ x %d", type.typeName, (int)(capacity / volume)];
				else
					row.chargeText = type.typeName;
			}
			else
				row.chargeText = nil;
			
			float optimal = module->getMaxRange();
			float falloff = module->getFalloff();
			float trackingSpeed = module->getTrackingSpeed();
			float lifeTime = module->getLifeTime();
			
			row.trackingText = nil;
			if (trackingSpeed > 0) {
				float v0 = ship->getMaxVelocityInOrbit(optimal);
				float v1 = ship->getMaxVelocityInOrbit(optimal + falloff);
				float orbitRadius = ship->getOrbitRadiusWithAngularVelocity(trackingSpeed);
				row.trackingColor = trackingSpeed * optimal > v0 ? [UIColor greenColor] : (trackingSpeed * (optimal + falloff) > v1 ? [UIColor yellowColor] : [UIColor redColor]);
				row.trackingSpeed = trackingSpeed;
				row.orbitRadius = orbitRadius;
			}
			
			if (optimal > 0) {
				NSMutableString* s = [NSMutableString stringWithFormat:NSLocalizedString(@"%@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(optimal)]];
				if (falloff > 0)
					[s appendFormat:NSLocalizedString(@" + %@m", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(falloff)]];
				row.optimalText = s;
			}
			else
				row.optimalText = nil;
			
			if (lifeTime > 0)
				row.lifeTimeText = [NSString stringWithFormat:NSLocalizedString(@"Lifetime: %@", nil), [NSString stringWithTimeLeft:lifeTime]];
			else
				row.lifeTimeText = nil;
			
			eufe::Module::Slot slot = module->getSlot();
			if (slot == eufe::Module::SLOT_HI || slot == eufe::Module::SLOT_MED || slot == eufe::Module::SLOT_LOW) {
				switch (module->getState()) {
					case eufe::Module::STATE_ACTIVE:
						row.stateImage = [UIImage imageNamed:@"active.png"];
						break;
					case eufe::Module::STATE_ONLINE:
						row.stateImage = [UIImage imageNamed:@"online.png"];
						break;
					case eufe::Module::STATE_OVERLOADED:
						row.stateImage = [UIImage imageNamed:@"overheated.png"];
						break;
					default:
						row.stateImage = [UIImage imageNamed:@"offline.png"];
						break;
				}
			}
			else
				row.stateImage = nil;
			
			row.targetImage = module->getTarget() != nullptr ? self.targetImage : nil;
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			});
		}];
	}
}

#pragma mark - Private

- (void) performActionForRowAtIndexPath:(NSIndexPath*) indexPath {
	NCFittingShipModulesViewControllerSection* section = self.sections[indexPath.section];
	UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NCFittingShipModulesViewControllerRow* row = section.rows[indexPath.row];
	NSMutableArray* actions = [NSMutableArray new];

	[self.controller.engine performBlockAndWait:^{
		auto ship = self.controller.fit.pilot->getShip();
		auto module = row.module;
		NCDBInvType* type = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:row.module->getTypeID()];
		
		eufe::ModulesList allSimilarModules;
		
		bool multiple = false;
		for (NCFittingShipModulesViewControllerRow* module in section.rows) {
			NCDBInvType* moduleType = [self.controller.engine.databaseManagedObjectContext invTypeWithTypeID:module.module->getTypeID()];
			if (type.marketGroup.marketGroupID == moduleType.marketGroup.marketGroupID)
				allSimilarModules.push_back(module.module);
		}
		multiple = allSimilarModules.size() > 1;
		
		
		eufe::Module::State state = module->getState();
		
		void (^setState)(eufe::ModulesList, eufe::Module::State) = ^(eufe::ModulesList modules, eufe::Module::State state) {
			[self.controller.engine performBlockAndWait:^{
				for (auto module: modules)
					module->setState(state);
			}];
			[self.controller reload];
		};
		
		NSArray* (^statesActions)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			NSMutableArray* statesActions = [NSMutableArray new];
			
			if (state != eufe::Module::STATE_OFFLINE && module->canHaveState(eufe::Module::STATE_OFFLINE))
				[statesActions addObject:[UIAlertAction actionWithTitle:ActionButtonOffline style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					setState(modules, eufe::Module::STATE_OFFLINE);
				}]];
			if (state != eufe::Module::STATE_ONLINE && module->canHaveState(eufe::Module::STATE_ONLINE))
				[statesActions addObject:[UIAlertAction actionWithTitle:state > eufe::Module::STATE_ONLINE ? ActionButtonDeactivate : ActionButtonOnline style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					setState(modules, eufe::Module::STATE_ONLINE);
				}]];
			if (state != eufe::Module::STATE_ACTIVE && module->canHaveState(eufe::Module::STATE_ACTIVE))
				[statesActions addObject:[UIAlertAction actionWithTitle:state < eufe::Module::STATE_ACTIVE ? ActionButtonActivate : ActionButtonOverheatOff style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					setState(modules, eufe::Module::STATE_ACTIVE);
				}]];
			if (state != eufe::Module::STATE_OVERLOADED && module->canHaveState(eufe::Module::STATE_OVERLOADED))
				[statesActions addObject:[UIAlertAction actionWithTitle:ActionButtonOverheatOn style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					setState(modules, eufe::Module::STATE_OVERLOADED);
				}]];
			return statesActions;
		};

		UIAlertAction* (^removeAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonDelete style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					for (auto module: modules)
						ship->removeModule(module);
				}];
				[self.controller reload];
			}];
		};
		
		eufe::ModulesList modules;
		modules.push_back(module);
		[actions addObject:removeAction(modules)];
		
		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowModuleInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
												 sender:@{@"sender": cell, @"object": [NCFittingEngineItemPointer pointerWithItem:module]}];
		}]];

		
		if (module->getCharge() != NULL) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonShowAmmoInfo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				__block NCFittingEngineItemPointer* pointer;
				[self.controller.engine performBlockAndWait:^{
					pointer = [NCFittingEngineItemPointer pointerWithItem:row.module->getCharge()];
				}];
				[self.controller performSegueWithIdentifier:@"NCDatabaseTypeInfoViewController"
													 sender:@{@"sender": cell, @"object": pointer}];
			}]];
		}
		
		
		NSArray* states = statesActions(modules);
		if (states.count > 0) {
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
				[actions addObjectsFromArray:states];
			else {
				[actions addObject:[UIAlertAction actionWithTitle:ActionButtonChangeState style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
					for (UIAlertAction* action in states)
						[controller addAction:action];
					[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
						
					}]];
					[self.controller presentViewController:controller animated:YES completion:nil];
				}]];
			}
		}
		
		
		UIAlertAction* (^ammoAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonAmmo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				__block NSManagedObjectID* categoryID;
				[self.controller.engine performBlockAndWait:^{
					categoryID = [type.eufeItem.charge objectID];
				}];
				
				self.controller.typePickerViewController.title = NSLocalizedString(@"Ammo", nil);
				[self.controller.typePickerViewController presentWithCategory:[self.databaseManagedObjectContext objectWithID:categoryID]
															 inViewController:self.controller
																	 fromRect:cell.bounds
																	   inView:cell
																	 animated:YES
															completionHandler:^(NCDBInvType *type) {
																int32_t typeID = type.typeID;
																[self.controller.engine performBlockAndWait:^{
																	for (auto module: modules)
																		module->setCharge(typeID);
																}];
																[self.controller reload];
																[self.controller dismissAnimated];
															}];
			}];
		};

		UIAlertAction* (^unloadAmmoAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonUnloadAmmo style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					for (auto module: modules)
						module->clearCharge();
				}];
				[self.controller reload];
			}];
		};
		
		if (module->getChargeGroups().size() > 0) {
			[actions addObject:ammoAction(modules)];

			
			if (module->getCharge() != nullptr) {
				[actions addObject:unloadAmmoAction(modules)];
			}
		}
		
		UIAlertAction* (^setTargetAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonSetTarget style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSMutableArray* array = [NSMutableArray new];
				[self.controller.engine performBlockAndWait:^{
					for (auto module: modules)
						[array addObject:[NCFittingEngineItemPointer pointerWithItem:module]];
				}];
				[self.controller performSegueWithIdentifier:@"NCFittingTargetsViewController"
													 sender:@{@"sender": cell, @"object": array}];
			}];
		};
		
		
		UIAlertAction* (^clearTargetAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonSetTarget style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[self.controller.engine performBlockAndWait:^{
					for (auto module: modules)
						module->clearTarget();
					[self.controller reload];
				}];
			}];
		};
		
		if (module->requireTarget() && self.controller.fits.count > 1) {
			[actions addObject:setTargetAction(modules)];

			if (module->getTarget() != nullptr) {
				[actions addObject:clearTargetAction(modules)];
			}
		}
		
		UIAlertAction* (^variationsAction)(eufe::ModulesList) = ^(eufe::ModulesList modules) {
			return [UIAlertAction actionWithTitle:ActionButtonSetTarget style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSMutableArray* array = [NSMutableArray new];
				[self.controller.engine performBlockAndWait:^{
					for (auto module: modules)
						[array addObject:[NCFittingEngineItemPointer pointerWithItem:module]];
				}];
				[self.controller performSegueWithIdentifier:@"NCFittingTypeVariationsViewController"
													 sender:@{@"sender": cell, @"object": array}];
			}];
		};

		
		[actions addObject:variationsAction(modules)];

		[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAffectingSkills style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self.controller performSegueWithIdentifier:@"NCFittingShipAffectingSkillsViewController"
												 sender:@{@"sender": cell, @"object": @[[NCFittingEngineItemPointer pointerWithItem:module]]}];
		}]];

		
		if (multiple) {
			[actions addObject:[UIAlertAction actionWithTitle:ActionButtonAllSimilarModules style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				NSMutableArray* actions = [NSMutableArray new];
				
				[self.controller.engine performBlockAndWait:^{
					
					[actions addObject:removeAction(allSimilarModules)];
					
					if (module->getChargeGroups().size() > 0) {
						[actions addObject:ammoAction(allSimilarModules)];
						
						if (module->getCharge() != nil) {
							[actions addObject:unloadAmmoAction(allSimilarModules)];
						}
					}
					[actions addObject:variationsAction(allSimilarModules)];
					
					if (module->requireTarget() && self.controller.fits.count > 1) {
						[actions addObject:setTargetAction(allSimilarModules)];
						if (module->getTarget() != nullptr) {
							[actions addObject:clearTargetAction(allSimilarModules)];
						}
					}
					NSArray* states = statesActions(allSimilarModules);
					if (states.count > 0)
						[actions addObjectsFromArray:states];

				}];
				UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
				for (UIAlertAction* action in actions)
					[controller addAction:action];
				[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
				[self.controller presentViewController:controller animated:YES completion:nil];
			}]];
		}
	}];
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	for (UIAlertAction* action in actions)
		[controller addAction:action];
	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	[self.controller presentViewController:controller animated:YES completion:nil];
	
}

@end
