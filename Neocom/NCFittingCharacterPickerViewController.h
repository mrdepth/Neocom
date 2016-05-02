//
//  NCFittingCharacterPickerViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"
#import "NCFitCharacter.h"

@class NCShipFit;
@interface NCFittingCharacterPickerViewController : NCTableViewController
@property (nonatomic, strong) id fit;
@property (nonatomic, strong) NCFitCharacter* selectedCharacter;

@end
