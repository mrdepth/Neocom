//
//  NCDBInvControlTower.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NCDBInvControlTowerResource, NCDBInvType;

@interface NCDBInvControlTower : NSManagedObject

@property (nonatomic, retain) NCDBInvControlTowerResource *resources;
@property (nonatomic, retain) NCDBInvType *type;

@end
