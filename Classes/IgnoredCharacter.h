//
//  IgnoredCharacter.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 25.01.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface IgnoredCharacter : NSManagedObject

@property (nonatomic) int32_t characterID;

+ (NSArray*) allIgnoredCharacters;

@end
