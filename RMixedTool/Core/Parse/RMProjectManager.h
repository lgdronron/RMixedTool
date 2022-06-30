//
//  RMProjectManager.h
//  RMixedTool
//
//  Created by ron on 2021/6/25.
//

#import <Foundation/Foundation.h>
#import "RMProjectParser.h"
#import "RMSourceScanner.h"
NS_ASSUME_NONNULL_BEGIN

@interface RMProjectManager : NSObject
+(RMProjectManager *)shareManager;

-(void)config:(NSString *)projectDir;
-(void)startAnalyse:(void (^)(NSError * error,NSArray* targets))result;
-(NSDictionary*)generalOrUpdateMixConfigFile:(NSString *)config target:(NSString *)targetName;
-(void)beginMixed;
-(void)addExcueWords:(NSArray *)ars;
@end

NS_ASSUME_NONNULL_END
