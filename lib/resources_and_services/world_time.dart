import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class WorldTime {
  String location; // location name for UI
  String time = ''; // the time in that location
  String flag; // url to an asset flag icon
  String url; // location url for api endpoint
  bool isDaytime = false; // true or false if daytime or not

  WorldTime({required this.location, required this.flag, required this.url});

  Future<void> getTime() async {
    try {
      final Uri uri = Uri.https('timeapi.io', '/api/Time/current/zone', {
        'timeZone': url,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        time = 'could not get time';
        return;
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final String? dateTimeRaw =
          (data['dateTime'] ?? data['date_time']) as String?;

      late final DateTime now;
      if (dateTimeRaw != null && dateTimeRaw.isNotEmpty) {
        now = DateTime.parse(dateTimeRaw);
      } else if (data['year'] is int &&
          data['month'] is int &&
          data['day'] is int &&
          data['hour'] is int &&
          data['minute'] is int) {
        now = DateTime(
          data['year'] as int,
          data['month'] as int,
          data['day'] as int,
          data['hour'] as int,
          data['minute'] as int,
          (data['seconds'] ?? 0) as int,
        );
      } else {
        time = 'could not get time';
        return;
      }

      isDaytime = now.hour > 6 && now.hour < 20;
      time = DateFormat.jm().format(now);
    } catch (_) {
      time = 'could not get time';
    }
  }
}
