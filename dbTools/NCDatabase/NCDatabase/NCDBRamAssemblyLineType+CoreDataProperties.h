//
//  NCDBRamAssemblyLineType+CoreDataProperties.h
//  NCDatabase
//
//  Created by Artem Shimanski on 29.11.15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBRamAssemblyLineType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBRamAssemblyLineType (CoreDataProperties)

@property (nonatomic) int32_t assemblyLineTypeID;
@property (nullable, nonatomic, retain) NSString *assemblyLineTypeName;
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
