import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import '../models/dog_post.dart';
import '../services/feed_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class LogDogScreen extends StatefulWidget {
  final VoidCallback? onDogLogged;
  
  const LogDogScreen({super.key, this.onDogLogged});

  @override
  State<LogDogScreen> createState() => _LogDogScreenState();
}

class _LogDogScreenState extends State<LogDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dogNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _imageFile;
  int _rating = 3;
  bool _isSubmitting = false;
  UserProfile? _currentUser;
  
  // Common dog breeds for suggestions
  final List<String> _commonBreeds = [
    'Golden Retriever',
    'Labrador Retriever',
    'German Shepherd',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Dachshund',
    'Siberian Husky',
    'Border Collie',
    'Boxer',
    'Cocker Spaniel',
    'Shih Tzu',
    'Boston Terrier',
    'Chihuahua',
    'Mixed Breed',
    'Unknown',
  ];
  
  // Common dog colors
  final List<String> _commonColors = [
    'Black',
    'Brown',
    'White',
    'Golden',
    'Tan',
    'Gray',
    'Black and White',
    'Brown and White',
    'Black and Tan',
    'Tricolor',
    'Brindle',
    'Cream',
    'Red',
    'Blue',
    'Silver',
    'Chocolate',
    'Merle',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _setDefaultLocation();
  }

  @override
  void dispose() {
    _dogNameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await ProfileService.instance.loadProfile();
    setState(() {
      _currentUser = user;
    });
  }

  void _setDefaultLocation() {
    // Set a default location - in real app this would use GPS
    _locationController.text = 'Current Location';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up your profile first')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final post = DogPost(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        userId: _currentUser!.id,
        userName: _currentUser!.displayName,
        userProfilePicture: _currentUser!.profilePictureUrl,
        dogName: _dogNameController.text.trim(),
        breed: _breedController.text.trim(),
        color: _colorController.text.trim(),
        location: _locationController.text.trim(),
        rating: _rating,
        photoUrl: _imageFile?.path,
        createdAt: DateTime.now(),
      );

      await FeedService.instance.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dog logged successfully!')),
        );
        
        // Clear the form
        _dogNameController.clear();
        _breedController.clear();
        _colorController.clear();
        _setDefaultLocation();
        setState(() {
          _imageFile = null;
          _rating = 3;
        });

        // Navigate back to feed to see the new post
        if (widget.onDogLogged != null) {
          widget.onDogLogged!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging dog: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a Dog'),
        backgroundColor: Colors.brown.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo section
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo\n(Optional)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dog name field
              TextFormField(
                controller: _dogNameController,
                decoration: const InputDecoration(
                  labelText: 'Dog Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Dog name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Breed field with autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _commonBreeds.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _breedController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _breedController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(
                      labelText: 'Breed',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Breed is required';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Color field with autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _commonColors.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _colorController.text = selection;
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _colorController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Color is required';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  suffixIcon: Icon(Icons.my_location),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Rating section
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        index < _rating ? Icons.pets : Icons.pets_outlined,
                        color: index < _rating ? Colors.orange : Colors.grey.shade400,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Log This Dog',
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