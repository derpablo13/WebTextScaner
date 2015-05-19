//
//  WTURLFilter.h
//  WebTextScanner
//
//  Created by parak on 4/16/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTMLNode;

@interface WTURLFilter : NSObject

- (NSArray *)getFilteredUrlsFromHTMLNode:(HTMLNode *)htmlNode withoutDuplicatesFromExistingUrlsDictionary:(NSDictionary *)existingUrlsDictionary;

@end
