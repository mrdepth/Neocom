//
//  NCDBIndActivity+CoreDataClass.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndBlueprintType, NCDBIndProduct, NCDBIndRequiredMaterial, NCDBIndRequiredSkill, NCDBRamActivity;

NS_ASSUME_NONNULL_BEGIN

@interface NCDBIndActivity : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "NCDBIndActivity+CoreDataProperties.h"
