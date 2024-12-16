# AutoScrollRow  

[![StandWithPalestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/badges/StandWithPalestine.svg)](https://github.com/TheBSD/StandWithPalestine/blob/main/docs/README.md) [![Pub Package](https://img.shields.io/pub/v/auto_scroll_row.svg)](https://pub.dev/packages/auto_scroll_row)

AutoScrollRow is a Flutter widget that allows automatic scrolling of a row of widgets `horizontally` with customizable options. It is useful for creating marquees or content sliders with smooth animation control.  

## Features  

- Automatically scrolls a row of widgets horizontally.  
- Customizable scrolling speed (`scrollDuration`).  
- Option to reverse scroll direction (`reverse`).  
- User interaction control (`enableUserScroll`): allow users to stop scrolling by dragging.  

## Getting started  

To use this package, add **`auto_scroll_row`** to your `pubspec.yaml`:  

```yaml  
dependencies:  
  auto_scroll_row: ^x.x.x  
```  

Run the following command:  

```bash  
flutter pub get  
```  

## Usage  

Here’s a basic example of how to use the `AutoScrollRow` widget in your Flutter app:  

```dart  
    AutoScrollRow(  
     children: List.generate(  
       10,  
       (index) => Container(  
         width: 100,  
         height: 100,  
         margin: const EdgeInsets.all(8),  
         color: Colors.blueAccent,  
         child: Center(child: Text('Item $index')),  
       ),  
     ),  
     scrollDuration: const Duration(minutes: 15),  // Customize scroll speed  
     reverse: false,  // Set to true for right-to-left scroll  
     enableUserScroll: true,  // Enable user to stop scroll by dragging  
    ),  
```  

## Additional information  

### Parameters  

- **`children`**: List of widgets displayed in the horizontal row.  
- **`scrollDuration`**: Controls the speed of scrolling. Default is 30 minutes for a full cycle. Customize to make scrolling faster or slower.  
- **`reverse`**: Set to `true` for right-to-left scrolling.  
- **`enableUserScroll`**: Enable or disable user control over scrolling. Set to `true` to allow users to stop the scroll by dragging.  

## Support

If you find this plugin helpful, consider supporting me:

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-1.svg)](https://buymeacoffee.com/is10vmust)
