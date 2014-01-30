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

@interface NCFittingShipViewController : NCViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentedControl;
@property (nonatomic, weak) NCFittingShipWorkspaceViewController* workspaceViewController;
@property (nonatomic, assign) std::shared_ptr<eufe::Engine> engine;
@property (nonatomic, strong) NCShipFit* fit;
@property (nonatomic, assign) eufe::Character* character;
@property (nonatomic, strong, readonly) NCDatabaseTypePickerViewController* typePickerViewController;

- (IBAction)onChangeSection:(id)sender;
- (EVEDBInvType*) typeWithItem:(eufe::Item*) item;
- (void) reload;

@end
