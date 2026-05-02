import 'package:dio/dio.dart';
import '../../../../services/api_service.dart';
import '../../../../data/models/social_models.dart';

/// Repository layer for social features (alternative architecture).
/// This wraps ApiService for use in feature-based modules.
class SocialRepository {
  final ApiService _api;

  SocialRepository([ApiService? api]) : _api = api ?? ApiService();

  Future<List<PostModel>> getFeed({String? cursor, int limit = 10}) async {
    try {
      final response = await _api.getFeedCursor(cursor: cursor, limit: limit);

      if (response.data['success'] == true) {
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
      final response = await _api.explorePosts(page: page, limit: limit);

      if (response.data['success'] == true) {
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
      final response = await _api.toggleLike(postId);
      return response.data['success'] == true;
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
      FormData formData = FormData.fromMap({'caption': caption, 'type': type});

      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (var path in imagePaths) {
          formData.files.add(
            MapEntry('images', await MultipartFile.fromFile(path)),
          );
        }
      }

      if (videoPath != null) {
        formData.files.add(
          MapEntry('video', await MultipartFile.fromFile(videoPath)),
        );
      }

      final response = await _api.createPost(formData);
      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }
}
