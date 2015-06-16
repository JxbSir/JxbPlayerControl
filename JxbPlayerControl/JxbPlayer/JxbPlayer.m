//
//  JxbPlayer.m
//  VOA
//
//  Created by Peter on 15/6/1.
//  Copyright (c) 2015年 Peter. All rights reserved.
//

#import "JxbPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioSession.h>

#define playerScale         44100
#define playerIconWidth     36
#define playerFont          [UIFont systemFontOfSize:16]


@implementation NSString (Size)
- (CGSize)textSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize textSize;
    if (CGSizeEqualToSize(size, CGSizeZero))
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        textSize = [self sizeWithAttributes:attributes];
    }
    else
    {
        NSStringDrawingOptions option = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
        //NSStringDrawingTruncatesLastVisibleLine如果文本内容超出指定的矩形限制，文本将被截去并在最后一个字符后加上省略号。 如果指定了NSStringDrawingUsesLineFragmentOrigin选项，则该选项被忽略 NSStringDrawingUsesFontLeading计算行高时使用行间距。（译者注：字体大小+行间距=行高）
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
        CGRect rect = [self boundingRectWithSize:size
                                         options:option
                                      attributes:attributes
                                         context:nil];
        
        textSize = rect.size;
    }
    return textSize;
}
@end

@interface JxbPlayer()<AVAudioSessionDelegate>
@property(nonatomic,copy)UIColor        *maincolor;
@property(nonatomic,strong)AVPlayer     *avPlayer;
@property(nonatomic,strong)AVPlayerItem *avItem;
@property(nonatomic,strong)NSTimer      *avTimer;
@property(nonatomic,assign)BOOL         bBegin;
@property(nonatomic,assign)BOOL         bStop;
@property(nonatomic,assign)BOOL         bSliderDragging;
@property(nonatomic,assign)BOOL         bPausing;
@property(nonatomic,assign)BOOL         bLoadFinish;

@property(nonatomic,strong)UIButton     *btnPlay;
@property(nonatomic,strong)UIButton     *btnNext;
@property(nonatomic,strong)UIButton     *btnBack;
@property(nonatomic,strong)UILabel      *lblPlayTime;
@property(nonatomic,strong)UILabel      *lblAllTime;
@property(nonatomic,strong)UISlider     *slider;
@property(nonatomic,strong)UIView       *vDownProgress;
@end

@implementation JxbPlayer

- (void)dealloc {
    [_avItem removeObserver:self forKeyPath:@"status"];
    [_avItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (id)initWithMainColor:(UIColor*)color frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:[AVAudioSession sharedInstance]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionRouteChangeNotification
                                                   object:[AVAudioSession sharedInstance]];
        
        _maincolor = color;
        [self setUI];
    }
    return self;
}

- (void)setUI {
    UIView* vline = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 0.5)];
    vline.backgroundColor = [UIColor colorWithRed:250/255. green:250/255. blue:250/255. alpha:1];
    [self addSubview:vline];
    
    _btnPlay = [[UIButton alloc] initWithFrame:CGRectMake((self.frame.size.width - playerIconWidth - 10) / 2, 0, playerIconWidth + 10, playerIconWidth + 10)];
    [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_play"] tintColor:_maincolor] forState:UIControlStateNormal];
    [_btnPlay addTarget:self action:@selector(btnPauseAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnPlay];
    
    _btnNext = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 + playerIconWidth + 15, 5, playerIconWidth, playerIconWidth)];
    [_btnNext setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_next"] tintColor:_maincolor] forState:UIControlStateNormal];
    [_btnNext addTarget:self action:@selector(btnNextAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnNext];
    
    _btnBack = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - playerIconWidth * 2 - 15, 5, playerIconWidth, playerIconWidth)];
    [_btnBack setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_back"] tintColor:_maincolor] forState:UIControlStateNormal];
    [_btnBack addTarget:self action:@selector(btnBackAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnBack];
    
    CGSize s = [@"00:00" textSizeWithFont:playerFont constrainedToSize:CGSizeMake(MAXFLOAT, 999) lineBreakMode:NSLineBreakByCharWrapping];
    
    _lblPlayTime = [[UILabel alloc] initWithFrame:CGRectMake(20, 5 + (playerIconWidth - s.height) / 2, s.width, s.height)];
    _lblPlayTime.font = playerFont;
    _lblPlayTime.text = @"00:00";
    _lblPlayTime.textColor = _maincolor;
    [self addSubview:_lblPlayTime];
    
    _lblAllTime = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 20 - s.width, 5 + (playerIconWidth - s.height) / 2, s.width, s.height)];
    _lblAllTime.font = playerFont;
    _lblAllTime.text = @"00:00";
    _lblAllTime.textColor = _maincolor;
    [self addSubview:_lblAllTime];
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(20, playerIconWidth + 20, self.frame.size.width - 40, 10)];
    _slider.minimumValue = 0;
    _slider.maximumValue = 1;
    [_slider setMinimumTrackTintColor:_maincolor];
    [_slider setMaximumTrackTintColor:[UIColor colorWithRed:200/255. green:200/255. blue:200/255. alpha:0.3]];
    [_slider setThumbTintColor:_maincolor];
    [_slider addTarget:self action:@selector(slideValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(sliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:_slider];
    
    _vDownProgress = [[UIView alloc] initWithFrame:CGRectMake(2, 4, 0, 2)];
    _vDownProgress.backgroundColor = [UIColor lightGrayColor];
    _vDownProgress.layer.cornerRadius = 1;
    [_slider addSubview:_vDownProgress];
}

- (void)stop {
    [_avPlayer pause];
    if(_avTimer)
    {
        [_avTimer invalidate];
        _avTimer = nil;
    }
    if(_delegate && [_delegate respondsToSelector:@selector(XBPlayer_stop)])
        [_delegate XBPlayer_stop];
}

- (void)play {
    if(!_itemUrl)
        return;
    NSURL * songUrl = nil;
    if ([_itemUrl rangeOfString:@"http:"].length > 0)
        songUrl = [NSURL URLWithString:_itemUrl];
    else
    {
        songUrl = [[NSURL alloc] initFileURLWithPath:_itemUrl];
    }
    AVURLAsset *movieAsset    = [[AVURLAsset alloc]initWithURL:songUrl options:nil];
    _avItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    [_avItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [_avItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    _avPlayer = [[AVPlayer alloc] initWithPlayerItem:_avItem];
    [_avPlayer play];
    
    //loading
    [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_refresh"] tintColor:_maincolor] forState:UIControlStateNormal];
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnimation.repeatCount = INFINITY;
    rotateAnimation.byValue = @(M_PI*2);
    rotateAnimation.duration = 1.5;
    [_btnPlay.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
}

- (void)playing {
    NSTimeInterval avDuration = [self playableDuration];
    if (avDuration > 0)
    {
        _lblAllTime.text = [self convertToMM:avDuration];
        
        NSArray* down = _avPlayer.currentItem.loadedTimeRanges;
        CMTimeRange range = [[down objectAtIndex:0] CMTimeRangeValue];
        double download = range.duration.value / range.duration.timescale;
        _vDownProgress.frame = CGRectMake(2, 4, download / avDuration * _slider.frame.size.width, 2);
    }
    NSTimeInterval avPlayTime = [self playableCurrentTime];
    if (!_bSliderDragging && avPlayTime > 0)
    {
        _lblPlayTime.text = [self convertToMM:avPlayTime];
    }
    if (!_bSliderDragging && avPlayTime > 0 && avDuration > 0)
    {
        CGFloat percent = avPlayTime / avDuration;
        [_slider setValue:percent animated:YES];
    }
    
    if(_delegate && [_delegate respondsToSelector:@selector(XBPlayer_playDuration:)])
        [_delegate XBPlayer_playDuration:avPlayTime];
    
    if (avDuration == avPlayTime)
    {
        [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_play"] tintColor:_maincolor] forState:UIControlStateNormal];
        _bStop = YES;
        if(_avTimer)
        {
            [_avTimer invalidate];
            _avTimer = nil;
        }
        return;
    }
    if(_avTimer)
    {
        [_avTimer invalidate];
        _avTimer = nil;
    }
    _avTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playing) userInfo:nil repeats:YES];
}

- (NSString*)convertToMM:(NSTimeInterval)t {
    int m = t / 60;
    int s = (int)t % 60;
    NSString* mStr = [NSString stringWithFormat:(m < 10 ? @"0%d" : @"%d"),m];
    NSString* sStr = [NSString stringWithFormat:(s < 10 ? @"0%d" : @"%d"),s];
    return [NSString stringWithFormat:@"%@:%@",mStr,sStr];
}

#pragma mark - back && next
- (void)btnPauseAction {
    if (!_bBegin)
    {
        _bBegin = YES;
        [self play];
        if(_delegate && [_delegate respondsToSelector:@selector(XBPlayer_play)])
            [_delegate XBPlayer_play];
        return;
    }
    else if (_bStop) {
        _bStop = NO;
        [_avPlayer seekToTime:CMTimeMakeWithSeconds(0, playerScale)];
        [_avPlayer play];
        [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_pause"] tintColor:_maincolor] forState:UIControlStateNormal];
        return;
    }
    else if (_bPausing) {
        [_avPlayer play];
        [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_pause"] tintColor:_maincolor] forState:UIControlStateNormal];
        if(_avTimer)
        {
            [_avTimer invalidate];
            _avTimer = nil;
        }
        _avTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playing) userInfo:nil repeats:YES];
    }
    else {
        [_avPlayer pause];
        [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_play"] tintColor:_maincolor] forState:UIControlStateNormal];
        if(_delegate && [_delegate respondsToSelector:@selector(XBPlayer_pause)])
            [_delegate XBPlayer_pause];
        if(_avTimer)
        {
            [_avTimer invalidate];
            _avTimer = nil;
        }
    }
    _bPausing = !_bPausing;
}

- (void)btnBackAction {
    if (!_bLoadFinish || _bStop)
        return;
    int t = [self playableCurrentTime];
    if(t >=0)
    {
        if(_avTimer)
        {
            [_avTimer invalidate];
            _avTimer = nil;
        }
        _avTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playing) userInfo:nil repeats:YES];
        [_avPlayer seekToTime:CMTimeMakeWithSeconds((t-20), playerScale)];
    }
}

- (void)btnNextAction {
    if (!_bLoadFinish || _bStop)
        return;
    int t = [self playableCurrentTime];
    if(t >=0)
    {
        if(_avTimer)
        {
            [_avTimer invalidate];
            _avTimer = nil;
        }
        _avTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playing) userInfo:nil repeats:YES];
        [_avPlayer seekToTime:CMTimeMakeWithSeconds((t+20), playerScale)];
    }
}

#pragma mark - get AVPlayerItem info
- (NSTimeInterval)playableDuration
{
    AVPlayerItem * item = _avPlayer.currentItem;
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds(_avPlayer.currentItem.duration);
    }
    else
    {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}

- (NSTimeInterval)playableCurrentTime
{
    AVPlayerItem * item = _avPlayer.currentItem;
    if (item.status == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds(_avPlayer.currentItem.currentTime);
    }
    else
    {
        return(CMTimeGetSeconds(kCMTimeInvalid));
    }
}

#pragma mark - uislide
- (void)slideValueChanged:(UISlider*)slider {
    NSLog(@"%f",slider.value);
    int t = [self playableDuration] * slider.value;
    if(t > 0)
    {
        _lblPlayTime.text = [self convertToMM:t];
    }
}

- (void)sliderTouchDown:(UISlider*)slider {
    NSLog(@"sliderTouchDown");
    _bSliderDragging = YES;
}

- (void)sliderTouchUp:(UISlider*)slider {
    NSLog(@"sliderTouchUp");
    
    if(_avTimer)
    {
        [_avTimer invalidate];
        _avTimer = nil;
    }
    
    int t = [self playableDuration] * slider.value;
    t  = t < 0 ? 0 : t;
    [_avPlayer seekToTime:CMTimeMakeWithSeconds(t, playerScale) completionHandler:^(BOOL bFinish){
        if(bFinish){
            _bSliderDragging = NO;
            _avTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playing) userInfo:nil repeats:YES];
        }
    }];
}

#pragma mark - observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerItem* item = (AVPlayerItem*)object;
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            _bLoadFinish = YES;
            [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_pause"] tintColor:_maincolor] forState:UIControlStateNormal];
            [_btnPlay.layer removeAllAnimations];
            [self playing];
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        
    }
}

#pragma mark - AvAudioNotificaion
- (void)handleInterruption:(NSNotification*)noti {
    [_btnPlay setImage:[self imageWithTintColor:[UIImage imageNamed:@"icon_play"] tintColor:_maincolor] forState:UIControlStateNormal];
    if(_delegate && [_delegate respondsToSelector:@selector(XBPlayer_pause)])
        [_delegate XBPlayer_pause];
    _bPausing = YES;
}

#pragma mark - UIImage
- (UIImage *)imageWithTintColor:(UIImage*)img tintColor:(UIColor *)tintColor
{
    //We want to keep alpha, set opaque to NO; Use 0.0f for scale to use the scale factor of the device’s main screen.
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, img.size.width, img.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [img drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}
@end
