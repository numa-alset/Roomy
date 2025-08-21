import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/chat/presentation/providers/room_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/chat/domain/entities/room.dart';

class JoinScreen extends ConsumerWidget {
  final String selfCallerId;

  const JoinScreen({super.key, required this.selfCallerId});

  void _joinRoom(BuildContext context, String roomId) {
    if (roomId.isEmpty) return;
    context.go("/chat", extra: roomId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomControllerProvider);
    final controller = ref.read(roomControllerProvider.notifier);
    final roomIdController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Join a Room"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Welcome / Join Card ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade300, Colors.green.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Welcome!",
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: selfCallerId),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: "Your ID",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: roomIdController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Enter Room ID",
                        prefixIcon: const Icon(Icons.meeting_room),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _joinRoom(context, roomIdController.text.trim()),
                      icon: const Icon(Icons.login),
                      label: const Text("Join Room"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Popular Rooms Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    "Popular Rooms",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => controller.loadRooms(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Horizontal scroll cards
            SizedBox(
              height: 140,
              child: roomState.loading
                  ? const Center(child: CircularProgressIndicator())
                  : roomState.error != null
                  ? Center(child: Text("Error: ${roomState.error}"))
                  : roomState.rooms.isEmpty
                  ? const Center(child: Text("No rooms available"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: roomState.rooms.length,
                itemBuilder: (context, index) {
                  final Room room = roomState.rooms[index];
                  return GestureDetector(
                    onTap: () => _joinRoom(context, room.id),
                    child: Container(
                      width: 180,
                      margin:
                      const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade200,
                            Colors.green.shade50
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade100
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.group,
                              size: 32,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              room.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: ${room.id}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
