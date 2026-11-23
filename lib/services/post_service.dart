import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post.dart';

/// Exception dengan pesan yang ramah untuk ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Semua request HTTP ada di sini.
/// Urutan tiap fungsi: (1) buat alamat, (2) kirim request,
/// (3) cek status code, (4) ubah JSON menjadi objek.
class PostService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _timeout = Duration(seconds: 10);

  /// GET /posts
  static Future<List<Post>> fetchPosts() async {
    try {
      final uri = Uri.parse('$_baseUrl/posts'); // 1. buat alamat
      final response = await http.get(uri).timeout(_timeout); // 2. kirim
      _checkStatus(response, const [200]); // 3. cek status code
      final List<dynamic> data = jsonDecode(response.body); // 4. JSON -> objek
      return data
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _toApiException(e);
    }
  }

  /// GET /posts/{id}/comments
  static Future<List<Comment>> fetchComments(int postId) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts/$postId/comments');
      final response = await http.get(uri).timeout(_timeout);
      _checkStatus(response, const [200]);
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _toApiException(e);
    }
  }

  /// POST /posts
  static Future<Post> createPost({
    required String title,
    required String body,
    int userId = 1,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'title': title, 'body': body, 'userId': userId}),
          )
          .timeout(_timeout);
      _checkStatus(response, const [200, 201]);
      return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      throw _toApiException(e);
    }
  }

  static void _checkStatus(http.Response response, List<int> okCodes) {
    if (!okCodes.contains(response.statusCode)) {
      throw ApiException(
          'Server mengembalikan kode ${response.statusCode}. Coba lagi nanti.');
    }
  }

  static ApiException _toApiException(Object e) {
    if (e is ApiException) return e;
    if (e is TimeoutException) {
      return const ApiException('Koneksi terlalu lama (timeout). Coba lagi.');
    }
    if (e is FormatException) {
      return const ApiException('Format data dari server tidak valid.');
    }
    return const ApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.');
  }
}
