//
//  WTSearchManager.h
//  WebTextScanner
//
//  Created by parak on 4/3/15.
//  Copyright (c) 2015 parak. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WTSearchManager;

/**
 *  Protocol for WTSearchManager delegate.
 */
@protocol WTSearchManagerDelegate <NSObject>

@optional

/**
 *  Will notify delegate about starting creating content.
 *
 *  @param manager Data manager instance.
 */
//- (void)dataManagerDidStartLoadingContent:(WTSearchManager *)manager;

/**
 *  Will notify delegate about finishing creating content.
 *
 *  @param manager Data manager instance.
 *  @param content Created content.
 */
//- (void)dataManager:(WTSearchManager *)manager didFinishLoadingContent:(NSArray *)content;

@end

@interface WTSearchManager : NSObject

- (void)searchWebTextForUrl:(NSString *)searchUrl
     maxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount
                 searchText:(NSString *)searchText
          maxSearchUrlCount:(NSInteger)maxSearchUrlCount;

/*
1.	Стартовый url
2.	Максимальное количество потоков
3.	Искомый текст
4.	Максимальное количество сканируемых url
*/

@end
