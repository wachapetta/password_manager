import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

class NetworkHelper {
  NetworkHelper._();

  static Future<List<String>> getData(String url,[String path, Map<String,String> params]) async {

    http.Response response = null;

    developer.log('url: $url');

    if(params !=null) {
      developer.log('via params and path');
      response = await http.get(Uri.https(url, path, params));
    }
    else {
      developer.log('via full url');
      response = await http.get(Uri.parse(url));
    }

    List<String> data = [];

    if (response.statusCode == 200) {
      List decodedData = jsonDecode(response.body);
      for (Map<String, dynamic> mapData in decodedData)
        data.add(mapData['password']);
      return data;
    } else {
      print("DATA FROM API RESPONSE CODE : ${response.statusCode}");
      return [];
    }
  }
}
