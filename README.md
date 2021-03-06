## LCPhotoBrowser 

![badge-pod] ![badge-languages] ![badge-platforms] ![badge-mit]

### Features
> * It supports multiple photos.
> * It supports zoom and gestures.
> * It supports GIF.
> * It supports thirdparty cache component.
> * Delete and insert photos.
> * Long press gesture.
> * It supports custom additional views.
> * Custom UI style support.
> * Only two files. ：）
 
### Preview (GIF)
-
![image](https://github.com/titman/Pictures-of-the-warehouse/blob/master/LCPhotoBrowser1.gif?raw=false)  ![image](https://github.com/titman/Pictures-of-the-warehouse/blob/master/LCPhotoBrowser3.gif?raw=false)
![image](https://github.com/titman/Pictures-of-the-warehouse/blob/master/LCPhotoBrowser2.gif?raw=false)  ![image](https://github.com/titman/Pictures-of-the-warehouse/blob/master/LCPhotoBrowser4.gif?raw=false)
-

### LCPhotoBrowser + SDWebImageCache

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions

    SDImageCache * imageCache = [SDWebImageManager sharedManager].imageCache;
    
    LCPhotoBrowserActionTransfer.share.downloadDidFinished = ^(NSString * urlString, UIImage * image){
        
        [imageCache storeImage:image forKey:[[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:urlString]]];
    };
    
    LCPhotoBrowserActionTransfer.share.readImageFromCache = ^UIImage *(NSString * urlString){
        
        NSString * key = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:urlString]];
        
        UIImage * image = [imageCache imageFromDiskCacheForKey:key];
        
        return image;
    };
}
```

### Update

 - 1.1
    * Fix current index problem.
    * Fix problem caused by cornerRadius of referenceView. 
 - 1.0
    * First commit.


[badge-platforms]: https://img.shields.io/badge/platforms-iOS-lightgrey.svg
[badge-pod]: https://img.shields.io/cocoapods/v/LCPhotoBrowser.svg?label=version
[badge-languages]: https://img.shields.io/badge/languages-ObjC-orange.svg
[badge-mit]: https://img.shields.io/badge/license-MIT-blue.svg
