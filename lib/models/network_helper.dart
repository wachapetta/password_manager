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
      response = await http.get(Uri.https(url, path, params),
          headers:{
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36',
          'accept-encoding': 'gzip, deflate, br',
          'accept-language': 'en-US,en;q=0.9,pt-BR;q=0.8,pt;q=0.7',
          'cache-control': 'max-age=0',
          'dnt': '1',
          'sec-ch-ua': '"Not_A Brand";v="99", "Google Chrome";v="109", "Chromium";v="109"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': "Windows",
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'none',
          'sec-fetch-user': '?1',
          'upgrade-insecure-requests': '1'
          } );
    }
    else {
      developer.log('via full url');
      response = await http.get(Uri.parse(url),
          headers: {
          "Access-Control-Allow-Origin":"*",
          "Access-Control-Allow-Methods": "GET,PUT,PATCH,POST,DELETE",
          "Access-Control-Allow-Headers": "Origin, X-Requested-With, Content-Type, Accept",
          });
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
