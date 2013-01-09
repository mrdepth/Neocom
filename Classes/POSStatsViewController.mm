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

#import "eufe.h"

@interface POSStatsViewController(Private)
- (void) updatePrice;
@end

@implementation POSStatsViewController
@synthesize posFittingViewController;
@synthesize scrollView;
@synthesize contentView;

@synthesize powerGridLabel;
@synthesize cpuLabel;

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

@synthesize shieldRecharge;

@synthesize weaponDPSLabel;

@synthesize fuelTypeLabel;
@synthesize fuelCostLabel;
@synthesize fuelImageView;
@synthesize infrastructureUpgradesCostLabel;
@synthesize posCostLabel;

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

	self.fuelImageView.image = [UIImage imageNamed:posFittingViewController.posFuelRequirements.resourceType.typeSmallImageName];
	self.fuelTypeLabel.text = posFittingViewController.posFuelRequirements.resourceType.typeName;
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


- (void)dealloc {
	[scrollView release];
	[contentView release];
	
	[powerGridLabel release];
	[cpuLabel release];
	
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
	
	[shieldRecharge release];
	
	[weaponDPSLabel release];
	
	[fuelTypeLabel release];
	[fuelCostLabel release];
	[fuelImageView release];
	[infrastructureUpgradesCostLabel release];
	[posCostLabel release];

    [super dealloc];
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
	
	__block UIImage *sensorImage = nil;
	__block DamagePattern* damagePattern = nil;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsViewController+Update" name:NSLocalizedString(@"Updating Stats", nil)];
	POSFittingViewController* aPosFittingViewController = posFittingViewController;

	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(posFittingViewController) {
			
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
			
			damagePattern = [aPosFittingViewController.damagePattern retain];
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			
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
			
			shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.passiveShield, ertank.passiveShield];
			
			weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f\n%.0f",weaponDPS, volleyDamage];
		}
		[sensorImage release];
		[damagePattern release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
	[self updatePrice];
}

@end

@implementation POSStatsViewController(Private)

- (void) updatePrice {
	__block int fuelConsumtion;
	__block float fuelDailyCost;
	__block float upgradesCost;
	__block float upgradesDailyCost;
	__block float posCost;
	
	__block EUOperation *operation = [EUOperation operationWithIdentifier:@"POSStatsViewController+UpdatePrice" name:NSLocalizedString(@"Updating Price", nil)];
	POSFittingViewController* aPosFittingViewController = posFittingViewController;
	
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSMutableSet* types = [NSMutableSet set];
		NSMutableDictionary* infrastructureUpgrades = [NSMutableDictionary dictionary];

		@synchronized(posFittingViewController) {
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
		operation.progress = 0.5;
		
		@synchronized(aPosFittingViewController) {
			eufe::ControlTower* controlTower = posFittingViewController.fit.controlTower;
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
		operation.progress = 1.0;

		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			fuelCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
								  fuelConsumtion,
								  [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:fuelDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			
			infrastructureUpgradesCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK (%@ ISK/day)", nil),
													[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesCost] numberStyle:NSNumberFormatterDecimalStyle],
													[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:upgradesDailyCost] numberStyle:NSNumberFormatterDecimalStyle]];
			posCostLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil),
								 [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithFloat:posCost] numberStyle:NSNumberFormatterDecimalStyle]];
		}
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end
