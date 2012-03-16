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

#import "eufe.h"

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
@synthesize shieldBoost;
@synthesize armorRepair;
@synthesize hullRepair;

@synthesize weaponDPSLabel;
@synthesize volleyDamageLabel;

@synthesize targetsLabel;
@synthesize targetRangeLabel;
@synthesize scanResLabel;
@synthesize sensorStrLabel;
@synthesize speedLabel;
@synthesize alignTimeLabel;
@synthesize signatureLabel;
@synthesize cargoLabel;
@synthesize sensorImageView;

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


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
	else
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
	self.shieldBoost = nil;
	self.armorRepair = nil;
	self.hullRepair = nil;
	
	self.weaponDPSLabel = nil;
	self.volleyDamageLabel = nil;
	
	self.targetsLabel = nil;
	self.targetRangeLabel = nil;
	self.scanResLabel = nil;
	self.sensorStrLabel = nil;
	self.speedLabel = nil;
	self.alignTimeLabel = nil;
	self.signatureLabel = nil;
	self.cargoLabel = nil;
	self.sensorImageView = nil;
}

- (void) viewWillAppear:(BOOL)animated {
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
	[shieldBoost release];
	[armorRepair release];
	[hullRepair release];
	
	[weaponDPSLabel release];
	[volleyDamageLabel release];
	
	[targetsLabel release];
	[targetRangeLabel release];
	[scanResLabel release];
	[sensorStrLabel release];
	[speedLabel release];
	[alignTimeLabel release];
	[signatureLabel release];
	[cargoLabel release];
	[sensorImageView release];
	
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
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"StatsViewController+Update"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(posFittingViewController) {
			
			boost::shared_ptr<eufe::ControlTower> controlTower = posFittingViewController.fit.controlTower;
			
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
			
			damagePattern = [posFittingViewController.damagePattern retain];
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
			
			ehpLabel.text = [NSString stringWithFormat:@"EHP: %@", [NSString stringWithResource:ehp unit:nil]];
			
			shieldBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair];
			armorRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair];
			hullRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair];
			shieldRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.passiveShield, ertank.passiveShield];
			
			weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f DPS",weaponDPS];
			volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f",volleyDamage];
		}
		[sensorImage release];
		[damagePattern release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end