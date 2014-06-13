//
//  NCDBCertCertificate.h
//  Neocom
//
//  Created by Артем Шиманский on 13.06.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBCertMastery, NCDBTxtDescription;

@interface NCDBCertCertificate : NSManagedObject

@property (nonatomic) int32_t certificateID;
@property (nonatomic, retain) NSString * certificateName;
@property (nonatomic, retain) NCDBTxtDescription *certificateDescription;
@property (nonatomic, retain) NSSet *masteries;
@end

@interface NCDBCertCertificate (CoreDataGeneratedAccessors)

- (void)addMasteriesObject:(NCDBCertMastery *)value;
- (void)removeMasteriesObject:(NCDBCertMastery *)value;
- (void)addMasteries:(NSSet *)values;
- (void)removeMasteries:(NSSet *)values;

@end
