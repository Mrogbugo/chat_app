import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'message_bubble.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatSnapshot.hasError) {
          return Center(child: Text('Error: ${chatSnapshot.error}'));
        }

        final chatDocs = chatSnapshot.data?.docs ?? [];

        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return ListView.builder(
          reverse: true,
          itemCount: chatDocs.length,
          itemBuilder: (ctx, index) {
            final data = chatDocs[index].data() as Map<String, dynamic>;

            final text = data['text'] ?? '';
            final userId = data['userId'] ?? '';
            final username = data['username'] ?? 'Anonymous';

            return MessageBubble(
              message: text,
              username: username,
              isMe: userId == currentUserId,
            );
          },
        );
      },
    );
  }
}
