//
//  NCDBInvMetaType.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvMetaGroup, NCDBInvType;

@interface NCDBInvMetaType : NSManagedObject

@property (nonatomic, retain) NCDBInvMetaGroup *metaGroup;
@property (nonatomic, retain) NCDBInvType *parentType;
@property (nonatomic, retain) NCDBInvType *type;

@end
