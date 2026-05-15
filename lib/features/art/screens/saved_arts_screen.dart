import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../../constants/global_variables.dart';

class ArtsScreen extends StatefulWidget {
  const ArtsScreen({super.key});

  @override
  State<ArtsScreen> createState() => _ArtsScreenState();
}

class _ArtsScreenState extends State<ArtsScreen> with TickerProviderStateMixin {
  List<FileSystemEntity> imgList = [];
  bool _isLoading = true;
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late AnimationController _autoRefreshController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  // Auto-refresh timer
  late Timer _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _initAnimations();
    _startAutoRefresh();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _autoRefreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _rotationAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _refreshImages();
      }
    });
  }

  Future<void> _refreshImages() async {
    HapticFeedback.mediumImpact();
    await _refreshController.forward(from: 0);
    await _loadImages();
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshController.reset();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory("/storage/emulated/0/Android/data/com.example.pictureai/files/FaceTrace/");
      
      if (await folder.exists()) {
        final List<FileSystemEntity> files = await folder.list().toList();
        final List<FileSystemEntity> images = files
            .where((file) => file.path.endsWith('.png'))
            .toList()
            ..sort((a, b) {
              final aStat = File(a.path).statSync();
              final bStat = File(b.path).statSync();
              return bStat.modified.compareTo(aStat.modified);
            });
        
        setState(() => imgList = images);
      } else {
        setState(() => imgList = []);
      }
    } catch (e) {
      debugPrint('Error loading images: $e');
      _showSnackBar('Error loading images', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImageDetail(FileSystemEntity image, int index) {
    HapticFeedback.mediumImpact();
    final file = File(image.path);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0F1923),
                        const Color(0xFF0A1628),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF4D9FFF).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.5,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.share_rounded,
                                    label: 'Share',
                                    color: const Color(0xFF00E676),
                                    onTap: () => _shareImage(file),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.save_alt_rounded,
                                    label: 'Gallery',
                                    color: const Color(0xFF4D9FFF),
                                    onTap: () => _saveToGallery(file),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    icon: Icons.delete_rounded,
                                    label: 'Delete',
                                    color: Colors.red,
                                    onTap: () {
                                      Navigator.pop(context);
                                      _deleteImage(image, index);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Created: ${_formatDate(file.statSync().modified)}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareImage(File image) async {
    try {
      await Share.shareXFiles(
        [XFile(image.path)],
        text: 'Generated by FaceTrace AI',
      );
      _showSnackBar('Image shared successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error sharing image', Colors.red);
    }
  }

  Future<void> _saveToGallery(File image) async {
    try {
      final result = await ImageGallerySaver.saveFile(image.path);
      if (result['isSuccess'] == true) {
        _showSnackBar('Image saved to gallery', Colors.green);
      } else {
        _showSnackBar('Failed to save to gallery', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error saving to gallery', Colors.red);
    }
  }

  Future<void> _deleteImage(FileSystemEntity image, int index) async {
    try {
      final file = File(image.path);
      await file.delete();
      setState(() {
        imgList.removeAt(index);
      });
      _showSnackBar('Image deleted successfully', Colors.red);
    } catch (e) {
      _showSnackBar('Error deleting image', Colors.red);
    }
  }

  void _confirmDelete(FileSystemEntity image, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        title: const Text(
          'Delete Image',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this image?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(image, index);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1923),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
          title: const Text(
            'Delete All',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'Are you sure you want to delete all images?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                for (var image in imgList) {
                  await File(image.path).delete();
                }
                setState(() => imgList.clear());
                Navigator.pop(context);
                _showSnackBar('All images deleted', Colors.red);
              },
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _refreshController.dispose();
    _autoRefreshController.dispose();
    _autoRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C12),
      appBar: AppBar(
        title: const Text(
          'My Arts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A1628),
                const Color(0xFF0D1F3C),
              ],
            ),
          ),
        ),
        actions: [
          // Auto-refresh indicator
          AnimatedBuilder(
            animation: _autoRefreshController,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.autorenew_rounded,
                  color: const Color(0xFF4D9FFF).withOpacity(0.5 + _autoRefreshController.value * 0.5),
                  size: 20,
                ),
              );
            },
          ),
          // Manual Refresh Button
          AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 6.28318,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _refreshImages,
                  tooltip: 'Refresh',
                ),
              );
            },
          ),
          // Delete All Button
          if (imgList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _showDeleteAllDialog,
              tooltip: 'Delete all',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshImages,
        color: const Color(0xFF4D9FFF),
        backgroundColor: const Color(0xFF0F1923),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _isLoading
              ? _buildLoadingShimmer()
              : imgList.isEmpty
                  ? _buildEmptyState()
                  : _buildImageGrid(),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7, // Reduced from 0.8 to prevent overflow
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1923),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3050),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 100,
              height: 12,
              color: const Color(0xFF1E3050),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4D9FFF).withOpacity(0.15),
                        const Color(0xFF4D9FFF).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: const Color(0xFF4D9FFF).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No images yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate and download images to see them here',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 80, // Add extra bottom padding
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7, // Reduced from 0.8 to make items shorter
      ),
      itemCount: imgList.length,
      itemBuilder: (context, index) {
        final image = imgList[index];
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: GestureDetector(
                  onTap: () => _showImageDetail(image, index),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0F1923),
                          const Color(0xFF0A1628),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4D9FFF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(File(image.path).statSync().modified),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildGridAction(
                                    icon: Icons.share_rounded,
                                    color: const Color(0xFF00E676),
                                    onTap: () => _shareImage(File(image.path)),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildGridAction(
                                    icon: Icons.save_alt_rounded,
                                    color: const Color(0xFF4D9FFF),
                                    onTap: () => _saveToGallery(File(image.path)),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildGridAction(
                                    icon: Icons.delete_rounded,
                                    color: Colors.red,
                                    onTap: () => _confirmDelete(image, index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}