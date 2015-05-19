//
//  WTNode.h
//  WebTextScanner
//
//  Created by parak on 4/3/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    kNodeStatusUnprocessed  = 0,
    kNodeStatusProcessed    = 1,
} NodeStatusItems;

@interface WTNode : NSObject

@property (nonatomic, readonly) NSString *urlString;
@property NSUInteger level;
@property NodeStatusItems status;
@property (nonatomic, copy) NSError *error;

- (instancetype)initWithUrlString:(NSString *)urlString;

@end
