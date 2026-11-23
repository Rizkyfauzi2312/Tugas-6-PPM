import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import 'add_post_screen.dart';
import 'detail_screen.dart';

String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> _future;
  final List<Post> _localPosts = []; // pengumuman yang baru dibuat

  @override
  void initState() {
    super.initState();
    _future = PostService.fetchPosts(); // dipanggil di initState, bukan build
  }

  void _reload() {
    setState(() => _future = PostService.fetchPosts());
  }

  Future<void> _onRefresh() async {
    final f = PostService.fetchPosts();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<Post>(
      context,
      MaterialPageRoute(builder: (_) => const AddPostScreen()),
    );
    if (created != null && mounted) {
      setState(() => _localPosts.insert(0, created));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Pengumuman berhasil dibuat (id: ${created.id}).'),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NusaInfo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Buat'),
      ),
      body: FutureBuilder<List<Post>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final posts = [..._localPosts, ...?snapshot.data];
          if (posts.isEmpty) {
            return const Center(child: Text('Belum ada pengumuman.'));
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: posts.length,
              itemBuilder: (context, i) {
                final p = posts[i];
                final isNew = i < _localPosts.length;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${p.id}')),
                    title: Text(capitalize(p.title),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(p.body,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: isNew ? const Chip(label: Text('Baru')) : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(post: p)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Gagal memuat data', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
