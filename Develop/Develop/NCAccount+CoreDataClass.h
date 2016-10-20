//
//  NCAccount+CoreDataClass.h
//  Develop
//
//  Created by Artem Shimanski on 18.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCAPIKey, NCMailBox, NCSkillPlan, EVEAPIKey;

NS_ASSUME_NONNULL_BEGIN

@interface NCAccount : NSManagedObject
@property (readonly) EVEAPIKey* eveAPIKey;
@end

NS_ASSUME_NONNULL_END

#import "NCAccount+CoreDataProperties.h"
