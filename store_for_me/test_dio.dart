import 'package:dio/dio.dart';
import 'lib/core/constants/app_constants.dart';

void main() {
  var dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  var options = RequestOptions(path: '/delivery-partner/register');
  var uri = dio.options.baseUrl + options.path; // Dio handles it differently
  print(uri);
}
