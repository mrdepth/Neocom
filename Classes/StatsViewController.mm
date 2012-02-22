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
#import "Fit.h"

#import "eufe.h"

@implementation StatsViewController
@synthesize fittingViewController;
@synthesize scrollView;
@synthesize contentView;

@synthesize powerGridLabel;
@synthesize cpuLabel;
@synthesize droneBayLabel;
@synthesize droneBandwidthLabel;
@synthesize calibrationLabel;
@synthesize turretsLabel;
@synthesize launchersLabel;
@synthesize dronesLabel;

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

@synthesize shieldHPLabel;
@synthesize armorHPLabel;
@synthesize hullHPLabel;
@synthesize ehpLabel;

@synthesize shieldSustainedRecharge;
@synthesize shieldReinforcedBoost;
@synthesize shieldSustainedBoost;
@synthesize armorReinforcedRepair;
@synthesize armorSustainedRepair;
@synthesize hullReinforcedRepair;
@synthesize hullSustainedRepair;

@synthesize capacitorCapacityLabel;
@synthesize capacitorStateLabel;
@synthesize capacitorRechargeTimeLabel;
@synthesize capacitorDeltaLabel;

@synthesize weaponDPSLabel;
@synthesize droneDPSLabel;
@synthesize volleyDamageLabel;
@synthesize dpsLabel;

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
}

- (void) viewWillAppear:(BOOL)animated {
	[self update];
}


- (void)dealloc {
	[scrollView release];
	[contentView release];
	
	[powerGridLabel release];
	[cpuLabel release];
	[droneBayLabel release];
	[droneBandwidthLabel release];
	[calibrationLabel release];
	[turretsLabel release];
	[launchersLabel release];
	[dronesLabel release];
	
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
	
	[shieldHPLabel release];
	[armorHPLabel release];
	[hullHPLabel release];
	[ehpLabel release];
	
	[shieldSustainedRecharge release];
	[shieldReinforcedBoost release];
	[shieldSustainedBoost release];
	[armorReinforcedRepair release];
	[armorSustainedRepair release];
	[hullReinforcedRepair release];
	[hullSustainedRepair release];
	
	[capacitorCapacityLabel release];
	[capacitorStateLabel release];
	[capacitorRechargeTimeLabel release];
	[capacitorDeltaLabel release];
	
	[weaponDPSLabel release];
	[droneDPSLabel release];
	[volleyDamageLabel release];
	[dpsLabel release];
	
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

/*- (void) update {
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
	NSMutableDictionary *resistances = [NSMutableDictionary dictionary];
	NSMutableDictionary *hp = [NSMutableDictionary dictionary];
	__block float ehp;
	NSMutableDictionary *rtank = [NSMutableDictionary dictionary];
	NSMutableDictionary *stank = [NSMutableDictionary dictionary];
	NSMutableDictionary *ertank = [NSMutableDictionary dictionary];
	NSMutableDictionary *estank = [NSMutableDictionary dictionary];
	
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
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"StatsViewController+Update"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		totalPG = fit.totalPowerGrid;
		usedPG = fit.powerGridUsed;
		
		totalCPU = fit.totalCPU;
		usedCPU = fit.cpuUsed;
		
		totalCalibration = fit.totalCalibration;
		usedCalibration = fit.calibrationUsed;
		
		maxActiveDrones = [[fit.extraAttributes valueForKey:@"maxActiveDrones"] integerValue];
		activeDrones = fit.activeDrones;
		
		
		totalBandwidth = fit.totalDroneBandwidth;
		usedBandwidth = fit.droneBandwidthUsed;
		
		totalDB = fit.totalDroneBay;
		usedDB = fit.droneBayUsed;
		
		usedTurretHardpoints = [fit usedHardpointsWithType:EVEFittingModuleHardpointTurret];
		totalTurretHardpoints = [fit hardpointsWithType:EVEFittingModuleHardpointTurret];
		usedMissileHardpoints = [fit usedHardpointsWithType:EVEFittingModuleHardpointMissile];
		totalMissileHardpoints = [fit hardpointsWithType:EVEFittingModuleHardpointMissile];
		
		[resistances addEntriesFromDictionary:fit.resistances];
		
		[hp addEntriesFromDictionary:fit.hp];
		ehp = [[fit.ehp valueForKey:@"shield"] floatValue] + [[fit.ehp valueForKey:@"armor"] floatValue] + [[fit.ehp valueForKey:@"hull"] floatValue];
		
		[rtank addEntriesFromDictionary:fit.tank];
		[stank addEntriesFromDictionary:fit.sustainableTank];
		[ertank addEntriesFromDictionary:fit.effectiveTank];
		[estank addEntriesFromDictionary:fit.effectiveSustainableTank];
		
		capCapacity = fit.capCapacity;
		capStable = fit.capStable;
		capState = fit.capState;
		capacitorRechargeTime = [[fit.ship.itemModifiedAttributes valueForKey:@"rechargeRate"] floatValue] / 1000.0;
		delta = fit.capRecharge - fit.capUsed;
		
		weaponDPS = fit.weaponDPS;
		droneDPS = fit.droneDPS;
		volleyDamage = fit.weaponVolley;
		dps = fit.totalDPS;
		
		targets = fit.maxTargets;
		targetRange = fit.maxTargetRange / 1000.0;
		scanRes = [[fit.ship.itemModifiedAttributes valueForKey:@"scanResolution"] floatValue];
		sensorStr = fit.scanStrength;
		speed = fit.velocity;
		alignTime = fit.alignTime;
		signature =[[fit.ship.itemModifiedAttributes valueForKey:@"signatureRadius"] floatValue];
		cargo =[[fit.ship.itemModifiedAttributes valueForKey:@"capacity"] floatValue];
		sensorImage = [[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", fit.scanType]] retain];
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			
			if (usedCalibration > totalCalibration)
				calibrationLabel.textColor = [UIColor redColor];
			else
				calibrationLabel.textColor = [UIColor whiteColor];
			
			dronesLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				dronesLabel.textColor = [UIColor redColor];
			else
				dronesLabel.textColor = [UIColor whiteColor];

			droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			
			turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			
			NSArray *resistanceLabels = [NSArray arrayWithObjects:shieldEMLabel, shieldThermalLabel, shieldKineticLabel, shieldExplosiveLabel,
										 armorEMLabel, armorThermalLabel, armorKineticLabel, armorExplosiveLabel,
										 hullEMLabel, hullThermalLabel, hullKineticLabel, hullExplosiveLabel, nil];
			
			NSArray *resistanceKeys = [NSArray arrayWithObjects:@"shield.em", @"shield.thermal", @"shield.kinetic", @"shield.explosive",
									   @"armor.em", @"armor.thermal", @"armor.kinetic", @"armor.explosive",
									   @"hull.em", @"hull.thermal", @"hull.kinetic", @"hull.explosive", nil];
			for (int i = 0; i < 12; i++) {
				ProgressLabel *label = [resistanceLabels objectAtIndex:i];
				float resist = [[resistances valueForKeyPath:[resistanceKeys objectAtIndex:i]] floatValue];
				label.progress = resist;
				label.text = [NSString stringWithFormat:@"%.1f%%", resist * 100];
			}

			shieldHPLabel.text = [NSString stringWithResource:[[hp valueForKey:@"shield"] floatValue] unit:nil];
			armorHPLabel.text = [NSString stringWithResource:[[hp valueForKey:@"armor"] floatValue] unit:nil];
			hullHPLabel.text = [NSString stringWithResource:[[hp valueForKey:@"hull"] floatValue] unit:nil];
			
			ehpLabel.text = [NSString stringWithFormat:@"EHP: %@", [NSString stringWithResource:ehp unit:nil]];

			shieldReinforcedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[rtank valueForKey:@"shieldRepair"] floatValue], [[ertank valueForKey:@"shieldRepair"] floatValue]];
			shieldSustainedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[stank valueForKey:@"shieldRepair"] floatValue], [[estank valueForKey:@"shieldRepair"] floatValue]];
			armorReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[rtank valueForKey:@"armorRepair"] floatValue], [[ertank valueForKey:@"armorRepair"] floatValue]];
			armorSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[stank valueForKey:@"armorRepair"] floatValue], [[estank valueForKey:@"armorRepair"] floatValue]];
			hullReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[rtank valueForKey:@"hullRepair"] floatValue], [[ertank valueForKey:@"hullRepair"] floatValue]];
			hullSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[stank valueForKey:@"hullRepair"] floatValue], [[estank valueForKey:@"hullRepair"] floatValue]];
			shieldSustainedRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", [[stank valueForKey:@"passiveShield"] floatValue], [[estank valueForKey:@"passiveShield"] floatValue]];

			capacitorCapacityLabel.text = [NSString stringWithFormat:@"Total: %@", [NSString stringWithResource:capCapacity unit:@"GJ"]];
			if (capStable)
				capacitorStateLabel.text = [NSString stringWithFormat:@"Stable: %.1f%%", capState];
			else
				capacitorStateLabel.text = [NSString stringWithFormat:@"Lasts %@", [NSString stringWithTimeLeft:capState]];
			capacitorRechargeTimeLabel.text = [NSString stringWithFormat:@"Recharge Time: %@", [NSString stringWithTimeLeft:capacitorRechargeTime]];
			capacitorDeltaLabel.text = [NSString stringWithFormat:@"Delta: %@%.2f GJ/s", delta >= 0.0 ? @"+" : @"", delta];
			
			weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f DPS",weaponDPS];
			droneDPSLabel.text = [NSString stringWithFormat:@"%.0f DPS",droneDPS];
			volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f",volleyDamage];
			dpsLabel.text = [NSString stringWithFormat:@"%.0f",dps];
			
			targetsLabel.text = [NSString stringWithFormat:@"%d", targets];
			targetRangeLabel.text = [NSString stringWithFormat:@"%.0f km", targetRange];
			scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", scanRes];
			sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", sensorStr];
			speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", speed];
			alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", alignTime];
			signatureLabel.text = [NSString stringWithFormat:@"%.0f", signature];
			cargoLabel.text = [NSString stringWithResource:cargo unit:@"m3"];
			sensorImageView.image = sensorImage;
		}
		[sensorImage release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}*/

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
	
	__block EUSingleBlockOperation *operation = [EUSingleBlockOperation operationWithIdentifier:@"StatsViewController+Update"];
	[operation addExecutionBlock:^(void) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		@synchronized(fittingViewController) {
			
			boost::shared_ptr<eufe::Ship> ship = fittingViewController.fit.character.get()->getShip();
			
			totalPG = ship->getTotalPowerGrid();
			usedPG = ship->getPowerGridUsed();
			
			totalCPU = ship->getTotalCpu();
			usedCPU = ship->getCpuUsed();
			
			totalCalibration = ship->getTotalCalibration();
			usedCalibration = ship->getCalibrationUsed();
			
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
					sensorImage = [[UIImage imageNamed:@"Gravimetric.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_LADAR:
					sensorImage = [[UIImage imageNamed:@"Ladar.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_MAGNETOMETRIC:
					sensorImage = [[UIImage imageNamed:@"Magnetometric.png"] retain];
					break;
				case eufe::Ship::SCAN_TYPE_RADAR:
					sensorImage = [[UIImage imageNamed:@"Radar.png"] retain];
					break;
				default:
					sensorImage = [[UIImage imageNamed:@"Multispectral.png"] retain];
					break;
			}
		}
		[pool release];
	}];
	
	[operation setCompletionBlockInCurrentThread:^(void) {
		if (![operation isCancelled]) {
			powerGridLabel.text = [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"];
			powerGridLabel.progress = totalPG > 0 ? usedPG / totalPG : 0;
			cpuLabel.text = [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"];
			cpuLabel.progress = usedCPU > 0 ? usedCPU / totalCPU : 0;
			calibrationLabel.text = [NSString stringWithFormat:@"%d/%d", (int) usedCalibration, (int) totalCalibration];
			
			if (usedCalibration > totalCalibration)
				calibrationLabel.textColor = [UIColor redColor];
			else
				calibrationLabel.textColor = [UIColor whiteColor];
			
			dronesLabel.text = [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones];
			if (activeDrones > maxActiveDrones)
				dronesLabel.textColor = [UIColor redColor];
			else
				dronesLabel.textColor = [UIColor whiteColor];
			
			droneBandwidthLabel.text = [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"];
			droneBandwidthLabel.progress = totalBandwidth > 0 ? usedBandwidth / totalBandwidth : 0;
			droneBayLabel.text = [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"];
			droneBayLabel.progress = totalDB > 0 ? usedDB / totalDB : 0;
			
			turretsLabel.text = [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints];
			launchersLabel.text = [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints];
			
			NSArray *resistanceLabels = [NSArray arrayWithObjects:shieldEMLabel, shieldThermalLabel, shieldKineticLabel, shieldExplosiveLabel,
										 armorEMLabel, armorThermalLabel, armorKineticLabel, armorExplosiveLabel,
										 hullEMLabel, hullThermalLabel, hullKineticLabel, hullExplosiveLabel, nil];
			
			float resistanceValues[] = {resistances.shield.em, resistances.shield.thermal, resistances.shield.kinetic, resistances.shield.explosive,
										resistances.armor.em, resistances.armor.thermal, resistances.armor.kinetic, resistances.armor.explosive,
										resistances.hull.em, resistances.hull.thermal, resistances.hull.kinetic, resistances.hull.explosive};
			for (int i = 0; i < 12; i++) {
				ProgressLabel *label = [resistanceLabels objectAtIndex:i];
				float resist = resistanceValues[i];
				label.progress = resist;
				label.text = [NSString stringWithFormat:@"%.1f%%", resist * 100];
			}
			
			shieldHPLabel.text = [NSString stringWithResource:hp.shield unit:nil];
			armorHPLabel.text = [NSString stringWithResource:hp.armor unit:nil];
			hullHPLabel.text = [NSString stringWithResource:hp.hull unit:nil];
			
			ehpLabel.text = [NSString stringWithFormat:@"EHP: %@", [NSString stringWithResource:ehp unit:nil]];
			
			shieldReinforcedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair];
			shieldSustainedBoost.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.shieldRepair, estank.shieldRepair];
			armorReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair];
			armorSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.armorRepair, estank.armorRepair];
			hullReinforcedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair];
			hullSustainedRepair.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.hullRepair, estank.hullRepair];
			shieldSustainedRecharge.text = [NSString stringWithFormat:@"%.1f\n%.1f", stank.passiveShield, estank.passiveShield];
			
			capacitorCapacityLabel.text = [NSString stringWithFormat:@"Total: %@", [NSString stringWithResource:capCapacity unit:@"GJ"]];
			if (capStable)
				capacitorStateLabel.text = [NSString stringWithFormat:@"Stable: %.1f%%", capState];
			else
				capacitorStateLabel.text = [NSString stringWithFormat:@"Lasts %@", [NSString stringWithTimeLeft:capState]];
			capacitorRechargeTimeLabel.text = [NSString stringWithFormat:@"Recharge Time: %@", [NSString stringWithTimeLeft:capacitorRechargeTime]];
			capacitorDeltaLabel.text = [NSString stringWithFormat:@"Delta: %@%.2f GJ/s", delta >= 0.0 ? @"+" : @"", delta];
			
			weaponDPSLabel.text = [NSString stringWithFormat:@"%.0f DPS",weaponDPS];
			droneDPSLabel.text = [NSString stringWithFormat:@"%.0f DPS",droneDPS];
			volleyDamageLabel.text = [NSString stringWithFormat:@"%.0f",volleyDamage];
			dpsLabel.text = [NSString stringWithFormat:@"%.0f",dps];
			
			targetsLabel.text = [NSString stringWithFormat:@"%d", targets];
			targetRangeLabel.text = [NSString stringWithFormat:@"%.0f km", targetRange];
			scanResLabel.text = [NSString stringWithFormat:@"%.0f mm", scanRes];
			sensorStrLabel.text = [NSString stringWithFormat:@"%.0f", sensorStr];
			speedLabel.text = [NSString stringWithFormat:@"%.0f m/s", speed];
			alignTimeLabel.text = [NSString stringWithFormat:@"%.1f s", alignTime];
			signatureLabel.text = [NSString stringWithFormat:@"%.0f", signature];
			cargoLabel.text = [NSString stringWithResource:cargo unit:@"m3"];
			sensorImageView.image = sensorImage;
		}
		[sensorImage release];
	}];
	
	[[EUOperationQueue sharedQueue] addOperation:operation];
}

@end