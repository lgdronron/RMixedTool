//
//  RMSourceScanner.h
//  RMixedTool
//
//  Created by ron on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RMSourceScanner : NSObject{
    
}
@property(nonatomic,strong)NSMutableArray *arrayOfClassName;
@property(nonatomic,strong)NSMutableArray *arrayOfPropertys;
@property(nonatomic,strong)NSMutableArray *arrayOfMethods;



@property(nonatomic,strong)NSString *strFilePath;
-(RMSourceScanner *)initWithPath:(NSString *)filePath;
-(BOOL)scan:(BOOL)isGeneralNew;
@end

NS_ASSUME_NONNULL_END
