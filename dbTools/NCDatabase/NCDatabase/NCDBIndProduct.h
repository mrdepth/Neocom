//
//  NCDBIndProduct.h
//  NCDatabase
//
//  Created by Артем Шиманский on 17.09.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBChrRace, NCDBIndActivity, NCDBInvType;

@interface NCDBIndProduct : NSManagedObject

@property (nonatomic) int32_t quantity;
@property (nonatomic) float probability;
@property (nonatomic, retain) NCDBIndActivity *activity;
@property (nonatomic, retain) NCDBInvType *productType;
//@property (nonatomic, retain) NCDBChrRace *race;

@end
