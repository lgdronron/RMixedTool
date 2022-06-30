//
//  RMProjectParser.h
//  RMixedTool
//
//  Created by ron on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RMProjectParser : NSObject

+(RMProjectParser *)shareParser;

-(NSDictionary *)parseProjectConfig:(NSString *)filePath;
-(NSArray *)getTargetsInfo;
@end

NS_ASSUME_NONNULL_END
