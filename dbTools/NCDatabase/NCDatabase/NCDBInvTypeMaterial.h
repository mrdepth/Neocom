//
//  NCDBInvTypeMaterial.h
//  NCDatabase
//
//  Created by Shimanski Artem on 15.06.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvBlueprintType, NCDBInvType;

@interface NCDBInvTypeMaterial : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic, retain) NCDBInvBlueprintType *blueprintType;
@property (nonatomic, retain) NCDBInvType *materialType;

@end
