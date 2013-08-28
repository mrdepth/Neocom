//
//  Setting.h
//  EVEUniverse
//
//  Created by Artem Shimanski on 27.08.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define SettingCharactersOrderKey @"SettingCharactersOrderKey"

@interface Setting : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;

+ (Setting*) settingWithKey:(NSString*) key;

@end
