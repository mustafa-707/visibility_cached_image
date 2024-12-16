# VisibilityCachedImage  

[![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md) [![Pub Package](https://img.shields.io/pub/v/visibility_cached_image.svg)](https://pub.dev/packages/visibility_cached_image)

`visibility_cached_image` is a powerful and efficient Flutter package that handles both network and asset image loading with advanced memory management techniques. This package optimizes the loading process, reduces memory usage, and ensures smooth user experience by using techniques like lazy loading, a queue system for prioritizing image requests, and caching with Hive.

With this package, you can load images from assets or the network, display them in a Widget, and benefit from smarter memory and performance management. Perfect for use in apps with long lists or dynamic image loading that needs optimization.

## Features  

- Network and Asset Image Loading: Handles both network and asset images seamlessly.
- Efficient Memory Management: Uses strategies like Lazy Image Rendering (`LRU` ~ Least Recently Used) and smart caching to reduce memory usage and improve app performance.
- Image Queue System: Loads images in a prioritized order to prevent unnecessary loading delays, optimizing the user experience.
- Hive Integration: Caches images locally with Hive to reduce redundant network requests and increase app responsiveness.
- Customizable Loading and Error Handling: Fully customizable loading and error states with loadingBuilder and errorBuilder options.
- Visibility Based Image Loading: Ensures that images are loaded only when they become visible on the screen, reducing unnecessary network requests and memory consumption.

## Getting started  

To use this package, add **`visibility_cached_image`** to your `pubspec.yaml`:  

```yaml  
dependencies:  
  visibility_cached_image: ^x.x.x  
```  

Run the following command:  

```bash  
flutter pub get  
```  

## Usage  

Import the Package

```dart
import 'package:visibility_cached_image/visibility_cached_image.dart';

// and initialize the package , you can do it in main.dart , this will initialize local storage 

 await VisibilityCacheImageConfig.init();

```

Here’s a basic example of how to use the `VisibilityCachedImage` widget in your Flutter app:  

```dart  
    VisibilityCachedImage(
      imageUrl: 'https://example.com/image.jpg',
      loadingBuilder: (context, progress) => Center(
        child: CircularProgressIndicator(value: progress),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text('Failed to load image'),
      ),
      width: 300,
      height: 300,
      fit: BoxFit.cover,
    ), 
```  

Loading Images from Assets
You can also use this package to load images from your app's assets.

```dart  
    VisibilityCachedImage(
     assetPath: 'assets/images/local_image.png',
     loadingBuilder: (context, progress) => Center(
       child: CircularProgressIndicator(value: progress),
     ),
     errorBuilder: (context, error, stackTrace) => Center(
       child: Text('Failed to load image'),
     ),
     width: 300,
     height: 300,
     fit: BoxFit.cover,
    ), 
```  

## Additional information  

### Performance Considerations  

- **`Memory Management`**: The package uses lazy loading and image cache size management to optimize memory usage. It ensures that only the required images are kept in memory at any given time.
- **`Network Requests`**: By using Dio with request queues, it ensures that network requests are handled efficiently and in a prioritized manner. If images are already cached, no network request will be made, reducing load times and unnecessary network traffic.  
- **`Local Caching`**: Using Hive for persistent local image caching means that once an image is loaded, it won’t need to be re-downloaded the next time the app starts.

## Support

If you find this plugin helpful, consider supporting me:

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-1.svg)](https://buymeacoffee.com/is10vmust)
