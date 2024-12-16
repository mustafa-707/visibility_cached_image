import 'package:flutter/material.dart';
import 'package:visibility_cached_image/visibility_cached_image.dart';

Future<void> main() async {
  await VisibilityCacheImageConfig.init(maxMemoryCacheEntries: 100);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visibility Cached Image Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      bottom: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Visibility Cached Image Example'),
        ),
        body: ListView(
          physics: NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          children: [
            // Asset Image Section
            Text(
              'Asset Image:',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            // Example with an asset image
            VisibilityCachedImage(
              assetPath: 'assets/image.jpg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, progress) {
                return Center(
                  child: Container(
                    color: Colors.grey.shade200,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Network Image Section
            Text(
              'Network Images:',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            // GridView for Network Images
            SizedBox(
              height: height,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 1000, // Set the number of items in the grid
                itemBuilder: (context, index) => VisibilityCachedImage(
                  imageUrl: 'https://picsum.photos/seed/$index/200/300',
                  width: double.infinity,
                  height: 200,
                  cacheHeight: 200,
                  cacheWidth: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, progress) {
                    return Center(
                      child: Container(
                        color: Colors.grey.shade200,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
