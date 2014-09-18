//
//  NCDBRamAssemblyLineType.h
//  Neocom
//
//  Created by Артем Шиманский on 18.09.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBRamActivity, NCDBRamInstallationTypeContent;

@interface NCDBRamAssemblyLineType : NSManagedObject

@property (nonatomic) int32_t assemblyLineTypeID;
@property (nonatomic, retain) NSString * assemblyLineTypeName;
@property (nonatomic) float baseMaterialMultiplier;
@property (nonatomic) float baseTimeMultiplier;
@property (nonatomic) float minCostPerHour;
@property (nonatomic) float volume;
@property (nonatomic, retain) NCDBRamActivity *activity;
@property (nonatomic, retain) NSSet *installationTypeContents;
@end

@interface NCDBRamAssemblyLineType (CoreDataGeneratedAccessors)

- (void)addInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)removeInstallationTypeContentsObject:(NCDBRamInstallationTypeContent *)value;
- (void)addInstallationTypeContents:(NSSet *)values;
- (void)removeInstallationTypeContents:(NSSet *)values;

@end
