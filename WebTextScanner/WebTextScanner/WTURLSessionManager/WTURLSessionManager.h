//
//  WTURLSessionManager.h
//  WebTextScanner
//
//  Created by parak on 4/10/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WTURLSessionManager : NSObject

- (instancetype)initWithMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount;

- (void)startTasks;
- (void)stopAllTasks;

- (NSURLSessionDataTask *)addNewDataTaskWithURL:(NSURL *)url
                              completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

@end
