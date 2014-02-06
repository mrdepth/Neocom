//
//  NCFittingTypeVariationsViewController.h
//  Neocom
//
//  Created by Shimanski Artem on 06.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCDatabaseTypeVariationsViewController.h"

@interface NCFittingTypeVariationsViewController : NCDatabaseTypeVariationsViewController
@property (nonatomic, strong) id object;
@property (nonatomic, strong) EVEDBInvType* type;
@property (nonatomic, strong) EVEDBInvType* selectedType;

@end
