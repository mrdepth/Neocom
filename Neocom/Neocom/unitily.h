//
//  unitily.h
//  Neocom
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CLAMP(x, from, to)(MIN(MAX(x, from), to))
#define NCDefaultErrorDomain ([NSStringFromClass([self class]) stringByAppendingString:@"Domain"])
#define NCDefaultErrorCode -1

extern NSString* const NCCurrentAccountChangedNotification;
