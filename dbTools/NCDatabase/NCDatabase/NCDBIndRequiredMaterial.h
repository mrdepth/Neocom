//
//  NCDBIndRequiredMaterial.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBIndActivity, NCDBInvType;

@interface NCDBIndRequiredMaterial : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic) int32_t consume;
@property (nonatomic, retain) NCDBIndActivity *activity;
@property (nonatomic, retain) NCDBInvType *materialType;

@end
