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
#import "eufe.h"
#import "NCPOSFit.h"
#import "NCDamagePattern.h"

@interface NCFittingPOSViewController : NCViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControl;
@property (nonatomic, weak) NCFittingPOSWorkspaceViewController* workspaceViewController;
@property (nonatomic, weak) NCFittingPOSStatsViewController* statsViewController;
@property (nonatomic, strong, readonly) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, assign, readonly) std::shared_ptr<eufe::Engine> engine;
@property (nonatomic, strong) NCPOSFit* fit;
@property (nonatomic, strong) NCDamagePattern* damagePattern;


- (IBAction)onChangeSection:(id)sender;
- (IBAction)onAction:(id)sender;
- (NCDBInvType*) typeWithItem:(eufe::Item*) item;
- (void) reload;
@end
