//
//  NCAccount.h
//  Develop
//
//  Created by Artem Shimanski on 12.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCAPIKey, NCMailBox, NCSkillPlan, EVEAPIKey;

NS_ASSUME_NONNULL_BEGIN

@interface NCAccount : NSManagedObject
@property (readonly) EVEAPIKey* eveAPIKey;
@end

NS_ASSUME_NONNULL_END

