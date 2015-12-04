//
//  NCFittingShipCombatSimulatorViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 02.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "NCFittingShipCombatSimulatorViewController.h"
#include <initializer_list>
#include <vector>
#import "NCShipFit.h"
#import "NSNumberFormatter+Neocom.h"
#import <algorithm>
#import "NSString+Neocom.h"
#import "NCFittingEngine.h"
#import "NCDatabase.h"
#import "NSManagedObjectContext+NCDatabase.h"

@interface NCFittingShipCombatSimulatorViewController()
@property (nonatomic, strong) CAShapeLayer* axisLayer;
@property (nonatomic, strong) CAShapeLayer* dealtDpsLayer;
@property (nonatomic, strong) CAShapeLayer* receivedDpsLayer;
//@property (nonatomic, strong) CAShapeLayer* velocityLayer;
@property (nonatomic, strong) CAShapeLayer* markerLayer;
@property (nonatomic, assign) float maxRange;
@property (nonatomic, assign) float falloff;
@property (nonatomic, assign) float fullRange;
@property (nonatomic, assign) float warpScrambleRange;
@property (nonatomic, strong) NSData* dealtDpsPoints;
@property (nonatomic, strong) NSData* receivedDpsPoints;
@property (nonatomic, strong) NSData* velocityPoints;
@property (nonatomic, assign) float markerPosition;
@property (nonatomic, strong) NSNumberFormatter* dpsNumberFormatter;
- (void) update;
- (BOOL) needsUpdate;
- (void) setNeedsUpdate;
@end

@implementation NCFittingShipCombatSimulatorViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.dpsNumberFormatter = [[NSNumberFormatter alloc] init];
	[self.dpsNumberFormatter setPositiveFormat:@"#,##0.0"];
	[self.dpsNumberFormatter setGroupingSeparator:@" "];
	[self.dpsNumberFormatter setDecimalSeparator:@"."];
	
	self.axisLayer = [CAShapeLayer layer];
	self.axisLayer.strokeColor = [[UIColor whiteColor] CGColor];
	self.axisLayer.fillColor = [[UIColor clearColor] CGColor];
	self.axisLayer.delegate = self;
	self.axisLayer.needsDisplayOnBoundsChange = YES;
	
	self.dealtDpsLayer = [CAShapeLayer layer];
	self.dealtDpsLayer.strokeColor = [[UIColor orangeColor] CGColor];
	self.dealtDpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.dealtDpsLayer.delegate = self;
	self.dealtDpsLayer.needsDisplayOnBoundsChange = YES;

	self.receivedDpsLayer = [CAShapeLayer layer];
	self.receivedDpsLayer.strokeColor = [[UIColor redColor] CGColor];
	self.receivedDpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.receivedDpsLayer.delegate = self;
	self.receivedDpsLayer.needsDisplayOnBoundsChange = YES;

	[self.canvasView.layer addSublayer:self.axisLayer];
	[self.canvasView.layer addSublayer:self.dealtDpsLayer];
	[self.canvasView.layer addSublayer:self.receivedDpsLayer];
	self.axisLayer.frame = self.canvasView.layer.bounds;
	self.dealtDpsLayer.frame = self.canvasView.layer.bounds;
	self.receivedDpsLayer.frame = self.canvasView.layer.bounds;
	
	self.markerLayer = [CAShapeLayer layer];
	self.markerLayer.frame = self.markerView.layer.bounds;
	self.markerLayer.strokeColor = [[UIColor yellowColor] CGColor];
	self.markerLayer.fillColor = [[UIColor clearColor] CGColor];
	self.markerLayer.lineDashPattern = @[@4, @4];
	self.markerLayer.delegate = self;
	self.markerLayer.needsDisplayOnBoundsChange = YES;
	[self.markerView.layer addSublayer:self.markerLayer];
	
	__block float maxVelocity = 0;
	__block NSString* targetName;
	
	[self.attacker.engine performBlockAndWait:^{
		auto pilot = self.attacker.pilot;
		auto ship = pilot->getShip();
		float turretsDPS = 0;
		float maxRange = 0;
		float falloff = 0;
		float warpScrambleRange = 0;
		for (const auto& module: ship->getModules()) {
			if (module->getHardpoint() == eufe::Module::HARDPOINT_TURRET) {
				float dps = module->getDps();
				if (dps > 0) {
					turretsDPS += dps;
					maxRange += module->getMaxRange() * dps;
					falloff += module->getFalloff() * dps;
				}
			}
			if (module->hasAttribute(eufe::WARP_SCRAMBLE_STRENGTH_ATTRIBUTE_ID))
				warpScrambleRange = std::max(warpScrambleRange, module->getMaxRange());
		}
		if (turretsDPS > 0) {
			maxRange /= turretsDPS;
			falloff /= turretsDPS;
		}
		self.maxRange = maxRange;
		self.falloff = falloff;
		self.fullRange = self.maxRange + self.falloff * 2;
		self.warpScrambleRange = warpScrambleRange;
		maxVelocity = ship->getVelocity();
		if (self.fullRange == 0) {
			self.fullRange = ceil(ship->getOrbitRadiusWithTransverseVelocity(ship->getVelocity() * 0.95) * 1.5 / 1000) * 1000;
		}
		NCDBInvType* type = [self.attacker.engine.databaseManagedObjectContext invTypeWithTypeID:self.target.typeID];
		targetName = [NSString stringWithFormat:@"%@ - %@", type.typeName, self.target.loadoutName];
	}];
	self.targetLabel.text = targetName;
	
	self.velocitySlider.minimumValue = 0;
	self.velocitySlider.maximumValue = maxVelocity;
	self.velocitySlider.value = maxVelocity;
	self.maxVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocity]];
	
	self.markerPosition = -1;
	[self onChangeVelocity:self.velocitySlider];
	
	if (self.fullRange >= self.warpScrambleRange) {
		if (self.warpScrambleRange > 0) {
			self.marker1TitleLabel.text = NSLocalizedString(@"Warp Disrupt", nil);
			self.marker1Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.warpScrambleRange]];
		}
		else {
			self.marker1Label.hidden = YES;
			self.marker1TitleLabel.hidden = YES;
		}
		if (self.falloff > 0)
			self.marker2TitleLabel.text = NSLocalizedString(@"Falloff x2", nil);
		else
			self.marker2TitleLabel.hidden = YES;
		self.marker2Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
		
		[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.marker1AuxiliaryView
																	 attribute:NSLayoutAttributeWidth
																	 relatedBy:NSLayoutRelationEqual
																		toItem:self.contentView
																	 attribute:NSLayoutAttributeWidth
																	multiplier:self.warpScrambleRange / self.fullRange
																	  constant:0]];

	}
	else {
		if (self.fullRange > 0) {
			self.marker1TitleLabel.text = NSLocalizedString(@"Falloff x2", nil);
			self.marker1Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
		}
		else {
			self.marker1Label.hidden = YES;
			self.marker1TitleLabel.hidden = YES;
		}

		self.marker2TitleLabel.text = NSLocalizedString(@"Warp Disrupt", nil);
		self.marker2Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.warpScrambleRange]];
		
		[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.marker1AuxiliaryView
																	 attribute:NSLayoutAttributeWidth
																	 relatedBy:NSLayoutRelationEqual
																		toItem:self.contentView
																	 attribute:NSLayoutAttributeWidth
																	multiplier:self.fullRange / self.warpScrambleRange
																	  constant:0]];
	}
}

- (void) dealloc {
	self.dealtDpsLayer.delegate = nil;
	self.receivedDpsLayer.delegate = nil;
	self.axisLayer.delegate = nil;
	self.markerLayer.delegate = nil;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (self.dealtDpsLayer.bounds.size.width != self.canvasView.bounds.size.width ||
		self.receivedDpsLayer.bounds.size.width != self.canvasView.bounds.size.width)
		[self setNeedsUpdate];
	
	self.dealtDpsLayer.frame = self.canvasView.bounds;
	self.receivedDpsLayer.frame = self.canvasView.bounds;
	self.axisLayer.frame = self.canvasView.bounds;
	self.markerLayer.frame = self.markerView.layer.bounds;
}

- (void) displayLayer:(CALayer *)layer {
	if ([self needsUpdate])
		[self update];

	if (layer == self.axisLayer) {
		UIBezierPath* bezierPath = [UIBezierPath bezierPath];
		[bezierPath moveToPoint:CGPointMake(0, 0)];
		[bezierPath addLineToPoint:CGPointMake(0, self.canvasView.bounds.size.height)];
		[bezierPath addLineToPoint:CGPointMake(self.canvasView.bounds.size.width, self.canvasView.bounds.size.height)];
		float axisRange = std::max(self.warpScrambleRange, self.fullRange);
		CGFloat marker1 = std::min(self.warpScrambleRange, self.fullRange) / axisRange * self.canvasView.bounds.size.width;
		for (CGFloat x: {marker1, self.canvasView.bounds.size.width}) {
				[bezierPath moveToPoint:CGPointMake(x, self.canvasView.bounds.size.height)];
				[bezierPath addLineToPoint:CGPointMake(x, self.canvasView.bounds.size.height - 4)];
			}
		
		for (CGFloat y: {(CGFloat) 0.0f, self.canvasView.bounds.size.height / 2}) {
			
			[bezierPath moveToPoint:CGPointMake(0, y)];
			[bezierPath addLineToPoint:CGPointMake(4, y)];
		}
		
		self.axisLayer.path = [bezierPath CGPath];
	}
	else if (layer == self.dealtDpsLayer) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.dealtDpsPoints bytes] count:self.dealtDpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.dealtDpsLayer.path = path.CGPath;
	}
	else if (layer == self.receivedDpsLayer) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.receivedDpsPoints bytes] count:self.receivedDpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.receivedDpsLayer.path = path.CGPath;
	}
	else if (layer == self.markerLayer) {
		UIBezierPath* path = [UIBezierPath bezierPath];
		CGFloat x = CGRectGetMidX(self.markerLayer.bounds);
		[path moveToPoint:CGPointMake(x, 0)];
		[path addLineToPoint:CGPointMake(x, self.markerLayer.bounds.size.height)];
		self.markerLayer.path = [path CGPath];
	}
}

- (IBAction)onChangeVelocity:(id) sender {
	[self setNeedsUpdate];
	CGRect rect = [self.velocitySlider thumbRectForBounds:self.velocitySlider.bounds trackRect:[self.velocitySlider trackRectForBounds:self.velocitySlider.bounds] value:self.velocitySlider.value];
	
	[self.velocityLabelAuxiliaryView.superview removeConstraint:self.velocityLabelConstraint];
	id constraint = [NSLayoutConstraint constraintWithItem:self.velocityLabelAuxiliaryView
												 attribute:NSLayoutAttributeWidth
												 relatedBy:NSLayoutRelationEqual
													toItem:self.velocitySlider
												 attribute:NSLayoutAttributeWidth
												multiplier:CGRectGetMidX(rect) / self.velocitySlider.bounds.size.width
												  constant:0];
	self.velocityLabelConstraint = constraint;
	[self.velocityLabelAuxiliaryView.superview addConstraint:constraint];
}

- (IBAction)onPan:(UIPanGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
	[self update];
}

- (IBAction)onTap:(UITapGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
	[self update];
}

#pragma mark - Private

- (void) update {
	float velocity = self.velocitySlider.value;
	__block CGPoint maxDPS = CGPointZero;
	__block eufe::DamageVector attackerOptimalDPS = 0;
	__block eufe::DamageVector targetOptimalDPS = 0;
	
	__block float dealtDPS = 0;
	__block float receivedDPS = 0;
	__block float orbit = 0;
	__block float timeToKill = 0;
	__block float timeToDie = 0;
	__block float attackerVelocity = 0;
	__block float targetVelocity = 0;
	__block float attackerCapLastsTime = -1;
	__block float targetCapLastsTime = -1;
	
	BOOL tracking = self.velocitySlider.tracking;
	
	[self.attacker.engine performBlockAndWait:^{
		auto attacker = self.attacker.pilot->getShip();
		auto target = self.target.pilot->getShip();
		eufe::CombatSimulator simulator(attacker, target);
		
		float axisRange = std::max(self.warpScrambleRange, self.fullRange);
		
		if (!self.dealtDpsPoints) {
			int n = self.canvasView.bounds.size.width / (tracking ? 6 : 2) - 1;
			CGPoint *dealtDpsPoints = new CGPoint[n];
			CGPoint *receivedDpsPoints = new CGPoint[n];
			float dx = axisRange / (n + 1);
			float x = dx;
			attackerOptimalDPS = attacker->getWeaponDps() + attacker->getDroneDps();
			targetOptimalDPS = target->getWeaponDps() + target->getDroneDps();
			
			eufe::CombatSimulator::State state;
			state.targetPosition = eufe::Point(0,0);
			state.targetVelocity = eufe::Vector(0, target->getVelocity());
			state.attackerVelocity = eufe::Vector(0, velocity);
			
			for (int i = 0; i < n; i++) {
				state.attackerPosition = eufe::Point(x, 0);
				simulator.setState(state);
				
				dealtDpsPoints[i] = CGPointMake(x / axisRange, attackerOptimalDPS > 0 ? (static_cast<float>(simulator.dealtDps())) / attackerOptimalDPS : 0);
				receivedDpsPoints[i] = CGPointMake(x / axisRange, targetOptimalDPS > 0 ? (static_cast<float>(simulator.receivedDps())) / targetOptimalDPS : 0);
				
				if (dealtDpsPoints[i].y >= maxDPS.y)
					maxDPS = dealtDpsPoints[i];
				
				x += dx;
			}
			
			self.dealtDpsPoints = [NSData dataWithBytes:dealtDpsPoints length:sizeof(CGPoint) * n];
			self.receivedDpsPoints = [NSData dataWithBytes:receivedDpsPoints length:sizeof(CGPoint) * n];
			delete[] dealtDpsPoints;
			delete[] receivedDpsPoints;
			
			if (self.markerPosition < 0)
				self.markerPosition = maxDPS.x;
		}
		

		orbit = axisRange * self.markerPosition;
		eufe::CombatSimulator::State state;
		state.targetPosition = eufe::Point(0,0);
		state.targetVelocity = eufe::Vector(0, target->getVelocity());
		state.attackerPosition = eufe::Point(orbit, 0);
		state.attackerVelocity = eufe::Vector(0, velocity);
		
		simulator.setState(state);
		dealtDPS = simulator.dealtDps();
		receivedDPS = simulator.receivedDps();
		
		timeToKill = simulator.timeToKill();
		timeToDie = simulator.timeToDie();
		
		attackerVelocity = std::min(attacker->getMaxVelocityInOrbit(state.range()), velocity);
		targetVelocity = target->getVelocity();
		
		attackerCapLastsTime = attacker->isCapStable() ? -1 : attacker->getCapLastsTime();
		targetCapLastsTime = target->isCapStable() ? -1 : target->getCapLastsTime();
	}];
	NSMutableAttributedString* report = [NSMutableAttributedString new];
	
	if (timeToKill > 0 && timeToKill < timeToDie) {
		[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Target will be destroyed in %@. ", nil), [NSString stringWithTimeLeft:timeToKill]] attributes:@{NSForegroundColorAttributeName:[UIColor greenColor]}]];
		if (attackerCapLastsTime > 0 && attackerCapLastsTime < timeToKill)
			[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your capacitor will deplete in %@. ", nil), [NSString stringWithTimeLeft:attackerCapLastsTime]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
	}
	else if (timeToDie > 0 && timeToDie < timeToKill) {
		[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"You will be destroyed in %@. ", nil), [NSString stringWithTimeLeft:timeToKill]] attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
	}
	else {
		[report appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your DPS is not sufficient to defeat the target. ", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
	}
	if (attackerVelocity < targetVelocity) {
		[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your speed is not sufficient to sustain orbit of the target (%@ < %@ m/s). ", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:attackerVelocity], [NSNumberFormatter neocomLocalizedStringFromInteger:targetVelocity]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
	}
	self.reportLabel.attributedText = report;
	
	self.orbitLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbit]];
	self.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.velocitySlider.value]];
	
	self.dealtDpsLabel.text = [self.dpsNumberFormatter stringFromNumber:@(dealtDPS)];
	self.receivedDpsLabel.text = [self.dpsNumberFormatter stringFromNumber:@(receivedDPS)];
}

- (void) setMarkerPosition:(float)markerPosition {
	_markerPosition = markerPosition;
	[self.markerAuxiliaryView.superview removeConstraint:self.markerViewConstraint];
	id constraint = [NSLayoutConstraint constraintWithItem:self.markerAuxiliaryView
												 attribute:NSLayoutAttributeWidth
												 relatedBy:NSLayoutRelationEqual
													toItem:self.contentView
												 attribute:NSLayoutAttributeWidth
												multiplier:markerPosition >= 0 ? markerPosition : 0
												  constant:0];
	self.markerViewConstraint = constraint;
	[self.markerAuxiliaryView.superview addConstraint:constraint];
}

- (BOOL) needsUpdate {
	return !self.dealtDpsPoints || !self.receivedDpsPoints;
}

- (void) setNeedsUpdate {
	self.dealtDpsPoints = nil;
	self.receivedDpsPoints = nil;
	[self.dealtDpsLayer setNeedsDisplay];
	[self.receivedDpsLayer setNeedsDisplay];
}

@end
