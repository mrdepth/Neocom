//
//  NCDBVersion+CoreDataProperties.h
//  NCDatabase
//
//  Created by Артем Шиманский on 14.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBVersion.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBVersion (CoreDataProperties)

@property (nonatomic) int32_t build;
@property (nullable, nonatomic, retain) NSString *expansion;
@property (nullable, nonatomic, retain) NSString *version;

@end

NS_ASSUME_NONNULL_END
