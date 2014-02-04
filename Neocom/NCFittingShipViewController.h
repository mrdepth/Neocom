//
//  NCFittingShipViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCViewController.h"
#import "eufe.h"
#import "NCShipFit.h"
#import "NCDatabaseTypePickerViewController.h"
#import "NCFittingShipWorkspaceViewController.h"
#import "NCDamagePattern.h"

@interface NCFittingShipViewController : NCViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControl;
@property (nonatomic, weak) NCFittingShipWorkspaceViewController* workspaceViewController;
@property (nonatomic, strong, readonly) NCDatabaseTypePickerViewController* typePickerViewController;

@property (nonatomic, strong, readonly) NSMutableArray* fits;
@property (nonatomic, assign, readonly) std::shared_ptr<eufe::Engine> engine;

@property (nonatomic, strong) NCShipFit* fit;

@property (nonatomic, strong) NCDamagePattern* damagePattern;


- (IBAction)onChangeSection:(id)sender;
- (EVEDBInvType*) typeWithItem:(eufe::Item*) item;
- (void) reload;

@end
