//
//  WTURLFilter.m
//  WebTextScanner
//
//  Created by parak on 4/16/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import "WTURLFilter.h"
#import "HTMLNode.h"

@interface WTURLFilter()

@property NSArray *urlInvalidExtensions;
@property NSCharacterSet *urlAcceptableCharacters;

@end

@implementation WTURLFilter

- (instancetype)init {
    self = [super init];
    if (self) {
        self.urlInvalidExtensions = @[@".zip", @".pdf", @".gif", @".png", @".jpg", @".jpeg"];
        self.urlAcceptableCharacters = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%"];
    }
    return self;
}

- (NSArray *)getFilteredUrlsFromHTMLNode:(HTMLNode *)htmlNode withoutDuplicatesFromExistingUrlsDictionary:(NSDictionary *)existingUrlsDictionary {
    NSArray *allUrls = [self allUrlsFromHTMLNode:htmlNode];
    NSArray *filteredValidUrls = [self filterValidUrls:allUrls];
    NSArray *filteredDuplicateUrls = [self filterDuplicateUrls:filteredValidUrls];
    return [self filterDuplicateUrls:filteredDuplicateUrls fromExistingUrlsDictionary:existingUrlsDictionary];
}

- (NSArray *)allUrlsFromHTMLNode:(HTMLNode *)htmlNode {
    NSMutableArray *allUrls = [NSMutableArray array];
    
    NSArray *urlContent = [htmlNode findChildTags:@"a"];
    
    for (HTMLNode *urlNode in urlContent) {
        NSString *urlString = [urlNode getAttributeNamed:@"href"];
        if (urlString) {
            [allUrls addObject:urlString];
        }
    }
    
    return allUrls;
}

- (NSArray *)filterValidUrls:(NSArray *)urls {
    NSMutableArray *filteredUrls = [NSMutableArray array];
    
    for (NSString *urlString in urls) {
        if (urlString && [self validateUrlPrefix:urlString] && [self validateUrlSuffix:urlString] && [self validateUrlCharacters:urlString]) {
            [filteredUrls addObject:urlString];
        }
    }
    
    return filteredUrls;
}

- (BOOL)validateUrlPrefix:(NSString *)candidate {
    return [candidate hasPrefix:@"http://"];
}

- (BOOL)validateUrlSuffix:(NSString *)candidate {
    for (NSString *invalidExtension in self.urlInvalidExtensions) {
        if ([candidate hasSuffix:invalidExtension]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)validateUrlCharacters:(NSString *)candidate {
    /*
     //@"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
     //NSString *urlRegEx = @"http://(%|(\\w)*|%|([0-9]*)|([-|_|%|?|=])*)+([\\.|/](%|(\\w)*|%|([0-9]*)|([-|_|%|?|=])*))+";
     //NSString *urlRegEx = @"http?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&amp;=]*)?";
     NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
     return [urlTest evaluateWithObject:candidate];
     */
    
    NSCharacterSet *candidateStringCharacters = [NSCharacterSet characterSetWithCharactersInString:candidate];
    return [self.urlAcceptableCharacters isSupersetOfSet:candidateStringCharacters];
}

- (NSArray *)filterDuplicateUrls:(NSArray *)urls {
    return [NSSet setWithArray:urls].allObjects;
}

- (NSArray *)filterDuplicateUrls:(NSArray *)urls fromExistingUrlsDictionary:(NSDictionary *)existingUrlsDictionary {
    NSMutableArray *filteredUrls = [NSMutableArray array];
    
    for (NSString *urlString in urls) {
        if (![existingUrlsDictionary objectForKey:urlString]) {
            [filteredUrls addObject:urlString];
        }
    }
    
    return filteredUrls;
}

@end
