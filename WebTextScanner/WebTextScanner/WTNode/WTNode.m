//
//  WTNode.m
//  WebTextScanner
//
//  Created by parak on 4/3/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import "WTNode.h"

@interface WTNode()

@property NSString *urlString;

@end

@implementation WTNode

- (instancetype)initWithUrlString:(NSString *)urlString {
    self = [super init];
    if (self) {
        self.urlString = urlString;
        self.status = kNodeStatusUnprocessed;
        self.error = nil;
    }
    return self;
}

@end
