import 'dart:convert';

import 'package:xml/xml.dart' as xml;

import '../models/models.dart';
import '../youtube_explode_base.dart';
import 'helpers_extension.dart';

/// Caption extension for [YoutubeExplode]
extension CaptionExtension on YoutubeExplode {
  /// Gets all available closed caption track infos for given video.
  Future<List<ClosedCaptionTrackInfo>> getVideoClosedCaptionTrackInfos(
      String videoId) async {
    if (!YoutubeExplode.validateVideoId(videoId)) {
      throw ArgumentError.value(videoId, 'videoId', 'Invalid video id');
    }

    var videoInfoDic = await getVideoInfoDictionary(videoId);

    var playerResponseJson = json.decode(videoInfoDic['player_response']);

    var playAbility = playerResponseJson['playabilityStatus'];

    if (playAbility['status'].toLowerCase() == 'error') {
      throw Exception('Video [$videoId] is unavailable');
    }

    var trackInfos = <ClosedCaptionTrackInfo>[];
    for (var trackJson in playerResponseJson['captions']
        ['playerCaptionsTracklistRenderer']['captionTracks']) {
      var url = Uri.parse(trackJson['baseUrl']);

      var query = Map<String, String>.from(url.queryParameters);
      query['format'] = '3';

      url = url.replace(queryParameters: query);

      var languageCode = trackJson['languageCode'];
      var languageName = trackJson['name']['simpleText'];
      var language = Language(languageCode, languageName);

      var isAutoGenerated = trackJson['vssId'].toLowerCase().startsWith('a.');

      trackInfos.add(ClosedCaptionTrackInfo(url, language, isAutoGenerated));
    }
    return trackInfos;
  }

  Future<xml.XmlDocument> _getClosedCaptionTrackXml(Uri url) async {
    var raw = (await client.get(url)).body;

    return xml.parse(raw);
  }

  /// Gets the closed caption track associated with given metadata.
  Future<ClosedCaptionTrack> getClosedCaptionTrack(
      ClosedCaptionTrackInfo info) async {
    var trackXml = await _getClosedCaptionTrackXml(info.url);

    var captions = <ClosedCaption>[];
    for (var captionXml in trackXml.findAllElements('p')) {
      var text = captionXml.text;
      if (text.isNullOrWhiteSpace) {
        continue;
      }

      var offset =
          Duration(milliseconds: int.parse(captionXml.getAttribute('t')));
      var duration = Duration(
          milliseconds: int.parse(captionXml.getAttribute('d') ?? '-1'));

      captions.add(ClosedCaption(text, offset, duration));
    }

    return ClosedCaptionTrack(info, captions);
  }
}
