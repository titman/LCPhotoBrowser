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

#import <UIKit/UIKit.h>


#undef  block
#define block(returnType, name, param) protocol must##_ndef##_block##_##name @end typedef returnType (^name) param



#pragma mark - LCPhotoItem
#pragma mark -

/**
 The LCPhotoItem model.
 
 * Use < LCPhotoItem > to configure < LCPhotoView >.
 */
@interface LCPhotoItem : NSObject

/**
 The image will be visible when the request at the beginning.
 */
@property(nullable, nonatomic, strong) UIImage * placeholder;

/**
 It must be a standard format, such as http://
 */
@property(nullable, nonatomic, strong) NSString * urlString;

/**
 PhotoView will regard referenceView as a starting point,
 and will show with animations.
 */
@property(nullable, nonatomic, weak) __kindof UIView * referenceView;

@end

#pragma mark - LCPhotoView
#pragma mark -

/**
 The LCPhotoView class implements a web image displayer.
 
 * It must use < LCPhotoItem > to initialize.
 */
@interface LCPhotoView : UIScrollView

/**
 Use item to configure view. Default is nil.
 */
@property (nullable, nonatomic, strong) LCPhotoItem * item;

/**
 Designated initializer.
 */
-(nonnull instancetype) init NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - LCPhotoBrowserActionTransfer
#pragma mark -

@block(void, LCPhotoBrowserActionDownloadFinished, ( NSString * _Nullable urlString, UIImage * _Nullable image));
@block(UIImage * _Nullable, LCPhotoBrowserActionReadImageFromCache, (NSString * _Nullable urlString));

@interface LCPhotoBrowserActionTransfer : NSObject

/** 
 Use this method to cache image with a third party cache component.
 */
@property(copy, nonatomic) LCPhotoBrowserActionDownloadFinished _Nullable downloadDidFinished;

/**
 Read cache image from disk or memory.
 */
@property(copy, nonatomic) LCPhotoBrowserActionReadImageFromCache _Nullable readImageFromCache;


+(nonnull instancetype) share;


@end

#pragma mark - LCPhotoBrowser
#pragma mark -

@block(void, LCPhotoBrowserDidSelectAction,     (LCPhotoView * _Nullable photo, NSInteger index));
@block(void, LCPhotoBrowserLongPressAction,     (LCPhotoView * _Nullable photo, NSInteger index));
@block(void, LCPhotoBrowserBeginDownloadAction, (LCPhotoView * _Nullable photo, NSInteger index));
@block(void, LCPhotoBrowserEndDownLoadAction,   (LCPhotoView * _Nullable photo, NSInteger index));

/**
 The LCPhotoBrowser class implements a web image browser.
 
 * It supports multiple photos.
 * It supports zoom.
 * It supports GIF.
 * It supports thirdparty cache component.
 * Delete and insert photos.
 */
@interface LCPhotoBrowser : UIView

typedef NS_ENUM(NSInteger, LCPhotoBrowserBackgroundStyle){
  
    LCPhotoBrowserBackgroundStyleBlack,
    LCPhotoBrowserBackgroundStyleBlur,
};

typedef NS_ENUM(NSInteger, LCPhotoBrowserLoadingStyle){
    
    LCPhotoBrowserLoadingStyleNone,
    LCPhotoBrowserLoadingStyleProgress,
    LCPhotoBrowserLoadingStyleActivityIndicator,
};

///=============================================================================
/// @name Configuring the browser style
///=============================================================================
@property (nonatomic, assign) CGFloat imageViewMargin;

/**
 The LCPhotoBrowser color of background. Default is [[UIColor blackColor] colorWithAlphaComponent:0.8].
 */
@property (nullable, nonatomic, strong) UIColor * backgroundColor;

/**
 It will ignore backgroundColor and blur the current view when set to LCPhotoBrowserBackgroundStyleBlur. Default is LCPhotoBrowserBackgroundStyleBlack.
 */
@property (nonatomic, assign) LCPhotoBrowserBackgroundStyle backgroundStyle;

/**
 Default is UIBlurEffectStyleDark.
 */
@property (nullable, nonatomic, copy) UIBlurEffect * backgroundBlurEffect;

/**
 All of the animation settings. Default is 0.25.
 */
@property (nonatomic, assign) NSTimeInterval animationDuration;

/**
 All of the animation settings. Default is UIViewAnimationOptionCurveEaseInOut.
 */
@property (nonatomic, assign) UIViewAnimationOptions animationOptions;

/**
 Default is LCPhotoBrowserLoadingStyleProgress.
 */
@property (nonatomic, assign) LCPhotoBrowserLoadingStyle loadingStyle;


///=============================================================================
/// @name Main attribute
///=============================================================================
@property (nonatomic, assign) NSInteger currentIndex;

@property (nullable, nonatomic, strong) NSArray<LCPhotoItem *> * items;

/**
 Designated initializer.
 */
-(nonnull instancetype) init NS_DESIGNATED_INITIALIZER;

/**
 Browser will be added on the keywindow of this Application with animations when you call this.
 */
-(void) show;

/**
 Browser will be removed on the keywindow of this Application with animations when you call this.
 */
-(void) hide;

/**
 Delete photo and layout subviews.
 */
-(void) deletePhotoAtIndex:(NSInteger)index;

/**
 Insert photo and layout subviews.
 */
-(void) insertPhotoItem:(nonnull LCPhotoItem *)item atIndex:(NSInteger)index;

///=============================================================================
/// @name Callback
///=============================================================================

/**
 Call this block when switch page.
 */
@property (nullable, nonatomic, copy) LCPhotoBrowserDidSelectAction didSelectAction;

/**
 Call this block when long pressed on photo.
 */
@property (nullable, nonatomic, copy) LCPhotoBrowserLongPressAction longPressAction;

/**
 Call this block when begin request photo data.
 */
@property (nullable, nonatomic, copy) LCPhotoBrowserBeginDownloadAction beginDownloadAction;

/**
 Call this block when finish request, whatever successful or not.
 */
@property (nullable, nonatomic, copy) LCPhotoBrowserEndDownLoadAction endDownloadAction;


@end

#pragma mark - LCPhotoBrowserDownloader
#pragma mark -

/**
 The LCPhotoBrowserDownloader class implements an image downloader.
 */
@interface LCPhotoBrowserDownloader : NSObject

+ (nullable NSURLSessionDataTask *)downloadImageForURL:(nonnull NSURL *)imageURL
                                            completion:(void(^ _Nullable)( UIImage * _Nullable image))completion;

@end

#pragma mark - LCAnimatedGIFUtility
#pragma mark -

@interface LCAnimatedGIFUtility : NSObject

+ (BOOL)imageURLIsAGIF:(nullable NSString *)imageURL;

/**
 UIImage *animation = [UIImage animatedImageWithAnimatedGIFData:theData];
 
 * I interpret `theData` as a GIF.  I create an animated `UIImage` using the source images in the GIF.
 * The GIF stores a separate duration for each frame, in units of centiseconds (hundredths of a second).  However, a `UIImage` only has a single, total `duration` property, which is a floating-point number.
 * To handle this mismatch, I add each source image (from the GIF) to `animation` a varying number of times to match the ratios between the frame durations in the GIF.
 * For example, suppose the GIF contains three frames.  Frame 0 has duration 3.  Frame 1 has duration 9.  Frame 2 has duration 15.  I divide each duration by the greatest common denominator of all the durations, which is 3, and add each frame the resulting number of times.  Thus `animation` will contain frame 0 3/3 = 1 time, then frame 1 9/3 = 3 times, then frame 2 15/3 = 5 times.  I set `animation.duration` to (3+9+15)/100 = 0.27 seconds.
 */
+ (nullable UIImage *)animatedImageWithAnimatedGIFData:(nullable NSData *)theData;

/**
 UIImage *image = [UIImage animatedImageWithAnimatedGIFURL:theURL];
 
 * I interpret the contents of `theURL` as a GIF.  I create an animated `UIImage` using the source images in the GIF.
 * I operate exactly like `+[UIImage animatedImageWithAnimatedGIFData:]`, except that I read the data from `theURL`.  If `theURL` is not a `file:` URL, you probably want to call me on a background thread or GCD queue to avoid blocking the main thread.
 */
+ (nullable UIImage *)animatedImageWithAnimatedGIFURL:(nullable NSURL *)theURL;

@end


