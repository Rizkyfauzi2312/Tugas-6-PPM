import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import 'home_screen.dart' show capitalize;

class DetailScreen extends StatefulWidget {
  final Post post;
  const DetailScreen({super.key, required this.post});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<List<Comment>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = PostService.fetchComments(widget.post.id);
  }

  void _reload() {
    setState(() => _comments = PostService.fetchComments(widget.post.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.post;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(capitalize(p.title),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Pengumuman #${p.id} • Pengguna ${p.userId}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(p.body, style: theme.textTheme.bodyLarge),
                const Divider(height: 32),
                Text('Komentar', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                FutureBuilder<List<Comment>>(
                  future: _comments,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          Text(snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: theme.colorScheme.error)),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      );
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const Text('Belum ada komentar.');
                    }
                    return Column(
                      children: list
                          .map((c) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.person)),
                                  title: Text(capitalize(c.name),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text('${c.email}\n${c.body}'),
                                  isThreeLine: true,
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
