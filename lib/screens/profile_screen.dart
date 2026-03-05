import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../models/dog_post.dart';
import '../models/dog_profile.dart';
import '../services/profile_service.dart';
import '../services/feed_service.dart';
import '../services/dog_service.dart';
import '../widgets/activity_item.dart';
import '../screens/add_dog_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  UserProfile _userProfile = UserProfile.defaultProfile;
  List<DogPost> _recentActivity = [];
  List<DogProfile> _ownedDogs = [];
  bool _isLoading = true;
  bool _isActivityLoading = false;
  bool _isDogsLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh activity when screen becomes visible
    if (!_isLoading && !_isActivityLoading) {
      _loadRecentActivity();
    }
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.instance.loadProfile();
    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });
    
    // Load recent activity and owned dogs after profile is loaded
    await _loadRecentActivity();
    await _loadOwnedDogs();
  }

  Future<void> _loadRecentActivity() async {
    setState(() {
      _isActivityLoading = true;
    });

    try {
      final userPosts = await FeedService.instance.getUserPosts(_userProfile.id, limit: 5);
      setState(() {
        _recentActivity = userPosts;
        _isActivityLoading = false;
      });
    } catch (e) {
      setState(() {
        _isActivityLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activity: $e')),
        );
      }
    }
  }

  Future<void> _loadOwnedDogs() async {
    setState(() {
      _isDogsLoading = true;
    });

    try {
      final dogs = await DogService.instance.getMyDogs(_userProfile.id);
      setState(() {
        _ownedDogs = dogs;
        _isDogsLoading = false;
      });
    } catch (e) {
      setState(() {
        _isDogsLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dogs: $e')),
        );
      }
    }
  }

  void _addDog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddDogScreen(
          ownerId: _userProfile.id,
          onDogAdded: (dog) {
            setState(() {
              _ownedDogs.insert(0, dog);
            });
          },
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          userProfile: _userProfile,
          onSave: (updatedProfile) async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final success = await ProfileService.instance.saveProfile(updatedProfile);
            if (mounted) {
              setState(() {
                _userProfile = updatedProfile;
              });
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Profile saved successfully!' : 'Failed to save profile'),
                ),
              );
              // Refresh activity in case user ID changed (though unlikely)
              await _loadRecentActivity();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMyDogsSection() {
    if (_isDogsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ownedDogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.pets,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No dogs added yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first dog using the button above!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _ownedDogs.map((dog) => _buildDogCard(dog)).toList(),
    );
  }

  Widget _buildDogCard(DogProfile dog) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Dog photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildDogPhoto(dog.photoUrl),
          ),
          const SizedBox(width: 16),
          
          // Dog details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dog.breed} • ${dog.color}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (dog.birthDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    dog.ageString,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Logged ${dog.timesLogged} times',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogPhoto(String? photoUrl) {
    if (photoUrl == null) {
      return Icon(
        Icons.pets,
        size: 40,
        color: Colors.grey.shade500,
      );
    }

    if (photoUrl.startsWith('/')) {
      // Local file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(photoUrl),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.pets,
              size: 40,
              color: Colors.grey.shade500,
            );
          },
        ),
      );
    } else {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          photoUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.pets,
              size: 40,
              color: Colors.grey.shade500,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildActivitySection() {
    if (_isActivityLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_recentActivity.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No dogs logged yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your logged dogs will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last ${_recentActivity.length} dogs logged',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(
                _recentActivity.length,
                (index) => ActivityItem(post: _recentActivity[index]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(String? profilePictureUrl) {
    if (profilePictureUrl == null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.brown.shade600,
        ),
      );
    }

    if (profilePictureUrl.startsWith('/')) {
      // Local file
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: ClipOval(
          child: Image.file(
            File(profilePictureUrl),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.brown.shade600,
              );
            },
          ),
        ),
      );
    } else {
      // Network image
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: ClipOval(
          child: Image.network(
            profilePictureUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.brown.shade600,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.brown.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Center(
              child: Column(
                children: [
                  _buildProfileAvatar(_userProfile.profilePictureUrl),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userProfile.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userProfile.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_userProfile.bio != null) ...[
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _userProfile.bio!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Dogs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addDog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Dog'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMyDogsSection(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_recentActivity.isNotEmpty)
                  TextButton(
                    onPressed: _loadRecentActivity,
                    child: const Text('Refresh'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivitySection(),
                ],
              ),
            ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onSave;

  const ProfileEditScreen({
    super.key,
    required this.userProfile,
    required this.onSave,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.userProfile.displayName);
    _emailController = TextEditingController(text: widget.userProfile.email);
    _locationController = TextEditingController(text: widget.userProfile.location ?? '');
    _bioController = TextEditingController(text: widget.userProfile.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Widget _buildEditProfileAvatar() {
    if (_imageFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: ClipOval(
          child: Image.file(
            _imageFile!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.brown.shade600,
              );
            },
          ),
        ),
      );
    }

    final profilePictureUrl = widget.userProfile.profilePictureUrl;
    if (profilePictureUrl == null) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.brown.shade600,
        ),
      );
    }

    if (profilePictureUrl.startsWith('/')) {
      // Local file
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: ClipOval(
          child: Image.file(
            File(profilePictureUrl),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.brown.shade600,
              );
            },
          ),
        ),
      );
    } else {
      // Network image
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.brown.shade200,
        child: ClipOval(
          child: Image.network(
            profilePictureUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.brown.shade600,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      String? profilePictureUrl = widget.userProfile.profilePictureUrl;
      
      if (_imageFile != null) {
        profilePictureUrl = _imageFile!.path;
      }
      
      final updatedProfile = widget.userProfile.copyWith(
        displayName: _displayNameController.text.trim(),
        email: _emailController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        profilePictureUrl: profilePictureUrl,
        updatedAt: DateTime.now(),
      );
      
      widget.onSave(updatedProfile);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.brown.shade50,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    _buildEditProfileAvatar(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.brown,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}