//
//
//      _|          _|_|_|
//      _|        _|
//      _|        _|
//      _|        _|
//      _|_|_|_|    _|_|_|
//
//
//  Copyright (c) 2014-2015, Licheng Guo. ( http://nsobject.me )
//  http://github.com/titman
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//


#import "LCPhotoBrowser.h"

@import ImageIO;

#ifndef	weakly
#if __has_feature(objc_arc)
#define weakly( x )	autoreleasepool{} __weak __typeof__(x) __weak_##x##__ = x;
#else
#define weakly( x )	autoreleasepool{} __block __typeof__(x) __block_##x##__ = x;
#endif
#endif

#ifndef	normally
#if __has_feature(objc_arc)
#define normally( x )	try{} @finally{} __typeof__(x) x = __weak_##x##__;
#else
#define normally( x )	try{} @finally{} __typeof__(x) x = __block_##x##__;
#endif
#endif

#pragma mark - LCPhotoView
#pragma mark -

@interface LCPhotoView () <UIScrollViewDelegate>

@property(nonnull, nonatomic, strong)  UIActivityIndicatorView * activityIndicatorView;

@property(nullable, nonatomic, weak)    LCPhotoBrowser       * browser;
@property(nonnull,  nonatomic, strong)  UIProgressView       * progressView;
@property(nullable, nonatomic, strong)  NSTimer              * timer;
@property(nullable, nonatomic, weak)    NSURLSessionDataTask * taskCache;
@property(nonnull,  nonatomic, strong)  UIImageView          * imageView;

@end

@implementation LCPhotoView

#pragma mark - Designated initializer
#pragma mark -

-(void) dealloc
{
    [self.taskCache cancel];
}

-(instancetype) init
{
    if(self = [super initWithFrame:CGRectZero]){
        
        [self initSelf];
    }
    
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame
{
    return [self init];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    return [self init];
}

-(void) initSelf
{
    self.frame                          = [UIApplication sharedApplication].keyWindow.frame;
    self.delegate                       = self;
    self.contentMode                    = UIViewContentModeScaleAspectFit;
    self.minimumZoomScale               = 1;
    self.maximumZoomScale               = 2;
    self.showsVerticalScrollIndicator   = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.contentSize                    = self.bounds.size;

    
    self.imageView                        = [[UIImageView alloc] init];
    self.imageView.contentMode            = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    self.imageView.frame                  = self.bounds;
    self.imageView.center                 = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    [self addSubview:self.imageView];
    
    
    self.progressView                = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.progress       = 0;
    self.progressView.tintColor      = [UIColor whiteColor];
    self.progressView.trackTintColor = [UIColor darkGrayColor];
    self.progressView.center = self.imageView.center;

    CGRect progressFrame     = self.progressView.frame;
    progressFrame.size.width = 128.0f;
    
    self.progressView.frame  = progressFrame;
    self.progressView.alpha  = 0;
    self.progressView.hidden = YES;
    [self addSubview:self.progressView];
    
    
    self.activityIndicatorView        = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicatorView.alpha  = 0;
    self.activityIndicatorView.center = self.imageView.center;
    self.activityIndicatorView.hidesWhenStopped = NO;
    [self.activityIndicatorView startAnimating];
    self.activityIndicatorView.hidden = YES;
    [self addSubview:self.activityIndicatorView];
}

#pragma mark - Delegate
#pragma mark -

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    // Fix center.
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}


#pragma mark - Overwrite
#pragma mark -

-(void) removeFromSuperview
{
    [self cancelTimer];

    [super removeFromSuperview];
}

-(void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // Fix contentSize.
    self.contentSize = CGSizeMake(
                                  self.imageView.frame.size.width < self.frame.size.width ? self.frame.size.width : self.imageView.frame.size.width,
                                  self.imageView.frame.size.height < self.frame.size.height ? self.frame.size.height : self.imageView.frame.size.height
                                  );
    
    self.imageView.center    = CGPointMake(self.contentSize.width / 2., self.contentSize.height / 2.);
    self.progressView.center = self.imageView.center;
}

-(void) setItem:(LCPhotoItem *)item
{
    // Not allowed to reuse.
    if (self.item) return;
    
    _item = item;

    // Get current image.
    if (item.placeholder) [self changeImage:item.placeholder];
    else if ([item.referenceView isKindOfClass:[UIImageView class]]) [self changeImage:((UIImageView *)item.referenceView).image];
    else if ([item.referenceView isKindOfClass:[UIButton class]])    [self changeImage:((UIButton *)item.referenceView).currentImage];

    UIImage * image = nil;
    
    // Load cache from others.
    if (LCPhotoBrowserActionTransfer.share.readImageFromCache) image = LCPhotoBrowserActionTransfer.share.readImageFromCache(item.urlString);
    
    if (image) {
        
        [self changeImage:image];
    }
    else{
        
        @weakly(self);
        
        // Downloading
        self.taskCache = [LCPhotoBrowserDownloader downloadImageForURL:[NSURL URLWithString:self.item.urlString] completion:^(UIImage * _Nullable image) {
           
            @normally(self);
            
            if (image) {
                
                [self cancelTimer];

                CATransition * transition = [CATransition animation];
                transition.type           = kCATransitionFade;
                transition.duration       = 0.25;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                [self.layer addAnimation:transition forKey:@"transition"];
                
                [self changeImage:image];
                
                if (self.taskCache) {
                    
                    if (self.browser.endDownloadAction) self.browser.endDownloadAction(self, self.tag);
                }
            }
        }];
        
        
        if (self.taskCache) {
            
            [self fireTimer];
            
            if (self.browser.beginDownloadAction) self.browser.beginDownloadAction(self, self.tag);
        }
    }
}

-(void) setBrowser:(LCPhotoBrowser *)browser
{
    _browser = browser;
    
    self.progressView.hidden          = browser.loadingStyle == LCPhotoBrowserLoadingStyleProgress ? NO : YES;
    self.activityIndicatorView.hidden = browser.loadingStyle == LCPhotoBrowserLoadingStyleActivityIndicator ? NO : YES;
}

#pragma mark - Actions


-(void) changeImage:(UIImage *)image
{
    self.imageView.image = image;
    
    self.imageView.frame  = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width / self.imageView.image.size.width * self.imageView.image.size.height);
    self.imageView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
}


-(void) fireTimer
{
    [self cancelTimer];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    
    [UIView animateWithDuration:0.25 animations:^{
       
        self.progressView.alpha          = 1;
        self.activityIndicatorView.alpha = 1;
    }];

    self.maximumZoomScale = 1;
}

-(void) cancelTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.progressView.alpha          = 0;
    self.activityIndicatorView.alpha = 0;
    self.maximumZoomScale            = 2;
}

-(void) timerHandler
{
    CGFloat progress = 0;
    CGFloat bytesExpected = self.taskCache.countOfBytesExpectedToReceive;
    
    if (bytesExpected > 0) {
        
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear animations:^{
            
            self.progressView.alpha          = 1;
            self.activityIndicatorView.alpha = 1;
            
        } completion:nil];
        
        progress = self.taskCache.countOfBytesReceived / bytesExpected;
    }
    
    self.progressView.progress = progress;
}

-(void) photoDoubleTapAction:(UITapGestureRecognizer *)tap
{
    if (self.zoomScale > 1.f)  [self setZoomScale:1 animated:YES];
    else                       [self setZoomScale:2 animated:YES];
}

@end

#pragma mark - LCPhotoItem
#pragma mark - 

@implementation LCPhotoItem

@end

#pragma mark - LCPhotoBrowserActionTransfer
#pragma mark -

@implementation LCPhotoBrowserActionTransfer

+ (instancetype) share
{
    static LCPhotoBrowserActionTransfer * p = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        p = [[[self class] alloc] init];
    });
    
    return p;
}

@end

#pragma mark - LCPhotoBrowser
#pragma mark -

@interface LCPhotoBrowser () <UIScrollViewDelegate>

@property(nonnull ,nonatomic, strong) NSMutableArray<LCPhotoView *> * imageViews;

@property(nonnull ,nonatomic, strong) UIScrollView * scrollView;
@property(nonnull ,nonatomic, strong) UIView * backgroundView;
@property(nonnull ,nonatomic, strong) UIVisualEffectView * backgroundBlurView;


@property(nonatomic, assign) BOOL firstShow;
@property(nonatomic, assign) BOOL willDisappear;

@end

@implementation LCPhotoBrowser

#pragma mark - Designated initializer

-(instancetype) init
{
    if(self = [super initWithFrame:CGRectZero]){
    
        [self initSelf];
    }
    
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame
{
    return [self init];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    return [self init];
}

#pragma mark - Setup

-(void) initSelf
{
    self.firstShow          = YES;
    self.frame              = [UIApplication sharedApplication].keyWindow.bounds;
    self.imageViewMargin    = 10;
    self.animationDuration  = 0.25;
    self.animationOptions   = UIViewAnimationOptionCurveEaseInOut;
    self.imageViews         = [NSMutableArray array];
    self.loadingStyle       = LCPhotoBrowserLoadingStyleProgress;
    
    self.backgroundView                 = [[UIView alloc] init];
    self.backgroundView.frame           = self.bounds;
    self.backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    [self addSubview:self.backgroundView];
    
    
    self.backgroundBlurView        = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.backgroundBlurView.frame  = self.bounds;
    self.backgroundBlurView.hidden = YES;
    [self addSubview:self.backgroundBlurView];
    
    
    self.scrollView                                = [[UIScrollView alloc] init];
    self.scrollView.delegate                       = self;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator   = NO;
    self.scrollView.pagingEnabled                  = YES;
    [self addSubview:self.scrollView];
}

#pragma mark - Overwrite

-(void) setBackgroundStyle:(LCPhotoBrowserBackgroundStyle)backgroundStyle
{
    _backgroundStyle = backgroundStyle;
    
    self.backgroundView.hidden     =  backgroundStyle;
    self.backgroundBlurView.hidden = !backgroundStyle;
}

-(void) setBackgroundBlurEffect:(UIBlurEffect *)backgroundBlurEffect
{
    self.backgroundBlurView.effect = backgroundBlurEffect;
}

-(void) setBackgroundColor:(UIColor *)backgroundColor
{
    self.backgroundView.backgroundColor = backgroundColor;
}

-(UIColor *) backgroundColor
{
    return self.backgroundView.backgroundColor;
}

-(void) setItems:(NSArray<LCPhotoItem *> *)items
{
    _items = [items mutableCopy];
    
    [self.items enumerateObjectsUsingBlock:^(LCPhotoItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        LCPhotoView * imageView = [[LCPhotoView alloc] init];
        imageView.browser = self;
        
        [self addRecognizersOnPhotoView:imageView];
        
        [self.scrollView addSubview:imageView];
        
        // .
        [self.imageViews addObject:imageView];
    }];
    
    
    [self setupImageViewForIndex:self.currentIndex];
}

-(void) addRecognizersOnPhotoView:(LCPhotoView *)photoView
{
    // Click.
    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoTapAction:)];
    
    // Double tap to zoom.
    UITapGestureRecognizer * doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoDoubleTapAction:)];
    doubleTap.numberOfTapsRequired = 2;
    
    // Conflict prevention.
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    // Long press.
    UILongPressGestureRecognizer * longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(photoLongPressAction:)];
    longPress.minimumPressDuration = 1.5;
    
    
    [photoView addGestureRecognizer:singleTap];
    [photoView addGestureRecognizer:doubleTap];
    [photoView addGestureRecognizer:longPress];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect rect      = self.bounds;
    rect.size.width += self.imageViewMargin * 2;
    
    _scrollView.bounds = rect;
    _scrollView.center = self.center;
    
    CGFloat y = 0;
    CGFloat w = _scrollView.frame.size.width - self.imageViewMargin * 2;
    CGFloat h = _scrollView.frame.size.height;
    
    
    [self.imageViews enumerateObjectsUsingBlock:^(LCPhotoView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        CGFloat x = self.imageViewMargin + idx * (self.imageViewMargin * 2 + w);
        obj.frame = CGRectMake(x, y, w, h);
        obj.tag = idx;
    }];
    

    _scrollView.contentSize   = CGSizeMake(_scrollView.subviews.count * _scrollView.frame.size.width, 0);
    _scrollView.contentOffset = CGPointMake(self.currentIndex * _scrollView.frame.size.width, 0);
}

-(void) relayoutSubViews
{
    [self animations:^{
        
        [self setNeedsLayout];
        
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Action

-(void) photoTapAction:(UITapGestureRecognizer *)tap
{
    [self hide];
}

-(void) photoDoubleTapAction:(UITapGestureRecognizer *)tap
{
    LCPhotoView * photoView = (LCPhotoView *)tap.view;
    
    [photoView photoDoubleTapAction:tap];
}

-(void) photoLongPressAction:(UILongPressGestureRecognizer *)longPress
{
    LCPhotoView * photoView = (LCPhotoView *)longPress.view;

    if (self.longPressAction) self.longPressAction(photoView, photoView.tag);
}

-(void) setupImageViewForIndex:(NSInteger)index
{
    LCPhotoView * imageView = self.imageViews[index];
    
    self.currentIndex = index;

    imageView.item = self.items[index];
    
    
    if (self.didSelectAction) self.didSelectAction(imageView, index);
}

-(void) show
{
    UIWindow * window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    
    self.backgroundView.alpha     = 0;
    self.backgroundBlurView.alpha = 0;
    
    //[window addObserver:self forKeyPath:@"frame" options:0 context:nil];
    [window addSubview:self];
    
    [UIView animateWithDuration:self.animationDuration animations:^{
       
        self.backgroundView.alpha     = 1;
        self.backgroundBlurView.alpha = 1;
    }];
    
    if (self.firstShow)
        [self showFirstImageView];
}

-(void) hide
{
    LCPhotoView * currentPhotoView = self.imageViews[self.currentIndex];

    if(!currentPhotoView.item.referenceView) {
        
        [self animations:^{
            
            self.alpha = 0;
            
        } completion:^(BOOL finished) {
           
            [self removeFromSuperview];
        }];
        
        return;
    }
    
    // Conver rect to window.
    CGRect rect = [currentPhotoView.item.referenceView.superview convertRect:currentPhotoView.item.referenceView.frame toView:self];
    
    [self animations:^{
        
        currentPhotoView.zoomScale = 1.;
        currentPhotoView.imageView.frame     = rect;
        currentPhotoView.progressView.hidden = YES;
        
        currentPhotoView.imageView.layer.cornerRadius = currentPhotoView.item.referenceView.layer.cornerRadius;
        currentPhotoView.imageView.contentMode        = currentPhotoView.item.referenceView.contentMode;
        
    } completion:^(BOOL finished) {
        
        [self animations:^{
            
            currentPhotoView.alpha        = 0;
            self.backgroundView.alpha     = 0;
            self.backgroundBlurView.alpha = 0;
            
        } completion:^(BOOL finished) {
            
            [self removeFromSuperview];
        }];
    }];
}

-(void) showFirstImageView
{
    LCPhotoView * currentPhotoView = self.imageViews[self.currentIndex];

    // Non reference view.
    if (!currentPhotoView.item.referenceView) {
        
        currentPhotoView.alpha = 0;
        
        [self animations:^{
            
            currentPhotoView.alpha = 1;
            
        } completion:^(BOOL finished) {
           
            self.firstShow = NO;
            
        }];
        
        return;
    };
    
    // Conver rect to window.
    CGRect rect = [currentPhotoView.item.referenceView.superview convertRect:currentPhotoView.item.referenceView.frame toView:nil];
    
    LCPhotoItem * item = self.items[self.currentIndex];
    
    // To rect.
    CGRect targetFrame = currentPhotoView.imageView.frame;
    UIViewContentMode contentMode = currentPhotoView.imageView.contentMode;
    
    currentPhotoView.imageView.frame              = rect;
    currentPhotoView.imageView.layer.cornerRadius = item.referenceView.layer.cornerRadius;
    currentPhotoView.imageView.contentMode        = item.referenceView.contentMode;
    

    [self animations:^{
        
        currentPhotoView.imageView.center             = self.center;
        currentPhotoView.imageView.bounds             = targetFrame;
        currentPhotoView.imageView.layer.cornerRadius = 0;
        currentPhotoView.imageView.contentMode        = contentMode;
        
    } completion:^(BOOL finished) {
       
        self.firstShow = NO;
    }];
}

-(void) deletePhotoAtIndex:(NSInteger)index
{
    NSMutableArray * items = (NSMutableArray *)self.items;

    [items removeObjectAtIndex:index];
    
    LCPhotoView * imageView = self.imageViews[index];
    
    [self animations:^{
        
        imageView.alpha = 0;
        
    } completion:^(BOOL finished) {
       
        [self.imageViews removeObjectAtIndex:index];
        
        [self relayoutSubViews];
        
    }];
}

-(void) insertPhotoItem:(LCPhotoItem *)item atIndex:(NSInteger)index
{
    NSMutableArray * items = (NSMutableArray *)self.items;
    
    [items insertObject:item atIndex:index];
    
    // Create new view.
    LCPhotoView * imageView = [[LCPhotoView alloc] init];
    imageView.browser = self;

    imageView.item = item;
    imageView.alpha = 0;
    
    [self addRecognizersOnPhotoView:imageView];
    
    [self.scrollView addSubview:imageView];
    
    [self.imageViews insertObject:imageView atIndex:index];
    
    [self relayoutSubViews];
    
    [self animations:^{
        
        imageView.alpha = 1;
        
    } completion:^(BOOL finished) {
       
        [self.scrollView scrollRectToVisible:imageView.frame animated:YES];
    }];
}

-(void) animations:(void (^)(void))animations completion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView animateWithDuration:self.animationDuration delay:0 options:self.animationOptions animations:^{
        
        if (animations) animations();
        
    } completion:^(BOOL finished) {
       
        if (completion) completion(finished);
        
    }];
}

#pragma mark - UIScrollView delegate
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int index = (scrollView.contentOffset.x + _scrollView.bounds.size.width * 0.5) / _scrollView.bounds.size.width;
    
    // Don't forget clear zoom.
    CGFloat margin = self.frame.size.width / 2.;
    CGFloat x = scrollView.contentOffset.x;
    
    if ((x - index * self.bounds.size.width) > margin || (x - index * self.bounds.size.width) < - margin) {
        
        LCPhotoView * photoView = self.imageViews[index];
        
        [photoView setZoomScale:1 animated:YES];
    }
    
    [self setupImageViewForIndex:index];
}

@end

#pragma mark - LCAnimatedGIFUtility
#pragma mark -

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

@implementation LCAnimatedGIFUtility

+ (BOOL)imageURLIsAGIF:(NSString *)imageURL
{
    if (imageURL.length < 4) {
        
        return  NO;
    }
    
    return [[imageURL substringFromIndex:[imageURL length] - 3] isEqualToString:@"gif"];
}

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i)
{
    int delayCentiseconds = 1;
    
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    
    if (properties) {
        
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        CFRelease(properties);
        
        if (gifProperties) {
            
            // kCGImagePropertyGIFUnclampedDelayTime appears to be what should be used instead of kCGImagePropertyGIFDelayTime JG 5/1/2013
            CFNumberRef const number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            
            // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
            delayCentiseconds = (int)lrint([fromCF number doubleValue] * 100.0);
        }
    }
    
    return delayCentiseconds;
}

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count])
{
    for (size_t i = 0; i < count; ++i) {
        
        imagesOut[i]            = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values)
{
    int theSum = 0;
    
    for (size_t i = 0; i < count; ++i) {
        
        theSum += values[i];
    }
    
    return theSum;
}

static int pairGCD(int a, int b)
{
    if (b == 0)
        return a;
    
    if (a < b)
        return pairGCD(b, a);
    
    while (true) {
        
        int const r = a % b;
        
        if (r == 0)
            return b;
        
        a = b;
        b = r;
    }
}

static int vectorGCD(size_t const count, int const *const values)
{
    int gcd = values[0];
    
    for (size_t i = 1; i < count; ++i) {
        
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    
    return gcd;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds)
{
    int const gcd = vectorGCD(count, delayCentiseconds);
    
    size_t const frameCount = totalDurationCentiseconds / gcd;
    
    UIImage *frames[frameCount];
    
    for (size_t i = 0, f = 0; i < count; ++i) {
        
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static void releaseImages(size_t const count, CGImageRef const images[count])
{
    for (size_t i = 0; i < count; ++i) {
        CGImageRelease(images[i]);
    }
}

static UIImage *animatedImageWithAnimatedGIFImageSource(CGImageSourceRef const source)
{
    size_t const count = CGImageSourceGetCount(source);
    CGImageRef images[count];
    int delayCentiseconds[count]; // in centiseconds
    createImagesAndDelays(source, count, images, delayCentiseconds);
    int const totalDurationCentiseconds = sum(count, delayCentiseconds);
    UIImage *image = nil;
    if (totalDurationCentiseconds == 0 || count == 1) {
        // This can't be animated, so don't bother trying to create an animated image.
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        if (imageRef) {
            image = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
    } else {
        NSArray *const frames = frameArray(count, images, delayCentiseconds, totalDurationCentiseconds);
        UIImage *const animation = [UIImage animatedImageWithImages:frames duration:(NSTimeInterval)totalDurationCentiseconds / 100.0];
        releaseImages(count, images);
        image = animation;
    }
    return image;
}

static UIImage *animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceRef source CF_CONSUMED)
{
    if (source) {
        UIImage *const image = animatedImageWithAnimatedGIFImageSource(source);
        CFRelease(source);
        return image;
    } else {
        return nil;
    }
}

+ (UIImage *)animatedImageWithAnimatedGIFData:(NSData *)data
{
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithData(toCF data, NULL));
}

+ (UIImage *)animatedImageWithAnimatedGIFURL:(NSURL *)url
{
    return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithURL(toCF url, NULL));
}

@end

#pragma mark - LCPhotoBrowserDownloader
#pragma mark -

@implementation  LCPhotoBrowserDownloader

+ (nullable NSURLSessionDataTask *)downloadImageForURL:(nonnull NSURL *)imageURL
                                            completion:(void(^ _Nullable)( UIImage * _Nullable image))completion
{
    if (!imageURL.absoluteString.length) {
        return nil;
    }
    
    NSURLSessionDataTask * dataTask = nil;
    
    
    UIImage * image = nil;
    
    if (LCPhotoBrowserActionTransfer.share.readImageFromCache) {
        
        LCPhotoBrowserActionTransfer.share.readImageFromCache(imageURL.absoluteString);
    }
    
    if (image) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(image);
            }
        });
    }
    else {
        
        NSURLRequest * request = [NSURLRequest requestWithURL:imageURL];
        
        if (request == nil) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
        }
        else {
            
            NSURLSession * session = [NSURLSession sharedSession];
            
            dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    UIImage * image = [self imageFromData:data forURL:imageURL];
                    
                    if (LCPhotoBrowserActionTransfer.share.downloadDidFinished) {
                        
                        LCPhotoBrowserActionTransfer.share.downloadDidFinished(imageURL.absoluteString, image);
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (completion) {
                            completion(image);
                        }
                    });
                });
            }];
            
            [dataTask resume];
        }
    }
    
    return dataTask;
}

+(UIImage *) imageFromData:(NSData *)data forURL:(NSURL *)imageURL
{
    UIImage * image = nil;
    
    if (data) {
        
        NSString * urlString = imageURL.absoluteString;
        
        if ([LCAnimatedGIFUtility imageURLIsAGIF:urlString]) {
            
            image = [LCAnimatedGIFUtility animatedImageWithAnimatedGIFData:data];
        }
        
        if (image == nil) {
            
            image = [[UIImage alloc] initWithData:data];
        }
    }
    
    return image;
}

@end








