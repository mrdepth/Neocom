//
//  NCDBMapRegion.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBMapConstellation, NCDBMapDenormalize;

@interface NCDBMapRegion : NSManagedObject

@property (nonatomic) int32_t regionID;
@property (nonatomic, retain) NSString * regionName;
@property (nonatomic, retain) NCDBMapConstellation *constellations;
@property (nonatomic, retain) NSSet *denormalize;
@end

@interface NCDBMapRegion (CoreDataGeneratedAccessors)

- (void)addDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)removeDenormalizeObject:(NCDBMapDenormalize *)value;
- (void)addDenormalize:(NSSet *)values;
- (void)removeDenormalize:(NSSet *)values;

@end
