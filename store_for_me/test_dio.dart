import 'package:dio/dio.dart';

void main() {
  var dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.9:5000/api'));
  var options = RequestOptions(path: '/delivery-partner/register');
  var uri = dio.options.baseUrl + options.path; // Dio handles it differently
  print(uri);
}
