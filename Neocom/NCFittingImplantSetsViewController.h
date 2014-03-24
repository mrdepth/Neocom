//
//  NCFittingImplantSetsViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 24.03.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCImplantSet.h"

@interface NCFittingImplantSetsViewController : NCTableViewController
@property (nonatomic, assign, getter = isSaveMode) BOOL saveMode;
@property (nonatomic, strong) NCImplantSetData* implantSetData;
@property (nonatomic, strong) NCImplantSet* selectedImplantSet;
@end
