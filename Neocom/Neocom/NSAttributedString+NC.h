//
//  NSAttributedString+NC.h
//  Neocom
//
//  Created by Artem Shimanski on 17.11.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (NC)

+ (instancetype) attributedStringWithSkillName:(NSString*) skillName level:(NSInteger) level;
+ (instancetype) attributedStringWithSkillName:(NSString*) skillName level:(NSInteger) level rank:(NSInteger) rank;
@end
