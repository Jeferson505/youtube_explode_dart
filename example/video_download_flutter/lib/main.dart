import 'dart:io';

import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter VideoDownload Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final textController = TextEditingController();

  Future<void> _displayInfoAboutVideo(Video video) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Title: ${video.title}, Duration: ${video.duration}'),
        );
      },
    );
  }

  Future<void> _showFileWasDownloaded(String filePath) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Download completed and saved to: $filePath'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Insert the video id or url',
            ),
            TextField(controller: textController),
            ElevatedButton(
              child: const Text('Download'),
              onPressed: () async {
                // Here you should validate the given input or else an error
                // will be thrown.
                var yt = YoutubeExplode();
                var id = VideoId(textController.text.trim());
                var video = await yt.videos.get(id);

                // Display info about this video.
                await _displayInfoAboutVideo(video);

                // Request permission to write in an external directory.
                // (In this case downloads)
                await Permission.storage.request();

                // Get the streams manifest and the audio track.
                var manifest = await yt.videos.streamsClient.getManifest(id);
                var audio = manifest.audioOnly.last;

                // Build the directory.
                var dir = await DownloadsPathProvider.downloadsDirectory;
                var dirPath = dir?.uri.toFilePath() ?? '';

                var filePath = path.join(
                  dirPath,
                  '${video.id}.${audio.container.name}',
                );

                // Open the file to write.
                var file = File(filePath);
                var fileStream = file.openWrite();

                // Pipe all the content of the stream into our file.
                await yt.videos.streamsClient.get(audio).pipe(fileStream);
                /*
                  If you want to show a % of download, you should listen
                  to the stream instead of using `pipe` and compare
                  the current downloaded streams to the totalBytes,
                  see an example ii example/video_download.dart
                   */

                // Close the file.
                await fileStream.flush();
                await fileStream.close();

                // Show that the file was downloaded.
                await _showFileWasDownloaded(filePath);
              },
            ),
          ],
        ),
      ),
    );
  }
}
