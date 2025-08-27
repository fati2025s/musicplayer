import 'dart:async';
import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../screens/playlistdetail.dart';
import '../service/playlist.dart';
import '../service/SocketService.dart';

class PlaylistsHome extends StatefulWidget {
  final List<Playlist> allplaylists;

  const PlaylistsHome({Key? key, required this.allplaylists}) : super(key: key);

  @override
  State<PlaylistsHome> createState() => _PlaylistsHomeState();
}

class _PlaylistsHomeState extends State<PlaylistsHome> {
  late List<Playlist> playlists;
  String message = "";
  final TextEditingController _controllerName = TextEditingController();

  final SocketService _socketService = SocketService();
  late final PlaylistService _playlistService;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    playlists = List<Playlist>.from(widget.allplaylists);
    _playlistService = PlaylistService(_socketService);
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _loading = true);
    try {
      final list = await _playlistService.listPlaylists();
      if (!mounted) return;
      setState(() {
        playlists = list;
        message = "";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = "خطا در بارگذاری پلی‌لیست‌ها: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    _controllerName.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create new playlist"),
        content: TextField(
          controller: _controllerName,
          decoration: const InputDecoration(labelText: "name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("cancel"),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _controllerName.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await _addPlaylist(name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.black,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text("create"),
          ),
        ],
      ),
    );
  }

  Future<void> _addPlaylist(String name) async {
    if (name.isEmpty) {
      if (!mounted) return;
      setState(() => message = "Name is invalid");
      return;
    }

    try {
      final newPlaylist = await _playlistService.addPlaylist(name);
      if (!mounted) return;
      if (newPlaylist != null) {
        setState(() {
          playlists.add(newPlaylist);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Playlist '$name' created successfully")),
        );
      } else {
        setState(() => message = "Failed to create playlist");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create playlist")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => message = "Connection failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
    }
  }

  Future<void> _deletePlaylist(int playlistId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete playlist'),
        content: const Text('آیا از حذف این پلی‌لیست مطمئن هستید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await _playlistService.deletePlaylist(playlistId);
      if (!mounted) return;
      if (success) {
        setState(() {
          playlists.removeWhere((p) => p.id == playlistId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Playlist deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete playlist")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => message = "Connection failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed: $e")),
      );
    }
  }

  Future<void> _renamePlaylistDialog(Playlist playlist) async {
    final renameController = TextEditingController(text: playlist.name);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'New name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            child: const Text('Rename'),
            onPressed: () async {
              final newName = renameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(ctx);
              await _renamePlaylist(playlist, newName);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _renamePlaylist(Playlist playlist, String newName) async {
    try {
      final success = await _playlistService.renamePlaylist(playlist.id, newName);

      if (!mounted) return;

      if (success) {
        setState(() {
          final idx = playlists.indexWhere((p) => p.id == playlist.id);
          if (idx >= 0) playlists[idx].name = newName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist renamed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rename')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }


  Future<void> _sharePlaylistDialog(int playlistId) async {
    final usernameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Playlist'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Target Username'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            child: const Text('Share'),
            onPressed: () async {
              final target = usernameController.text.trim();
              if (target.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final success = await _playlistService.sharePlaylist(playlistId, target);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Playlist shared successfully'
                        : 'Failed to share playlist'),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Network error')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistCard(Playlist playlist) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailsScreen(playlist: playlist),
            ),
          );
          if (!mounted) return;
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    playlist.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${playlist.songs.length
                    } آهنگ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _renamePlaylistDialog(playlist),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                    // Share
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _sharePlaylistDialog(playlist.id),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share, size: 18, color: Colors.white),
                      ),
                    ),
                    // Delete
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async => await _deletePlaylist(playlist.id),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : playlists.isEmpty
          ? Center(
        child: Text(
          message.isEmpty ? 'هیچ پلی‌لیستی وجود ندارد' : message,
          style: const TextStyle(fontSize: 18),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: List.generate(
            playlists.length,
                (index) => _buildPlaylistCard(playlists[index]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
