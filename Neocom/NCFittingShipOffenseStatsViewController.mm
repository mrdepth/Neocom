//
//  NCFittingShipOffenseStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 25.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "NCFittingShipOffenseStatsViewController.h"
#include <initializer_list>
#include <vector>
#import "NCShipFit.h"
#import "NSNumberFormatter+Neocom.h"
#import <algorithm>
#import "NCDatabase.h"
#import "NSManagedObjectContext+NCDatabase.h"
#import "NCFittingHullTypePickerViewController.h"

@interface NCFittingShipOffenseStatsViewController()
@property (nonatomic, strong) CAShapeLayer* axisLayer;
@property (nonatomic, strong) CAShapeLayer* dpsLayer;
@property (nonatomic, strong) CAShapeLayer* velocityLayer;
@property (nonatomic, strong) CAShapeLayer* markerLayer;
@property (nonatomic, assign) float maxRange;
@property (nonatomic, assign) float falloff;
@property (nonatomic, assign) float fullRange;
@property (nonatomic, strong) NSData* dpsPoints;
@property (nonatomic, strong) NSData* velocityPoints;
@property (nonatomic, assign) float markerPosition;
@property (nonatomic, strong) NSNumberFormatter* dpsNumberFormatter;
@property (nonatomic, strong) NCDBEufeHullType* hullType;
- (void) update;
@end

@implementation NCFittingShipOffenseStatsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	NSManagedObjectID* hullTypeID = self.fit.engine.userInfo[@"hullType"];
	NCDBEufeHullType* hullType;
	if (hullTypeID)
		hullType = [self.databaseManagedObjectContext existingObjectWithID:hullTypeID error:nil];
	
	if (!hullType) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
		hullType = type.hullType;
	}
	self.hullType = hullType;

	self.dpsNumberFormatter = [[NSNumberFormatter alloc] init];
	[self.dpsNumberFormatter setPositiveFormat:@"#,##0.0"];
	[self.dpsNumberFormatter setGroupingSeparator:@" "];
	[self.dpsNumberFormatter setDecimalSeparator:@"."];

	self.axisLayer = [CAShapeLayer layer];
	self.axisLayer.strokeColor = [[UIColor whiteColor] CGColor];
	self.axisLayer.fillColor = [[UIColor clearColor] CGColor];
	self.axisLayer.delegate = self;
	self.axisLayer.needsDisplayOnBoundsChange = YES;

	self.dpsLayer = [CAShapeLayer layer];
	self.dpsLayer.strokeColor = [[UIColor orangeColor] CGColor];
	self.dpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.dpsLayer.delegate = self;
	self.dpsLayer.needsDisplayOnBoundsChange = YES;

	self.velocityLayer = [CAShapeLayer layer];
	self.velocityLayer.strokeColor = [[UIColor greenColor] CGColor];
	self.velocityLayer.fillColor = [[UIColor clearColor] CGColor];
	self.velocityLayer.delegate = self;
	self.velocityLayer.needsDisplayOnBoundsChange = YES;

	[self.canvasView.layer addSublayer:self.axisLayer];
	[self.canvasView.layer addSublayer:self.dpsLayer];
	[self.canvasView.layer addSublayer:self.velocityLayer];
	self.axisLayer.frame = self.canvasView.layer.bounds;
	self.dpsLayer.frame = self.canvasView.layer.bounds;
	self.velocityLayer.frame = self.canvasView.layer.bounds;
	
	self.markerLayer = [CAShapeLayer layer];
	self.markerLayer.frame = self.markerView.layer.bounds;
	self.markerLayer.strokeColor = [[UIColor yellowColor] CGColor];
	self.markerLayer.fillColor = [[UIColor clearColor] CGColor];
	self.markerLayer.lineDashPattern = @[@4, @4];
	self.markerLayer.delegate = self;
	self.markerLayer.needsDisplayOnBoundsChange = YES;
	[self.markerView.layer addSublayer:self.markerLayer];
	
	__block float maxVelocity = 0;
	[self.fit.engine performBlockAndWait:^{
		auto pilot = self.fit.pilot;
		auto ship = pilot->getShip();
		float turretsDPS = 0;
		float maxRange = 0;
		float falloff = 0;
		for (auto module: ship->getModules()) {
			if (module->getHardpoint() == eufe::Module::HARDPOINT_TURRET) {
				float dps = module->getDps();
				if (dps > 0) {
					turretsDPS += dps;
					maxRange += module->getMaxRange() * dps;
					falloff += module->getFalloff() * dps;
				}
			}
		}
		if (turretsDPS > 0) {
			maxRange /= turretsDPS;
			falloff /= turretsDPS;
		}
		self.maxRange = maxRange;
		self.falloff = falloff;
		self.fullRange = self.maxRange + self.falloff * 2;
		maxVelocity = ship->getVelocity();
		if (self.fullRange == 0) {
			self.fullRange = ceil(ship->getOrbitRadiusWithTransverseVelocity(ship->getVelocity() * 0.95) * 1.5 / 1000) * 1000;
		}
	}];
	
	self.velocitySlider.minimumValue = 0;
	self.velocitySlider.maximumValue = maxVelocity;
	self.velocitySlider.value = maxVelocity;
	self.maxVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocity]];

	//[self update];
	self.markerPosition = -1;
	[self onChangeVelocity:self.velocitySlider];

	self.optimalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.maxRange]];
	self.falloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.falloff + self.maxRange]];
	self.doubleFalloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
	
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.optimalAuxiliaryView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeWidth
																multiplier:self.maxRange / self.fullRange
																  constant:0]];

	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.falloffAuxiliaryView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeWidth
																multiplier:self.falloff / self.fullRange
																  constant:0]];
	
	if (self.maxRange == 0 || self.falloff == 0) {
		self.optimalLabel.hidden = YES;
		self.falloffLabel.hidden = YES;
		for (UIView* label in self.axisLabels)
			label.hidden = YES;
	}
}

- (void) dealloc {
	self.dpsLayer.delegate = nil;
	self.axisLayer.delegate = nil;
	self.velocityLayer.delegate = nil;
	self.markerLayer.delegate = nil;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.dpsLayer.frame = self.canvasView.bounds;
	self.velocityLayer.frame = self.canvasView.bounds;
	self.axisLayer.frame = self.canvasView.bounds;
	self.markerLayer.frame = self.markerView.layer.bounds;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[self.view setNeedsUpdateConstraints];
}

- (void) displayLayer:(CALayer *)layer {
	if (layer == self.axisLayer) {
		UIBezierPath* bezierPath = [UIBezierPath bezierPath];
		[bezierPath moveToPoint:CGPointMake(0, 0)];
		[bezierPath addLineToPoint:CGPointMake(0, self.canvasView.bounds.size.height)];
		[bezierPath addLineToPoint:CGPointMake(self.canvasView.bounds.size.width, self.canvasView.bounds.size.height)];
		
		for (CGFloat x: {	self.canvasView.bounds.size.width * self.maxRange / self.fullRange,
			self.canvasView.bounds.size.width * (self.maxRange + self.falloff) / self.fullRange,
			self.canvasView.bounds.size.width}) {
				[bezierPath moveToPoint:CGPointMake(x, self.canvasView.bounds.size.height)];
				[bezierPath addLineToPoint:CGPointMake(x, self.canvasView.bounds.size.height - 4)];
			}
		
		//for (CGFloat y: std::vector<CGFloat>({0.0f, self.canvasView.bounds.size.height / 2})) {
		for (CGFloat y: {(CGFloat) 0.0f, self.canvasView.bounds.size.height / 2}) {

			[bezierPath moveToPoint:CGPointMake(0, y)];
			[bezierPath addLineToPoint:CGPointMake(4, y)];
		}
		
		self.axisLayer.path = [bezierPath CGPath];
	}
	else if (layer == self.dpsLayer) {
		//SKShapeNode* node = [SKShapeNode shapeNodeWithSplinePoints:(CGPoint*) [self.dpsPoints bytes] count:self.dpsPoints.length / sizeof(CGPoint)];
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.dpsPoints bytes] count:self.dpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.dpsLayer.path = path.CGPath;
	}
	else if (layer == self.velocityLayer) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.velocityPoints bytes] count:self.velocityPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.velocityLayer.path = path.CGPath;
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
	[self update];
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
	//self.velocityLabelConstraint.priority = UILayoutPriorityDefaultHigh;
	[self.velocityLabelAuxiliaryView.superview addConstraint:constraint];
	[self.view setNeedsUpdateConstraints];
}

- (IBAction)onPan:(UIPanGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
	[self update];
}

- (IBAction)onTap:(UITapGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
	[self update];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingHullTypePickerViewController"]) {
		NCFittingHullTypePickerViewController* controller = segue.destinationViewController;
		controller.selectedHullType = self.hullType;
	}
}

- (IBAction) unwindFromHullTypePicker:(UIStoryboardSegue*) segue {
	NCFittingHullTypePickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedHullType) {
		NCDBEufeHullType* hullType = [self.databaseManagedObjectContext objectWithID:sourceViewController.selectedHullType.objectID];
		self.hullType = hullType;
		self.fit.engine.userInfo[@"hullType"] = sourceViewController.selectedHullType.objectID;
		[self update];
	}
}



#pragma mark - Private

- (void) update {
	float velocity = self.velocitySlider.value;
	__block CGPoint maxDPS = CGPointZero;
	float targetSignature = self.hullType.signature;

	[self.fit.engine performBlockAndWait:^{
		auto pilot = self.fit.pilot;
		auto ship = pilot->getShip();
		auto maxVelocity = ship->getVelocity();
		
		int n = self.canvasView.bounds.size.width / 2 - 1;
		CGPoint *dpsPoints = new CGPoint[n];
		CGPoint *velocityPoints = new CGPoint[n];
		float dx = self.fullRange / (n + 1);
		float x = dx;
		float droneDPS = ship->getDroneDps();
		float dps = ship->getWeaponDps() + droneDPS;
		for (int i = 0; i < n; i++) {
			float v = ship->getMaxVelocityInOrbit(x);
			v = std::min(v, velocity);
			float angularVelocity = v / x;
			eufe::HostileTarget target = eufe::HostileTarget(x, angularVelocity, targetSignature, 0);

			dpsPoints[i] = CGPointMake(x / self.fullRange, dps > 0 ? (ship->getWeaponDps(target) + droneDPS) / dps : 0);
			
			if (dpsPoints[i].y >= maxDPS.y)
				maxDPS = dpsPoints[i];
			
			velocityPoints[i] = CGPointMake(x / self.fullRange, maxVelocity > 0 ? v / maxVelocity : 0);
			x += dx;
		}
		
		self.dpsPoints = [NSData dataWithBytes:dpsPoints length:sizeof(CGPoint) * n];
		self.velocityPoints = [NSData dataWithBytes:velocityPoints length:sizeof(CGPoint) * n];
		delete[] dpsPoints;
		delete[] velocityPoints;
	}];
	
	if (self.markerPosition < 0)
		self.markerPosition = maxDPS.x;
	
	__block float orbit = 0;
	__block float transverseVelocity = 0;
	__block float dps = 0;
	__block float droneDPS = 0;
	__block float turretsDPS = 0;
	__block float launchersDPS = 0;
	
	__block float optimalDPS = 0;
	[self.fit.engine performBlockAndWait:^{
		auto pilot = self.fit.pilot;
		auto ship = pilot->getShip();

		float x = self.fullRange * self.markerPosition;
		orbit = x;
		float v = ship->getMaxVelocityInOrbit(x);
		v = std::min(v, velocity);
		transverseVelocity = v;
		float angularVelocity = v / x;
		droneDPS = ship->getDroneDps();
		eufe::HostileTarget target = eufe::HostileTarget(x, angularVelocity, targetSignature, 0);

		for (auto module: ship->getModules()) {
			if (module->getHardpoint() == eufe::Module::HARDPOINT_TURRET)
				turretsDPS += module->getDps(target);
			else
				launchersDPS += module->getDps(target);
		}

		dps = turretsDPS + launchersDPS + droneDPS;
		optimalDPS = ship->getWeaponDps() + droneDPS;
	}];
	
	self.orbitLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbit]];
	self.transverseVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:transverseVelocity]];
	
	NSMutableAttributedString* s = [NSMutableAttributedString new];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (", [self.dpsNumberFormatter stringFromNumber:@(dps)]] attributes:nil]];
	
	NSTextAttachment* icon;

	icon = [NSTextAttachment new];
	icon.image = [UIImage imageNamed:@"turrets"];
	icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
	[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ + ", [self.dpsNumberFormatter stringFromNumber:@(turretsDPS)]] attributes:nil]];

	
	icon = [NSTextAttachment new];
	icon.image = [UIImage imageNamed:@"launchers"];
	icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
	[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ + ", [self.dpsNumberFormatter stringFromNumber:@(launchersDPS)]] attributes:nil]];

	icon = [NSTextAttachment new];
	icon.image = [UIImage imageNamed:@"drone"];
	icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
	[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
	//[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@) %.0f%%", [self.dpsNumberFormatter stringFromNumber:@(droneDPS)], optimalDPS ? dps / optimalDPS * 100 : 100.0f] attributes:nil]];
	[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@)", [self.dpsNumberFormatter stringFromNumber:@(droneDPS)]] attributes:nil]];
	self.dpsTitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DPS %.0f%%", nil), optimalDPS ? dps / optimalDPS * 100 : 100.0f];

	
	//self.dpsLabel.text = [NSNumberFormatter neocomLocalizedStringFromNumber:@(dps)];
	self.dpsLabel.attributedText = s;
	
	self.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.velocitySlider.value]];

	
	[self.dpsLayer setNeedsDisplay];
	[self.velocityLayer setNeedsDisplay];
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

- (void) setHullType:(NCDBEufeHullType*) hullType {
	_hullType = hullType;
	if (hullType) {
		NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:hullType.hullTypeName attributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
		[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@" (sig %.0f m)", nil), hullType.signature] attributes:nil]];
		self.targetLabel.attributedText = s;
	}
	else
		self.targetLabel.text = NSLocalizedString(@"None", nil);
}

@end
