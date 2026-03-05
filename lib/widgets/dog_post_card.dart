import 'package:flutter/material.dart';
import 'dart:io';
import '../models/dog_post.dart';

class DogPostCard extends StatelessWidget {
  final DogPost post;
  final String currentUserId;
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const DogPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedByUser(currentUserId);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.brown.shade200,
                  backgroundImage: post.userProfilePicture != null
                      ? (post.userProfilePicture!.startsWith('/')
                          ? FileImage(File(post.userProfilePicture!))
                          : NetworkImage(post.userProfilePicture!) as ImageProvider)
                      : null,
                  child: post.userProfilePicture == null
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.brown.shade600,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Dog photo (if available)
          if (post.photoUrl != null)
            SizedBox(
              width: double.infinity,
              height: 250,
              child: _buildDogImage(post.photoUrl!),
            ),
          
          // Dog details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dog name and rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.dogName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < post.rating ? Icons.pets : Icons.pets_outlined,
                          color: index < post.rating ? Colors.orange : Colors.grey.shade400,
                          size: 20,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Breed and color
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${post.breed} • ${post.color}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        post.location,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Like and comment buttons
                Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: onLike,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likedByUserIds.length}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    
                    // Comment button
                    GestureDetector(
                      onTap: onComment,
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogImage(String photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: photoUrl.startsWith('/')
          ? Image.file(
              File(photoUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorPlaceholder();
              },
            )
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageErrorPlaceholder();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}