//
//  POSStatsViewController.m
//  EVEUniverse
//
//  Created by Mr. Depth on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "POSStatsViewController.h"
#import "POSFittingViewController.h"
#import "NSString+Fitting.h"
#import "NSString+TimeLeft.h"
#import "EUOperationQueue.h"
#import "POSFit.h"
#import "PriceManager.h"
#import "ItemInfo.h"

#import "eufe.h"

@interface POSStatsViewController()
- (void) updatePrice;
@end

@implementation POSStatsViewController

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

	self.fuelImageView.image = [UIImage imageNamed:self.posFittingViewController.posFuelRequirements.resourceType.typeSmallImageName];
	self.fuelTypeLabel.text = self.posFittingViewController.posFuelRequirements.resourceType.typeName;
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
	
	self.shieldRecharge = nil;
	
	self.weaponDPSLabel = nil;
	
	self.fuelTypeLabel = nil;
	self.fuelCostLabel = nil;
	self.fuelImageView = nil;
	self.infrastructureUpgradesCostLabel = nil;
	self.posCostLabel = nil;
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
	__block eufe::Resistances resistances;
	__block eufe::HitPoints hp;
	__block float ehp;
	__block eufe::Tank rtank;
	__block eufe::Tank ertank;
	
	__block float weaponDPS;
	__block float volleyDamage;
	
	__block DamagePattern* damagePattern = nil;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsViewController+Update" name:NSLocalizedString(@"Updating Stats", nil)];
	__weak EUOperation* weakOperation = operation;
	POSFittingViewController* aPosFittingViewController = self.posFittingViewController;

	[operation addExecutionBlock:^(void) {
		@synchronized(self.posFittingViewController) {
			
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			
			totalPG = controlTower->getTotalPowerGrid();
			usedPG = controlTower->getPowerGridUsed();
			
			totalCPU = controlTower->getTotalCpu();
			usedCPU = controlTower->getCpuUsed();
			
			resistances = controlTower->getResistances();
			
			hp = controlTower->getHitPoints();
			eufe::HitPoints effectiveHitPoints = controlTower->getEffectiveHitPoints();
			ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
			
			rtank = controlTower->getTank();
			ertank = controlTower->getEffectiveTank();
			
			weaponDPS = controlTower->getWeaponDps();
			volleyDamage = controlTower->getWeaponVolley();
			
			damagePattern = self.posFittingViewController.damagePattern;
		}
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
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
			
			self.weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f\n%.0f",weaponDPS, volleyDamage];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self updatePrice];
}

#pragma mark - Private

- (void) updatePrice {
	__block int fuelConsumtion;
	__block float fuelDailyCost;
	__block float upgradesCost;
	__block float upgradesDailyCost;
	__block float posCost;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsViewController+UpdatePrice" name:NSLocalizedString(@"Updating Price", nil)];
	__weak EUOperation* weakOperation = operation;
	POSFittingViewController* aPosFittingViewController = self.posFittingViewController;
	
	[operation addExecutionBlock:^(void) {
		NSMutableSet* types = [NSMutableSet set];
		NSMutableDictionary* infrastructureUpgrades = [NSMutableDictionary dictionary];

		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = aPosFittingViewController.fit.controlTower;
			fuelConsumtion = aPosFittingViewController.posFuelRequirements.quantity;
			
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			
			[types addObject:aPosFittingViewController.fit];

			upgradesDailyCost = 0;
			for (i = structuresList.begin(); i != end; i++) {
				ItemInfo* itemInfo = [ItemInfo itemInfoWithItem:*i error:nil];
				if (itemInfo)
					[types addObject:itemInfo];
				
				if ((*i)->hasAttribute(1595)) { //anchoringRequiresSovUpgrade1
					NSInteger typeID = (NSInteger) (*i)->getAttribute(1595)->getValue();
					NSString* key = [NSString stringWithFormat:@"%d", typeID];
					EVEDBInvType* upgrade = [infrastructureUpgrades valueForKey:key];
					if (!upgrade) {
						upgrade = [EVEDBInvType invTypeWithTypeID:typeID error:nil];
						if (upgrade) {
							[types addObject:upgrade];
							[infrastructureUpgrades setValue:upgrade forKey:key];
							EVEDBDgmTypeAttribute* attribute = [upgrade.attributesDictionary valueForKey:@"1603"];//sovBillSystemCost
							upgradesDailyCost += attribute.value; 
						}
					}
				}
			}
		}
		[types addObject:aPosFittingViewController.posFuelRequirements.resourceType];
			
		NSDictionary* prices = [aPosFittingViewController.priceManager pricesWithTypes:[types allObjects]];

		float fuelPrice = [aPosFittingViewController.priceManager priceWithType:aPosFittingViewController.posFuelRequirements.resourceType];
		fuelDailyCost = fuelConsumtion * fuelPrice * 24;
		weakOperation.progress = 0.5;
		
		@synchronized(self.posFittingViewController) {
			eufe::ControlTower* controlTower = self.posFittingViewController.fit.controlTower;
			const eufe::StructuresList& structuresList = controlTower->getStructures();
			eufe::StructuresList::const_iterator i, end = structuresList.end();
			for (i = structuresList.begin(); i != end; i++) {
				NSInteger typeID = (NSInteger) (*i)->getTypeID();
				NSString* key = [NSString stringWithFormat:@"%d", typeID];
				posCost += [[prices valueForKey:key] floatValue];
			}
			posCost += [[prices valueForKey:[NSString stringWithFormat:@"%d", controlTower->getTypeID()]] floatValue];
		}
		
		upgradesCost = 0;
		prices = [aPosFittingViewController.priceManager pricesWithTypes:[infrastructureUpgrades allValues]];
		for (NSNumber* number in [prices allValues])
			upgradesCost += [number floatValue];
		weakOperation.progress = 1.0;
	}];
	
	[operation setCompletionBlockInMainThread:^(void) {
		if (![weakOperation isCancelled]) {
			self.fuelCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
								  fuelConsumtion,
								  [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:fuelDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			
			self.infrastructureUpgradesCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
													[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesCost] numberStyle:NSNumberFormatterDecimalStyle],
													[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			self.posCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
								 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:posCost] numberStyle:NSNumberFormatterDecimalStyle]];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
