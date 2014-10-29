//
//  NCDBVersion.h
//  NCDatabase
//
//  Created by Artem Shimanski on 15.10.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCDBVersion : NSManagedObject

@property (nonatomic, retain) NSString * version;
@property (nonatomic) int32_t build;

@end
