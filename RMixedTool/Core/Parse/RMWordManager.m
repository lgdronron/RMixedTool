//
//  RMWordManager.m
//  RMixedTool
//
//  Created by ron on 2021/6/25.
//

#import "RMWordManager.h"

@interface RMWordManager(){
    NSArray * _arrayOfExcudle;
    NSArray * _arrayOfShort;
    NSArray * _arrayOfMiddles;
    NSArray * _arrayOfLong;
    NSArray * _arrayOfReserved;
    NSArray * _arrayOfProgramer;
}
@end

@implementation RMWordManager
static RMWordManager* shareManager = nil;
+(RMWordManager *)shareManager{
    if(shareManager == nil){
        shareManager = [[RMWordManager alloc] init];
    }
    return shareManager;
}
-(instancetype)init{
    if(self = [super init]){
        NSString *path = [[NSBundle mainBundle] resourcePath];
        NSLog(@"resourcePath %@",path);
        NSString *content_short = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/short.txt"] encoding:NSUTF8StringEncoding error:nil];
        _arrayOfShort = [content_short componentsSeparatedByString:@"\n"];
        
        NSString *content_middle = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/mid.txt"] encoding:NSUTF8StringEncoding error:nil];
        _arrayOfMiddles = [content_middle componentsSeparatedByString:@"\n"];
        
        NSString *content_long = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/long.txt"] encoding:NSUTF8StringEncoding error:nil];
        _arrayOfLong = [content_long componentsSeparatedByString:@"\n"];
        
//        NSMutableArray *_array = [NSMutableArray array];
//        int istart = 0;
//        int file_number = 0;
//        for(int i =0;i<_arrayOfShort.count;i++){
//
//            for(int j = 0;j<_arrayOfMiddles.count;j++){
//                for(int k = 0;k<_arrayOfLong.count;k++){
//                    NSString *f = [_arrayOfShort objectAtIndex:arc4random()%_arrayOfShort.count];
//                    NSString *m = [_arrayOfMiddles objectAtIndex:arc4random()%_arrayOfMiddles.count];
//                    NSString *l = [_arrayOfLong objectAtIndex:arc4random()%_arrayOfLong.count];
//
//                    [_array addObject:[NSString stringWithFormat:@"%@%@%@",f,m,l]];
//                    istart ++;
//                    if(istart % 4000 == 0){
//                        if(file_number<20){
//                            NSMutableString *result = [NSMutableString string];
//                            for (NSString *s in _array) {
//                                [result appendString:s];
//                                [result appendString:@"\n"];
//                            }
//                            NSString *file = [NSString stringWithFormat:@"%@/%i.txt",@"/Users/ron/Desktop/words/",file_number];
//                            [result writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
//                            [_array removeAllObjects];
//                            file_number++;
//                        }
//                    }
//                }
//            }
//        }
        
        NSString *content_programer = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/Programmer_word.txt"] encoding:NSUTF8StringEncoding error:nil];
        _arrayOfProgramer = [content_programer componentsSeparatedByString:@"\n"];
        
        NSString *content_reservered = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/ReservedKeywords.txt"] encoding:NSUTF8StringEncoding error:nil];
        _arrayOfReserved = [content_reservered componentsSeparatedByString:@"\n"];
        
        NSString *content_white = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/systemWhiteList.txt"] encoding:NSUTF8StringEncoding error:nil];
        NSArray *wh = [content_white componentsSeparatedByString:@"\n"];
        
        NSString *content_white_2 = [NSString stringWithContentsOfFile:[path stringByAppendingFormat:@"/systemWord.txt"] encoding:NSUTF8StringEncoding error:nil];
        NSArray *wh2 = [content_white_2 componentsSeparatedByString:@"\n"];
        
        NSMutableArray *arWhite = [NSMutableArray array];
        [arWhite addObjectsFromArray:wh];
        [arWhite addObjectsFromArray:wh2];
        
        _arrayOfExcudle = arWhite;
        
        
        
    }
    return self;
}
-(void)addExcudeWords:(NSArray *)words{
    if(_arrayOfExcudle){
       _arrayOfExcudle =  [_arrayOfExcudle arrayByAddingObjectsFromArray:words];
    }
}
-(BOOL)isExcudleWord:(NSString *)_word{
    for (NSString *word in _arrayOfExcudle) {
        
        if([word isEqualToString:_word]){
           
            return true;
        }
    }
    return false;
}
-(BOOL)isExcudlePathFile:(NSString *)path{
    for (NSString *word in _arrayOfExcudle) {
        NSArray *ar = [path componentsSeparatedByString:@"/"];
        if (ar.count > 0){
            if ([ar.lastObject isEqualToString:word]){
                return true;
            }
        }
    }
    return false;
}
-(NSString *)generalNewWord:(int)type{
    if(type == 0){
        //
        NSString *str = [_arrayOfProgramer objectAtIndex: arc4random()%_arrayOfProgramer.count];
        NSString *str2 = [_arrayOfMiddles objectAtIndex:arc4random()%_arrayOfMiddles.count];
        return [NSString stringWithFormat:@"%@%@",str,str2];
    }
    
    if(type == 1){
        //
        NSString *str = [_arrayOfShort objectAtIndex:arc4random()%_arrayOfShort.count];
        NSString *str2 = [_arrayOfProgramer objectAtIndex:arc4random()%_arrayOfProgramer.count];
        return [NSString stringWithFormat:@"%@%@",str,str2];
    }
    
    if(type == 2){
        //
        NSString *str = [_arrayOfLong objectAtIndex:arc4random()%_arrayOfLong.count];
        NSString *str2 = [_arrayOfProgramer objectAtIndex:arc4random()%_arrayOfProgramer.count];
        return [NSString stringWithFormat:@"%@%@",str,str2];
    }
    return @"";
}
@end
