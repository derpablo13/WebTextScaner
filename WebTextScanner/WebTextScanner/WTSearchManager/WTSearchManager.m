//
//  WTSearchManager.m
//  WebTextScanner
//
//  Created by parak on 4/3/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import "WTSearchManager.h"
#import "HTMLParser.h"
#import "WTNode.h"
#import "WTURLFilter.h"
#import "WTURLSessionManager.h"

@interface WTSearchManager()

@property NSMutableDictionary *currentSearchNodes;
@property BOOL isSearching;

@property NSString *searchText;
@property NSInteger maxSearchUrlCount;

@property NSUInteger processingLevel;
@property NSUInteger processingLevelNodesCount;

@property WTURLSessionManager *URLSessionManager;
@property WTURLFilter *URLFilter;

@property BOOL searchTextWithTrimming;

@end

@implementation WTSearchManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentSearchNodes = [NSMutableDictionary dictionary];
        self.URLFilter = [WTURLFilter new];
    }
    return self;
}

#pragma mark - Start/Stop search

- (void)searchWebTextForUrl:(NSString *)searchUrl
     maxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount
                 searchText:(NSString *)searchText
          maxSearchUrlCount:(NSInteger)maxSearchUrlCount {

    // TODO : Change later!!!
    self.searchTextWithTrimming = YES;
    
    [self.currentSearchNodes removeAllObjects];
    
    self.isSearching = YES;
    
    // TODO : Chacnge later!!!
    if (!self.URLSessionManager) {
        self.URLSessionManager = [[WTURLSessionManager alloc] initWithMaxConcurrentTaskCount:maxConcurrentTaskCount];
    }
    
    if (self.searchTextWithTrimming) {
        self.searchText = [self trimString:searchText];
    } else {
        self.searchText = searchText;
    }
    
    self.maxSearchUrlCount = maxSearchUrlCount;
    
    WTNode *rootNode = [self createNewNodeWithUrl:searchUrl
                                       parentNode:nil];
    
    self.processingLevel = rootNode.level;
    self.processingLevelNodesCount = 1;
    [self addNewDataTaskWithNode:rootNode];
    
    [self.URLSessionManager startTasks];
}

- (void)stopSearching {
    self.isSearching = NO;
    
    [self.URLSessionManager stopAllTasks];
    
    NSLog(@"stopSearching!!!");
}

- (BOOL)processingCurrentLevelNodesFinished {
    return self.isSearching && self.processingLevelNodesCount == 0;
}

- (void)processNextLevelNodes {
    NSLog(@"processNextLevelNodes");
    self.processingLevel++;
    NSArray *nextLevelUnprocessedNodes = [self getUnprocessedNodesForProcessingLevel:self.processingLevel];
    if (nextLevelUnprocessedNodes.count) {
        self.processingLevelNodesCount = nextLevelUnprocessedNodes.count;
        for (WTNode *node in nextLevelUnprocessedNodes) {
            [self addNewDataTaskWithNode:node];
        }
    } else {
        // Stop with message "Text not found".
    }
}

#pragma mark - Create new node and add it to arrays

- (WTNode *)createNewNodeWithUrl:(NSString *)url
                      parentNode:(WTNode *)parentNode {
    if (!url) {
        return nil;
    }
    
    WTNode *node = [[WTNode alloc] initWithUrlString:url];
    
    if (parentNode) {
        node.level = parentNode.level + 1;
    } else {
        node.level = 0;
    }
    
    [self.currentSearchNodes setObject:node
                                forKey:node.urlString];
    
    return node;
}

- (void)createNewNodesWithParrentNode:(WTNode *)node
                           urlContent:(NSArray *)urlContent {
    for (NSString *urlString in urlContent) {
        if (self.currentSearchNodes.allValues.count < self.maxSearchUrlCount) {
            [self createNewNodeWithUrl:urlString
                            parentNode:node];
        } else {
            return;
        }
    }
}

- (NSArray *)getUnprocessedNodesForProcessingLevel:(NSInteger)processingLevel {
    NSMutableArray *unprocessedNodes = [NSMutableArray array];
    for (WTNode *node in self.currentSearchNodes.allValues) {
        if (node.level == processingLevel && node.status == kNodeStatusUnprocessed) {
            [unprocessedNodes addObject:node];
        }
    }
    return unprocessedNodes;
}

#pragma mark - Process node

- (void)addNewDataTaskWithNode:(WTNode *)node {
    if (!self.isSearching) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.URLSessionManager addNewDataTaskWithURL:[NSURL URLWithString:node.urlString]
                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    [weakSelf dataTaskCompletionWithNode:node
                                                                response:response
                                                                    data:data
                                                                   error:error];
                                }];
}

- (void)dataTaskCompletionWithNode:(WTNode *)node
                          response:(NSURLResponse *)response
                              data:(NSData *)data
                             error:(NSError *)error {
    if (!self.isSearching) {
        return;
    }
    
    node.status = kNodeStatusProcessed;
    
    if (node.level == self.processingLevel) {
        self.processingLevelNodesCount--;
    }
    
    if (error) {
        node.error = error;
    } else if (!data) {
        NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionaryWithObject:@"No data found."
                                                                                forKey:NSLocalizedDescriptionKey];
        node.error = [NSError errorWithDomain:node.urlString
                                         code:404
                                     userInfo:errorUserInfo];
    } else {
        NSError *parsingError = nil;
        HTMLParser *parser = [[HTMLParser alloc] initWithData:data
                                                        error:&parsingError];
        
        if (parsingError) {
            NSLog(@"Error: %@", parsingError);
            return;
        }
        
        HTMLNode *bodyNode = [parser body];
        NSLog(@"bodyNode.contents %d", bodyNode.allContents.length);
        
        // Check text content
        if ([self textContainsSearchText:bodyNode.allContents]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"\n\nText is found!!! Level %lu | Node level %d | In node %@\n\n", (unsigned long)self.processingLevel, node.level, node.urlString);
                [self stopSearching];
            });
        } else {
            // Continue search...
            NSArray *filteredUrlContent = [self.URLFilter getFilteredUrlsFromHTMLNode:bodyNode withoutDuplicatesFromExistingUrlsDictionary:self.currentSearchNodes];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self createNewNodesWithParrentNode:node
                                         urlContent:filteredUrlContent];
            });
        }
    }
    
    NSLog(@"Node level %lu | Left nodes %d | Node URL %@", (unsigned long)node.level, self.processingLevelNodesCount, node.urlString);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self processingCurrentLevelNodesFinished]) {
            [self processNextLevelNodes];
        }
    });
}

#pragma mark - Check text

- (BOOL)textContainsSearchText:(NSString *)text {
    if (text) {
        NSString *sourceText = self.searchTextWithTrimming ? [self trimString:text] : text;
        return [sourceText rangeOfString:self.searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
    } else {
        return NO;
    }
}

- (NSString *)trimString:(NSString *)string {
    NSString *squashedString = [string stringByReplacingOccurrencesOfString:@"\\s+"
                                                                 withString:@" "
                                                                    options:NSRegularExpressionSearch
                                                                      range:NSMakeRange(0, string.length)];
    
    return [squashedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
