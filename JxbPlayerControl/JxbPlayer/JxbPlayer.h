//
//  JxbPlayer.h
//  VOA
//
//  Created by Peter on 15/6/1.
//  Copyright (c) 2015年 Peter. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (Size)
- (CGSize)textSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode;
@end

@protocol JxbPlayerDelegate <NSObject>
- (void)XBPlayer_play;
- (void)XBPlayer_pause;
- (void)XBPlayer_stop;
- (void)XBPlayer_playDuration:(NSTimeInterval)duration;
@end

@interface JxbPlayer : UIControl
@property(nonatomic,assign)id<JxbPlayerDelegate> delegate;
/**
 *  set mp3 url
 */
@property(nonatomic,copy)NSString* itemUrl;


- (id)initWithMainColor:(UIColor*)color frame:(CGRect)frame;

/**
 *  start play
 */
- (void)play;

/**
 *  stop play
 */
- (void)stop;
@end
