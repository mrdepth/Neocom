//
//  NCFittingPOSViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 11.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"
#import "NCFittingPOSWorkspaceViewController.h"
#import "NCFittingPOSStatsViewController.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCPOSFit.h"
#import "NCDamagePattern.h"
#import "NCProgressLabel.h"

@interface NCFittingPOSViewController : NCViewController<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControl;
@property (nonatomic, weak) IBOutlet NCProgressLabel *powerGridLabel;
@property (nonatomic, weak) IBOutlet NCProgressLabel *cpuLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong, readonly) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong, readonly) NCFittingEngine* engine;
@property (nonatomic, strong) NCPOSFit* fit;


- (IBAction)onChangeSection:(UISegmentedControl*)sender;
- (IBAction)onAction:(id)sender;
- (IBAction)onBack:(id)sender;
- (void) reload;
@end
