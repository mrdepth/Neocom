//
//  NCDBCertMasteryLevel.h
//  Neocom
//
//  Created by Shimanski Artem on 15.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBEveIcon;

@interface NCDBCertMasteryLevel : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic) int16_t level;
@property (nonatomic, retain) NCDBEveIcon *claimedIcon;
@property (nonatomic, retain) NSSet *masteries;
@property (nonatomic, retain) NCDBEveIcon *unclaimedIcon;
@end

@interface NCDBCertMasteryLevel (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
