//
//  RMWordManager.h
//  RMixedTool
//
//  Created by ron on 2021/6/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RMWordManager : NSObject{
    
}

+(RMWordManager *)shareManager;
-(BOOL)isExcudleWord:(NSString *)word;
-(BOOL)isExcudlePathFile:(NSString *)path;

-(void)addExcudeWords:(NSArray *)words;
-(NSString *)generalNewWord:(int)type;
@end

NS_ASSUME_NONNULL_END
