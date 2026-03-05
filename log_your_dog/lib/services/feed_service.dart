import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dog_post.dart';

abstract class IFeedRepository {
  Future<List<DogPost>> getPosts({int? limit, String? cursor});
  Future<List<DogPost>> getPostsByUser(String userId, {int? limit});
  Future<DogPost> savePost(DogPost post);
  Future<DogPost> updatePost(DogPost post);
  Future<bool> deletePost(String postId);
  Future<DogPost> toggleLike(String postId, String userId);
  Future<DogPost> addComment(String postId, String userId, String content);
}

class LocalFeedRepository implements IFeedRepository {
  static const String _postsKey = 'feed_posts';

  @override
  Future<List<DogPost>> getPosts({int? limit, String? cursor}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getString(_postsKey);
      
      if (postsJson != null) {
        final List<dynamic> postsList = jsonDecode(postsJson);
        var posts = postsList
            .map((json) => DogPost.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by creation date (reverse chronological)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Apply limit if specified
        if (limit != null && posts.length > limit) {
          posts = posts.take(limit).toList();
        }
        
        return posts;
      }
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
    
    return [];
  }

  @override
  Future<List<DogPost>> getPostsByUser(String userId, {int? limit}) async {
    try {
      final allPosts = await getPosts();
      
      // Filter posts by user ID
      var userPosts = allPosts.where((post) => post.userId == userId).toList();
      
      // Already sorted by creation date from getPosts()
      
      // Apply limit if specified
      if (limit != null && userPosts.length > limit) {
        userPosts = userPosts.take(limit).toList();
      }
      
      return userPosts;
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      return [];
    }
  }

  @override
  Future<DogPost> savePost(DogPost post) async {
    final posts = await getPosts();
    posts.insert(0, post); // Add to beginning for chronological order
    await _savePosts(posts);
    return post;
  }

  @override
  Future<DogPost> updatePost(DogPost post) async {
    final posts = await getPosts();
    final index = posts.indexWhere((p) => p.id == post.id);
    
    if (index != -1) {
      posts[index] = post;
      await _savePosts(posts);
      return post;
    }
    
    throw Exception('Post not found');
  }

  @override
  Future<bool> deletePost(String postId) async {
    final posts = await getPosts();
    final originalLength = posts.length;
    posts.removeWhere((p) => p.id == postId);
    
    if (posts.length < originalLength) {
      await _savePosts(posts);
      return true;
    }
    
    return false;
  }

  @override
  Future<DogPost> toggleLike(String postId, String userId) async {
    final posts = await getPosts();
    final index = posts.indexWhere((p) => p.id == postId);
    
    if (index != -1) {
      final updatedPost = posts[index].toggleLike(userId);
      posts[index] = updatedPost;
      await _savePosts(posts);
      return updatedPost;
    }
    
    throw Exception('Post not found');
  }

  @override
  Future<DogPost> addComment(String postId, String userId, String content) async {
    // For now, just return the post as-is since commenting is not fully implemented
    // This method is prepared for future cloud implementation
    final posts = await getPosts();
    final post = posts.firstWhere((p) => p.id == postId);
    return post;
  }

  Future<void> _savePosts(List<DogPost> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = jsonEncode(posts.map((p) => p.toJson()).toList());
      await prefs.setString(_postsKey, postsJson);
    } catch (e) {
      debugPrint('Error saving posts: $e');
      rethrow;
    }
  }
}

// Cloud implementation placeholder - ready for future Firebase/API integration
class CloudFeedRepository implements IFeedRepository {
  @override
  Future<List<DogPost>> getPosts({int? limit, String? cursor}) async {
    // TODO: Implement cloud fetch
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<List<DogPost>> getPostsByUser(String userId, {int? limit}) async {
    // TODO: Implement cloud fetch by user
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogPost> savePost(DogPost post) async {
    // TODO: Implement cloud save
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogPost> updatePost(DogPost post) async {
    // TODO: Implement cloud update
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<bool> deletePost(String postId) async {
    // TODO: Implement cloud delete
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogPost> toggleLike(String postId, String userId) async {
    // TODO: Implement cloud like toggle
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogPost> addComment(String postId, String userId, String content) async {
    // TODO: Implement cloud comment
    throw UnimplementedError('Cloud implementation not yet available');
  }
}

class FeedService {
  static FeedService? _instance;
  late final IFeedRepository _repository;
  
  FeedService._({required IFeedRepository repository}) : _repository = repository;
  
  static FeedService get instance {
    _instance ??= FeedService._(repository: LocalFeedRepository());
    return _instance!;
  }

  // Method to switch to cloud implementation when ready
  static void initializeWithCloud() {
    _instance = FeedService._(repository: CloudFeedRepository());
  }

  Future<List<DogPost>> getFeedPosts({int? limit}) async {
    return await _repository.getPosts(limit: limit);
  }

  Future<List<DogPost>> getUserPosts(String userId, {int? limit}) async {
    return await _repository.getPostsByUser(userId, limit: limit);
  }

  Future<DogPost> createPost(DogPost post) async {
    return await _repository.savePost(post);
  }

  Future<DogPost> updatePost(DogPost post) async {
    return await _repository.updatePost(post);
  }

  Future<bool> deletePost(String postId) async {
    return await _repository.deletePost(postId);
  }

  Future<DogPost> toggleLike(String postId, String userId) async {
    return await _repository.toggleLike(postId, userId);
  }

  Future<void> generateMockData() async {
    final mockPosts = _createMockPosts();
    
    for (final post in mockPosts) {
      await _repository.savePost(post);
    }
  }

  List<DogPost> _createMockPosts() {
    final now = DateTime.now();
    
    return [
      DogPost(
        id: 'post_1',
        userId: 'user_sarah',
        userName: 'Sarah Johnson',
        userProfilePicture: null,
        dogName: 'Buddy',
        breed: 'Golden Retriever',
        color: 'Golden',
        location: 'Central Park, NYC',
        rating: 5,
        photoUrl: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        likedByUserIds: ['user_current', 'user_mike'],
      ),
      DogPost(
        id: 'post_2',
        userId: 'user_mike',
        userName: 'Mike Chen',
        userProfilePicture: null,
        dogName: 'Luna',
        breed: 'Border Collie',
        color: 'Black and White',
        location: 'Dog Park, SF',
        rating: 4,
        photoUrl: null,
        createdAt: now.subtract(const Duration(hours: 5)),
        likedByUserIds: ['user_sarah'],
      ),
      DogPost(
        id: 'post_3',
        userId: 'user_alex',
        userName: 'Alex Thompson',
        userProfilePicture: null,
        dogName: 'Max',
        breed: 'German Shepherd',
        color: 'Brown and Black',
        location: 'Riverside Park',
        rating: 5,
        photoUrl: null,
        createdAt: now.subtract(const Duration(hours: 8)),
        likedByUserIds: ['user_current', 'user_sarah', 'user_mike'],
      ),
      DogPost(
        id: 'post_4',
        userId: 'user_emma',
        userName: 'Emma Wilson',
        userProfilePicture: null,
        dogName: 'Bella',
        breed: 'Labrador',
        color: 'Chocolate',
        location: 'Beach Walk, CA',
        rating: 4,
        photoUrl: null,
        createdAt: now.subtract(const Duration(hours: 12)),
        likedByUserIds: [],
      ),
      DogPost(
        id: 'post_5',
        userId: 'user_david',
        userName: 'David Kim',
        userProfilePicture: null,
        dogName: 'Rocky',
        breed: 'Bulldog',
        color: 'Brindle',
        location: 'Local Neighborhood',
        rating: 3,
        photoUrl: null,
        createdAt: now.subtract(const Duration(days: 1)),
        likedByUserIds: ['user_current'],
      ),
    ];
  }
}