//
//  NCMessageCell.h
//  Neocom
//
//  Created by Артем Шиманский on 24.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCTableViewCell.h"

@class NCMailBoxMessage;
@interface NCMessageCell : NCTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;
@property (strong, nonatomic) NCMailBoxMessage* message;

@end
