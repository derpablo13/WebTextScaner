//
//  WTURLSessionManager.m
//  WebTextScanner
//
//  Created by parak on 4/10/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import "WTURLSessionManager.h"

@interface WTURLSessionManager() <NSURLSessionDelegate>

@property NSURLSession *URLSession;
@property NSInteger maxConcurrentTaskCount;
@property NSInteger runningTaskCount;
@property NSMutableArray *tasksArray;
@property BOOL haveToCreateNewURLSession;
@property BOOL tasksRunning;
@property NSOperationQueue *tasksQueue;

@end

@implementation WTURLSessionManager

- (instancetype)initWithMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount {
    self = [super init];
    if (self) {
        self.maxConcurrentTaskCount = maxConcurrentTaskCount;
        [self createURLSession];
        
        self.tasksArray = [NSMutableArray array];
        self.runningTaskCount = 0;
        
        self.tasksQueue = [NSOperationQueue new];
        self.tasksQueue.maxConcurrentOperationCount = 1;
        
        self.tasksRunning = NO;
    }
    return self;
}

#pragma mark - NSURLSession configuration

- (void)createURLSession {
    if (self.URLSession) {
        [self stopAllTasks];
        
        [self.URLSession invalidateAndCancel];
    } else {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.HTTPMaximumConnectionsPerHost = self.maxConcurrentTaskCount;
        sessionConfig.timeoutIntervalForResource = 0;
        sessionConfig.timeoutIntervalForRequest = 0;
        
        sessionConfig.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                               diskCapacity:0
                                                                   diskPath:nil];
        
        self.URLSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                        delegate:self
                                                   delegateQueue:nil];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if (error) {
        NSLog(@"Error Session Invalidation: %@", [error description]);
    }
    
    if ([session isEqual:self.URLSession]) {
        [self cleanupSession];
    }
}

- (void)cleanupSession {
    self.URLSession = nil;
    
    if (self.haveToCreateNewURLSession) {
        self.haveToCreateNewURLSession = NO;
        [self createURLSession];
    }
}

#pragma mark - Tasks methods

- (void)startTasks {
    self.tasksRunning = YES;
    
    [self updateTasksQueueAfterTaskCompleted:NO];
}

- (void)stopAllTasks {
    self.tasksRunning = NO;
    
    for (NSURLSessionTask *task in self.tasksArray) {
        [task cancel];
    }
}

- (NSURLSessionDataTask *)addNewDataTaskWithURL:(NSURL *)url
                              completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSURLSessionDataTask *dataTask = [self.URLSession dataTaskWithURL:url
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             if (completionHandler) {
                                                                 completionHandler(data, response, error);
                                                             }
                                                             
                                                             [self updateTasksQueueAfterTaskCompleted:YES];
                                                         }];
    [self.tasksArray addObject:dataTask];
    [self updateTasksQueueAfterTaskCompleted:NO];
    
    return dataTask;
}

- (void)updateTasksQueueAfterTaskCompleted:(BOOL)taskCompleted {
    if (!self.tasksRunning) {
        return;
    }
    
    [self.tasksQueue addOperationWithBlock:^{
        if (taskCompleted) {
            self.runningTaskCount--;
        }
        
        NSMutableArray *completedTasks = [NSMutableArray array];
        
        for (NSURLSessionTask *task in [self.tasksArray copy]) {
            if (task.state == NSURLSessionTaskStateSuspended) {
                if (self.runningTaskCount < self.maxConcurrentTaskCount) {
                    self.runningTaskCount++;
                    [task resume];
                } else {
                    break;
                }
            } else if (task.state == NSURLSessionTaskStateCompleted) {
                [completedTasks addObject:task];
            }
        }
        
        [self.tasksArray removeObjectsInArray:completedTasks];
    }];
}

@end
