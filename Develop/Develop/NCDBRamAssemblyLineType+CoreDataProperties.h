//
//  NCDBRamAssemblyLineType+CoreDataProperties.h
//  Develop
//
//  Created by Artem Shimanski on 20.10.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCDBRamAssemblyLineType+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface NCDBRamAssemblyLineType (CoreDataProperties)

+ (NSFetchRequest<NCDBRamAssemblyLineType *> *)fetchRequest;

@property (nonatomic) int32_t assemblyLineTypeID;
@property (nullable, nonatomic, copy) NSString *assemblyLineTypeName;
@property (nonatomic) float baseMaterialMultiplier;
@property (nonatomic) float baseTimeMultiplier;
@property (nonatomic) float minCostPerHour;
@property (nonatomic) float volume;
@property (nullable, nonatomic, retain) NCDBRamActivity *activity;
@property (nullable, nonatomic, retain) NSSet<NCDBRamInstallationTypeContent *> *installationTypeContents;

@end

@interface NCDBRamAssemblyLineType (CoreDataGeneratedAccessors)

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet<NCDBRamInstallationTypeContent *> *)values;
- (void)removeInstallationTypeContents:(NSSet<NCDBRamInstallationTypeContent *> *)values;

@end

NS_ASSUME_NONNULL_END
