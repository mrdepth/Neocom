//
//  NCDBCertMasteryLevel+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBCertMasteryLevel+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBCertMasteryLevel (CoreDataProperties)

+ (NSFetchRequest<NCDBCertMasteryLevel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *displayName;
@property (nonatomic) int16_t level;
@property (nullable, nonatomic, retain) NCDBEveIcon *icon;
@property (nullable, nonatomic, retain) NSSet<NCDBCertMastery *> *masteries;

@end

@interface NCDBCertMasteryLevel (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet<NCDBCertMastery *> *)values;
- (void)removeMasteries:(NSSet<NCDBCertMastery *> *)values;

@end

NS_ASSUME_NONNULL_END
