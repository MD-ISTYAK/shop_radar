import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import 'post_model.dart';

class SocialRepository {
  final ApiClient _apiClient;

  SocialRepository(this._apiClient);

  Future<List<PostModel>> getFeed({String? cursor, int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/social/feed',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );

      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch feed: $e');
    }
  }

  Future<List<PostModel>> getExplore({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/social/explore',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => PostModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch explore: $e');
    }
  }

  Future<bool> toggleLike(String postId) async {
    try {
      final response = await _apiClient.dio.post('/social/posts/$postId/like');
      return response.data['success'];
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  Future<bool> createPost({
    required String caption,
    required String type,
    List<String>? imagePaths,
    String? videoPath,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'caption': caption,
        'type': type,
      });

      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var path in imagePaths) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(path),
          ));
        }
      }

      if (videoPath != null) {
        formData.files.add(MapEntry(
          'video',
          await MultipartFile.fromFile(videoPath),
        ));
      }

      final response = await _apiClient.dio.post(
        '/social/posts',
        data: formData,
      );

      return response.data['success'];
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }
}
