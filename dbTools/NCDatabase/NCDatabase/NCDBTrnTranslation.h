//
//  NCDBTrnTranslation.h
//  NCDatabase
//
//  Created by Артем Шиманский on 15.05.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NCDBTrnTranslation : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic) int32_t keyID;
@property (nonatomic) int16_t columnID;

@end
