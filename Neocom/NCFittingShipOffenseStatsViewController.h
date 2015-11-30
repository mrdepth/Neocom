//
//  NCFittingShipOffenseStatsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 25.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"

@class NCShipFit;
@interface NCFittingShipOffenseStatsViewController : NCViewController
@property (weak, nonatomic) IBOutlet UILabel *optimalLabel;
@property (weak, nonatomic) IBOutlet UILabel *falloffLabel;
@property (weak, nonatomic) IBOutlet UILabel *doubleFalloffLabel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *canvasView;
@property (weak, nonatomic) IBOutlet UIView *optimalAuxiliaryView;
@property (weak, nonatomic) IBOutlet UIView *falloffAuxiliaryView;
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
@property (weak, nonatomic) IBOutlet UILabel *dpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *dpsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *axisLabels;
@property (strong, nonatomic) NCShipFit* fit;

- (IBAction)onChangeVelocity:(id) sender;
- (IBAction)onPan:(UIPanGestureRecognizer*) recognizer;
- (IBAction)onTap:(UITapGestureRecognizer*) recognizer;
@end
