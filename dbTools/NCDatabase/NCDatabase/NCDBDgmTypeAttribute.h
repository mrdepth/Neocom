//
//  NCDBDgmTypeAttribute.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBDgmAttributeType, NCDBInvType;

@interface NCDBDgmTypeAttribute : NSManagedObject

@property (nonatomic) float value;
@property (nonatomic, retain) NCDBDgmAttributeType *attributeType;
@property (nonatomic, retain) NCDBInvType *type;

@end
