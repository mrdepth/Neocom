//
//  NCFittingSpaceStructureViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"
#import <dgmpp/dgmpp.h>
#import "NCSpaceStructureFit.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCFittingSpaceStructureWorkspaceViewController.h"
#import "NCDamagePattern.h"
#import "NCProgressLabel.h"
#import "NCFittingEngine.h"

@interface NCFittingSpaceStructureViewController : NCViewController<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControl;
@property (nonatomic, weak) IBOutlet NCProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *cpuLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *calibrationLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBayLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *droneBandwidthLabel;
@property (nonatomic, weak) IBOutlet UILabel *dronesCountLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong, readonly) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong) NCSpaceStructureFit* fit;
@property (nonatomic, strong, readonly) NCFittingEngine* engine;


- (IBAction)onChangeSection:(UISegmentedControl*)sender;
- (IBAction)onAction:(id)sender;
- (IBAction)onBack:(id)sender;
- (void) reload;

@end
