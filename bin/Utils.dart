import 'dart:convert';

import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart'as http;

Future<void> changePlace(GuildChannel channel, String id, String token) async {
  var uri = Uri.parse('https://discord.com/api/v9/channels/${channel.id}');
  var headers = {'Authorization':'Bot $token','Content-Type':'application/json'};
  var body = jsonEncode( {'parent_id':id});
  var response = await http.patch(uri, headers: headers, body: body);
  print(response.body);
}