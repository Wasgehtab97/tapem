import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined, canceled, blocked }

class FriendRequest {
  FriendRequest({
    required this.requestId,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  final String requestId;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendRequest.fromMap(String id, Map<String, dynamic> data) {
    return FriendRequest(
      requestId: id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      message: data['message'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
