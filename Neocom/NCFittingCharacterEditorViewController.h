//
//  NCFittingCharacterEditorViewController.h
//  Neocom
//
//  Created by Артем Шиманский on 31.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewController.h"

@class NCFitCharacter;
@interface NCFittingCharacterEditorViewController : NCTableViewController
@property (nonatomic, strong) NCFitCharacter* character;

@end
