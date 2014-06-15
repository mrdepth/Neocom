//
//  NCDBMapRegion.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBMapConstellation, NCDBMapDenormalize;

@interface NCDBMapRegion : NSManagedObject

@property (nonatomic) int32_t regionID;
@property (nonatomic, retain) NSString * regionName;
@property (nonatomic, retain) NSSet *constellations;
@property (nonatomic, retain) NSSet *denormalize;
@end

@interface NCDBMapRegion (CoreDataGeneratedAccessors)

- (void)addConstellationsObject:(NCDBMapConstellation *)value;
- (void)removeConstellationsObject:(NCDBMapConstellation *)value;
- (void)addConstellations:(NSSet *)values;
- (void)removeConstellations:(NSSet *)values;

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet *)values;
- (void)removeDenormalize:(NSSet *)values;

@end
