//
//  NCFittingShipCombatSimulatorViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 02.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"

@class NCShipFit;
@interface NCFittingShipCombatSimulatorViewController : NCViewController
@property (weak, nonatomic) IBOutlet UILabel *marker1Label;
@property (weak, nonatomic) IBOutlet UILabel *marker1TitleLabel;
@property (weak, nonatomic) IBOutlet UIView *marker1AuxiliaryView;
@property (weak, nonatomic) IBOutlet UILabel *marker2Label;
@property (weak, nonatomic) IBOutlet UILabel *marker2TitleLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *canvasView;
@property (weak, nonatomic) IBOutlet UISlider *velocitySlider;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *velocityLabelConstraint;
@property (weak, nonatomic) IBOutlet UILabel *maxVelocityLabel;
@property (weak, nonatomic) IBOutlet UIView *velocityLabelAuxiliaryView;
@property (weak, nonatomic) IBOutlet UIView *markerView;
@property (weak, nonatomic) IBOutlet UIView *markerAuxiliaryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *markerViewConstraint;
@property (weak, nonatomic) IBOutlet UILabel *orbitLabel;
@property (weak, nonatomic) IBOutlet UILabel *transverseVelocityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealtDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealtDpsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedDpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *receivedDpsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (strong, nonatomic) NCShipFit* attacker;
@property (strong, nonatomic) NCShipFit* target;
@property (weak, nonatomic) IBOutlet UILabel *reportLabel;

- (IBAction)onChangeVelocity:(id) sender;
- (IBAction)onPan:(UIPanGestureRecognizer*) recognizer;
- (IBAction)onTap:(UITapGestureRecognizer*) recognizer;

@end
