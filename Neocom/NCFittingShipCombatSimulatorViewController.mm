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

typedef NS_ENUM(NSInteger, NCManeuver) {
	NCManeuverOrbit,
	NCManeuverKeepAtRange
};

@interface NCFittingShipCombatSimulatorViewController()
@property (nonatomic, strong) NSLayoutConstraint* markerConstraint;
@property (nonatomic, strong) CAShapeLayer* axisLayer;
@property (nonatomic, strong) CAShapeLayer* outgoingDpsLayer;
@property (nonatomic, strong) CAShapeLayer* incomingDpsLayer;
@property (nonatomic, strong) CAShapeLayer* markerLayer;
@property (nonatomic, assign) float maxRange;
@property (nonatomic, assign) float falloff;
@property (nonatomic, assign) float fullRange;
@property (nonatomic, assign) float warpScrambleRange;
@property (nonatomic, strong) NSData* outgoingDpsPoints;
@property (nonatomic, strong) NSData* incomingDpsPoints;
@property (nonatomic, strong) NSData* velocityPoints;
@property (nonatomic, assign) float markerPosition;
@property (nonatomic, strong) NSNumberFormatter* dpsNumberFormatter;
@property (nonatomic, assign) BOOL needsUpdateState;
@property (nonatomic, assign) BOOL updatingState;
@property (nonatomic, assign) BOOL needsUpdateReport;
@property (nonatomic, assign) BOOL updatingReport;
@property (nonatomic, assign) NCManeuver maneuver;

- (void) reload;
- (void) updateState;
- (void) updateReport;
- (void) setNeedsUpdateState;
- (void) setNeedsUpdateReport;

@end

@implementation NCFittingShipCombatSimulatorViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	id maneuver = self.attacker.engine.userInfo[@"maneuver"];
	if (maneuver)
		self.maneuver = (NCManeuver) [maneuver integerValue];
	else
		self.maneuver = NCManeuverOrbit;
	
	self.dpsNumberFormatter = [[NSNumberFormatter alloc] init];
	[self.dpsNumberFormatter setPositiveFormat:@"#,##0.0"];
	[self.dpsNumberFormatter setGroupingSeparator:@" "];
	[self.dpsNumberFormatter setDecimalSeparator:@"."];
	
	self.axisLayer = [CAShapeLayer layer];
	self.axisLayer.strokeColor = [[UIColor whiteColor] CGColor];
	self.axisLayer.fillColor = [[UIColor clearColor] CGColor];
	self.axisLayer.delegate = self;
	self.axisLayer.needsDisplayOnBoundsChange = YES;
	self.axisLayer.zPosition = 10;
	
	self.outgoingDpsLayer = [CAShapeLayer layer];
	self.outgoingDpsLayer.strokeColor = [[UIColor orangeColor] CGColor];
	self.outgoingDpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.outgoingDpsLayer.delegate = self;
	self.outgoingDpsLayer.needsDisplayOnBoundsChange = YES;

	self.incomingDpsLayer = [CAShapeLayer layer];
	self.incomingDpsLayer.strokeColor = [[UIColor redColor] CGColor];
	self.incomingDpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.incomingDpsLayer.delegate = self;
	self.incomingDpsLayer.needsDisplayOnBoundsChange = YES;

	[self.canvasView.layer addSublayer:self.axisLayer];
	[self.canvasView.layer addSublayer:self.outgoingDpsLayer];
	[self.canvasView.layer addSublayer:self.incomingDpsLayer];
	self.axisLayer.frame = self.canvasView.layer.bounds;
	self.outgoingDpsLayer.frame = self.canvasView.layer.bounds;
	self.incomingDpsLayer.frame = self.canvasView.layer.bounds;
	
	self.markerLayer = [CAShapeLayer layer];
	self.markerLayer.frame = self.markerView.layer.bounds;
	self.markerLayer.strokeColor = [[UIColor yellowColor] CGColor];
	self.markerLayer.fillColor = [[UIColor clearColor] CGColor];
	self.markerLayer.lineDashPattern = @[@4, @4];
	self.markerLayer.delegate = self;
	self.markerLayer.needsDisplayOnBoundsChange = YES;
	[self.markerView.layer addSublayer:self.markerLayer];
	
	[self reload];
}

- (void) dealloc {
	self.outgoingDpsLayer.delegate = nil;
	self.incomingDpsLayer.delegate = nil;
	self.axisLayer.delegate = nil;
	self.markerLayer.delegate = nil;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (self.outgoingDpsLayer.bounds.size.width != self.canvasView.bounds.size.width ||
		self.incomingDpsLayer.bounds.size.width != self.canvasView.bounds.size.width)
		[self setNeedsUpdateState];
	
	self.outgoingDpsLayer.frame = self.canvasView.bounds;
	self.incomingDpsLayer.frame = self.canvasView.bounds;
	self.axisLayer.frame = self.canvasView.bounds;
	self.markerLayer.frame = self.markerView.layer.bounds;
}

- (void) displayLayer:(CALayer *)layer {
//	if ([self needsUpdate])
//		[self update];

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
	else if (layer == self.outgoingDpsLayer && self.outgoingDpsPoints) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.outgoingDpsPoints bytes] count:self.outgoingDpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.outgoingDpsLayer.path = path.CGPath;
	}
	else if (layer == self.incomingDpsLayer && self.incomingDpsPoints) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.incomingDpsPoints bytes] count:self.incomingDpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.incomingDpsLayer.path = path.CGPath;
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
	[self setNeedsUpdateState];
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
}

- (IBAction)onTap:(UITapGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
}

- (IBAction)onSwap:(id)sender {
	NCShipFit* attacker = self.target;
	NCShipFit* target = self.attacker;
	self.attacker = attacker;
	self.target = target;
	[self reload];
}

- (IBAction)onManeuver:(UITapGestureRecognizer*) recognizer {
	UIAlertController* controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Orbit", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.maneuver = NCManeuverOrbit;
		self.attacker.engine.userInfo[@"maneuver"] = @(NCManeuverOrbit);
		_markerPosition = -1;
		[self setNeedsUpdateState];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Keep at Range", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		self.maneuver = NCManeuverKeepAtRange;
		self.attacker.engine.userInfo[@"maneuver"] = @(NCManeuverKeepAtRange);
		_markerPosition = -1;
		[self setNeedsUpdateState];
	}]];

	[controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		controller.modalPresentationStyle = UIModalPresentationPopover;
		[self presentViewController:controller animated:YES completion:nil];
		controller.popoverPresentationController.sourceView = recognizer.view;
		controller.popoverPresentationController.sourceRect = [recognizer.view bounds];
	}
	else
		[self presentViewController:controller animated:YES completion:nil];

}

#pragma mark - Private

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
	[self setNeedsUpdateReport];
}

- (void) reload {
	__block float maxVelocity = 0;
	__block NSString* targetName;
	__block NSString* attackerName;
	__block float optimalDPS = 0;
	__block UIImage* warpScramblerImage;
	[self.attacker.engine performBlockAndWait:^{
		auto pilot = self.attacker.pilot;
		auto ship = pilot->getShip();
		float weaponDPS = 0;
		float maxRange = 0;
		float falloff = 0;
		float warpScrambleRange = 0;
		int32_t warpScramblerTypeID = 0;
		for (const auto& module: ship->getModules()) {
			float dps = module->getDps();
			if (dps > 0) {
				weaponDPS += dps;
				maxRange += module->getMaxRange() * dps;
				falloff += module->getFalloff() * dps;
			}
			if (module->hasAttribute(eufe::WARP_SCRAMBLE_STRENGTH_ATTRIBUTE_ID) || module->hasAttribute(eufe::WARP_SCRAMBLE_STRENGTH_HIDDEN_ATTRIBUTE_ID)) {
				if (module->getMaxRange() > warpScrambleRange) {
					warpScrambleRange = module->getMaxRange();
					warpScramblerTypeID = module->getTypeID();
				}
			}
		}
		if (weaponDPS > 0) {
			maxRange /= weaponDPS;
			falloff /= weaponDPS;
		}
		self.maxRange = maxRange;
		self.falloff = falloff;
		self.fullRange = self.maxRange + self.falloff * 2;
		self.warpScrambleRange = warpScrambleRange;
		
		if (warpScramblerTypeID)
			warpScramblerImage = [self.attacker.engine.databaseManagedObjectContext invTypeWithTypeID:warpScramblerTypeID].icon.image.image;
		
		maxVelocity = ship->getVelocity();
		if (self.fullRange == 0) {
			self.fullRange = ceil(ship->getOrbitRadiusWithTransverseVelocity(ship->getVelocity() * 0.95) * 1.5 / 1000) * 1000;
		}
		if (self.fullRange == 0)
			self.fullRange = 40000;
		
		if (self.attacker.typeID == self.target.typeID) {
			//targetName = [NSString stringWithFormat:@"%@ vs %@", self.attacker.loadoutName, self.target.loadoutName];
			attackerName = self.attacker.loadoutName.length > 0 ? self.attacker.loadoutName : NSLocalizedString(@"Unnamed", nil);
			targetName = self.target.loadoutName.length > 0 ? self.target.loadoutName : NSLocalizedString(@"Unnamed", nil);
		}
		else {
			NCDBInvType* attacker = [self.attacker.engine.databaseManagedObjectContext invTypeWithTypeID:self.attacker.typeID];
			NCDBInvType* target = [self.attacker.engine.databaseManagedObjectContext invTypeWithTypeID:self.target.typeID];
			attackerName = attacker.typeName;
			targetName = target.typeName;
		}
		
		auto attacker = self.attacker.pilot->getShip();
		auto target = self.target.pilot->getShip();

		float attackerOptimalDPS = attacker->getWeaponDps() + attacker->getDroneDps();
		float targetOptimalDPS = target->getWeaponDps() + target->getDroneDps();
		optimalDPS = std::max(attackerOptimalDPS, targetOptimalDPS);
	}];
	self.dpsAxisLabel.text = [NSString stringWithFormat:@"%@ DPS", [NSNumberFormatter neocomLocalizedStringFromInteger:optimalDPS]];
	
	NSMutableAttributedString* s = [NSMutableAttributedString new];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:attackerName attributes:@{NSForegroundColorAttributeName:[UIColor orangeColor]}]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@" vs ", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:targetName attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
	
	self.targetLabel.attributedText = s;
	
	self.velocitySlider.minimumValue = 0;
	self.velocitySlider.maximumValue = maxVelocity;
	self.velocitySlider.value = maxVelocity;
	self.maxVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocity]];
	
	_markerPosition = -1;
	[self onChangeVelocity:self.velocitySlider];
	
	if (self.markerConstraint)
		[self.contentView removeConstraint:self.markerConstraint];

	if (self.fullRange >= self.warpScrambleRange) {
		if (self.warpScrambleRange > 0) {
			NSTextAttachment* icon = [NSTextAttachment new];
			icon.image = warpScramblerImage;
			icon.bounds = CGRectMake(0, -11 -self.marker1TitleLabel.font.descender, 22, 22);
			self.marker1TitleLabel.attributedText = [NSAttributedString attributedStringWithAttachment:icon];
			//self.marker1TitleLabel.text = NSLocalizedString(@"Warp Disrupt", nil);
			self.marker1Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.warpScrambleRange]];
			self.marker1Label.hidden = NO;
			self.marker1TitleLabel.hidden = NO;
		}
		else {
			self.marker1Label.hidden = YES;
			self.marker1TitleLabel.hidden = YES;
		}
		if (self.falloff > 0) {
			self.marker2TitleLabel.text = NSLocalizedString(@"Falloff x2", nil);
			self.marker2TitleLabel.hidden = NO;
		}
		else
			self.marker2TitleLabel.hidden = YES;
		self.marker2Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
		
		self.markerConstraint = [NSLayoutConstraint constraintWithItem:self.marker1AuxiliaryView
															 attribute:NSLayoutAttributeWidth
															 relatedBy:NSLayoutRelationEqual
																toItem:self.contentView
															 attribute:NSLayoutAttributeWidth
															multiplier:self.warpScrambleRange / self.fullRange
															  constant:0];
		[self.contentView addConstraint:self.markerConstraint];
		
	}
	else {
		if (self.fullRange > 0) {
			self.marker1TitleLabel.text = NSLocalizedString(@"Falloff x2", nil);
			self.marker1Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
			self.marker1Label.hidden = NO;
			self.marker1TitleLabel.hidden = NO;
		}
		else {
			self.marker1Label.hidden = YES;
			self.marker1TitleLabel.hidden = YES;
		}
		
		NSTextAttachment* icon = [NSTextAttachment new];
		icon.image = warpScramblerImage;
		icon.bounds = CGRectMake(0, -11 -self.marker2TitleLabel.font.descender, 22, 22);
		self.marker2TitleLabel.attributedText = [NSAttributedString attributedStringWithAttachment:icon];

		
		//self.marker2TitleLabel.text = NSLocalizedString(@"Warp Disrupt", nil);
		self.marker2Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.warpScrambleRange]];
		
		self.markerConstraint = [NSLayoutConstraint constraintWithItem:self.marker1AuxiliaryView
															 attribute:NSLayoutAttributeWidth
															 relatedBy:NSLayoutRelationEqual
																toItem:self.contentView
															 attribute:NSLayoutAttributeWidth
															multiplier:self.fullRange / self.warpScrambleRange
															  constant:0];
		[self.contentView addConstraint:self.markerConstraint];
	}
	[self.axisLayer setNeedsDisplay];
}

- (void) updateState {
	if (self.updatingState)
		return;
	if (self.needsUpdateState) {
		self.needsUpdateState = NO;
		self.updatingState = YES;
		
		float velocity = self.velocitySlider.value;
		BOOL tracking = self.velocitySlider.tracking;
		NCManeuver maneuver = self.maneuver;
		__block BOOL unstable = YES;
		[self.activityIndicator startAnimating];
		[self.attacker.engine performBlock:^{
			CGPoint maxDPS = CGPointZero;

			auto attacker = self.attacker.pilot->getShip();
			auto target = self.target.pilot->getShip();
			eufe::CombatSimulator simulator(attacker, target);
			
			float axisRange = std::max(self.warpScrambleRange, self.fullRange);
			
			int n = self.canvasView.bounds.size.width / (tracking ? 6 : 2) - 1;
			CGPoint *outgoingDpsPoints = new CGPoint[n];
			CGPoint *incomingDpsPoints = new CGPoint[n];
			float dx = axisRange / (n + 1);
			float x = dx;
			float attackerOptimalDPS = attacker->getWeaponDps() + attacker->getDroneDps();
			float targetOptimalDPS = target->getWeaponDps() + target->getDroneDps();
			attackerOptimalDPS = std::max(attackerOptimalDPS, targetOptimalDPS);
			targetOptimalDPS = std::max(attackerOptimalDPS, targetOptimalDPS);
			
			eufe::CombatSimulator::OrbitState orbitState(attacker, target, 0, velocity);
			eufe::CombatSimulator::KeepAtRangeState keepAtRangeState(attacker, target, 0);
			
			
			for (int i = 0; i < n; i++) {
				BOOL b;
				if (maneuver == NCManeuverOrbit) {
					orbitState.setOrbitRadius(x);
					simulator.setState(orbitState);
					b = orbitState.targetVelocity() >= orbitState.attackerVelocity();
				}
				else {
					keepAtRangeState.setRange(x);
					simulator.setState(keepAtRangeState);
					b = keepAtRangeState.targetVelocity() >= keepAtRangeState.attackerVelocity();
				}
				
				outgoingDpsPoints[i] = CGPointMake(x / axisRange, attackerOptimalDPS > 0 ? (static_cast<float>(simulator.outgoingDps())) / attackerOptimalDPS : 0);
				incomingDpsPoints[i] = CGPointMake(x / axisRange, targetOptimalDPS > 0 ? (static_cast<float>(simulator.incomingDps())) / targetOptimalDPS : 0);
				
				BOOL g = outgoingDpsPoints[i].y >= maxDPS.y;
				if ((unstable && !b) || (!b && g) || (unstable && b && g)) {
					if (!b)
						unstable = NO;
					maxDPS = outgoingDpsPoints[i];
				}
				
				x += dx;
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.activityIndicator stopAnimating];
				self.outgoingDpsPoints = [NSData dataWithBytesNoCopy:outgoingDpsPoints length:sizeof(CGPoint) * n freeWhenDone:YES];
				self.incomingDpsPoints = [NSData dataWithBytesNoCopy:incomingDpsPoints length:sizeof(CGPoint) * n freeWhenDone:YES];
				
				if (self.markerPosition < 0)
					self.markerPosition = maxDPS.x;
				self.updatingState = NO;
				[self.outgoingDpsLayer setNeedsDisplay];
				[self.incomingDpsLayer setNeedsDisplay];
				
				if (self.needsUpdateState) {
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateState) object:nil];
					[self performSelector:@selector(updateState) withObject:nil afterDelay:0];
				}
				[self setNeedsUpdateReport];
			});
		}];
	}
}

- (void) updateReport {
	if (self.updatingReport)
		return;
	if (self.needsUpdateReport) {
		self.needsUpdateReport = NO;
		self.updatingReport = YES;
		
		float velocity = self.velocitySlider.value;
		NCManeuver maneuver = self.maneuver;

		[self.attacker.engine performBlock:^{
			auto attacker = self.attacker.pilot->getShip();
			auto target = self.target.pilot->getShip();
			
			eufe::CombatSimulator simulator(attacker, target);
			float axisRange = std::max(self.warpScrambleRange, self.fullRange);
			float range = std::max(axisRange * self.markerPosition, 0.0f);

			float attackerVelocity = 0;
			float targetVelocity = 0;
			
			if (maneuver == NCManeuverOrbit) {
				eufe::CombatSimulator::OrbitState orbitState(attacker, target, range, velocity);
				simulator.setState(orbitState);
				attackerVelocity = orbitState.attackerVelocity();
				targetVelocity = orbitState.targetVelocity();
			}
			else {
				eufe::CombatSimulator::KeepAtRangeState keepAtRangeState(attacker, target, range);
				simulator.setState(keepAtRangeState);
				attackerVelocity = keepAtRangeState.attackerVelocity();
				targetVelocity = keepAtRangeState.targetVelocity();
			}
			
			float outgoingDps = simulator.outgoingDps();
			float incomingDps = simulator.incomingDps();
			
			float timeToKill = simulator.timeToKill();
			float timeToDie = simulator.timeToDie();
			
			
			float attackerCapLastsTime = attacker->isCapStable() ? -1 : attacker->getCapLastsTime();
			float attackerModulesLifeTime = simulator.attackerModulesLifeTime();

			dispatch_async(dispatch_get_main_queue(), ^{
				NSMutableAttributedString* report = [NSMutableAttributedString new];
				
				if (std::isfinite(timeToKill) &&  timeToKill <= timeToDie) {
					[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Target will be destroyed in %@. ", nil), [NSString stringWithTimeLeft:timeToKill]] attributes:@{NSForegroundColorAttributeName:[UIColor greenColor]}]];
					if (attackerCapLastsTime > 0 && attackerCapLastsTime < timeToKill)
						[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your capacitor will deplete in %@. ", nil), [NSString stringWithTimeLeft:attackerCapLastsTime]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
					if (attackerModulesLifeTime > 0 && attackerModulesLifeTime < timeToKill) {
						[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your modules will be burned in %@. ", nil), [NSString stringWithTimeLeft:attackerModulesLifeTime]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
					}
				}
				else if (std::isfinite(timeToDie) && timeToDie < timeToKill) {
					[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"You will be destroyed in %@. ", nil), [NSString stringWithTimeLeft:timeToDie]] attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}]];
				}
				else {
					[report appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Your DPS is not sufficient to defeat the target. ", nil) attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
				}
				if (attackerVelocity < targetVelocity) {
					if (maneuver == NCManeuverOrbit)
						[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your speed is not sufficient to sustain orbit of the target (%@ < %@ m/s). ", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:attackerVelocity], [NSNumberFormatter neocomLocalizedStringFromInteger:targetVelocity]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
					else
						[report appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Your speed is not sufficient to sustain range to the target (%@ < %@ m/s). ", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:attackerVelocity], [NSNumberFormatter neocomLocalizedStringFromInteger:targetVelocity]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
				}
				self.reportLabel.attributedText = report;
				
				self.orbitLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:range]];
				self.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.velocitySlider.value]];
				
				self.outgoingDpsLabel.text = [self.dpsNumberFormatter stringFromNumber:@(outgoingDps)];
				self.incomingDpsLabel.text = [self.dpsNumberFormatter stringFromNumber:@(incomingDps)];
				self.updatingReport = NO;
				if (self.needsUpdateReport) {
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateReport) object:nil];
					[self performSelector:@selector(updateReport) withObject:nil afterDelay:0];
				}
			});
		}];
	}
}

- (void) setNeedsUpdateState {
	self.needsUpdateState = YES;
	if (self.updatingState)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateState) object:nil];
	[self performSelector:@selector(updateState) withObject:nil afterDelay:0];
}

- (void) setNeedsUpdateReport {
	self.needsUpdateReport = YES;
	if (self.updatingReport)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateReport) object:nil];
	[self performSelector:@selector(updateReport) withObject:nil afterDelay:0];
}

- (void) setManeuver:(NCManeuver)maneuver {
	_maneuver = maneuver;
	if (maneuver == NCManeuverOrbit) {
		self.maneuverLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Orbit", nil) attributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
		self.maneuverRangeTitleLabel.text = NSLocalizedString(@"Orbit Radius:", nil);
		for (id view in self.velocitySlider.superview.subviews) {
			if ([view respondsToSelector:@selector(setEnabled:)])
				[view setEnabled:YES];
		}
	}
	else {
		self.maneuverLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Keep at Range", nil) attributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
		self.maneuverRangeTitleLabel.text = NSLocalizedString(@"Range:", nil);
		for (id view in self.velocitySlider.superview.subviews) {
			if ([view respondsToSelector:@selector(setEnabled:)])
				[view setEnabled:NO];
		}
	}
}

@end
