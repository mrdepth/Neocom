//
//  NCFitLoadout.h
//  Neocom
//
//  Created by Артем Шиманский on 30.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCFit;

@interface NCFitLoadout : NSManagedObject

@property (nonatomic, retain) id loadout;
@property (nonatomic, retain) NCFit *fit;

@end
