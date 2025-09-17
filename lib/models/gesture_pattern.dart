class GesturePattern {
  final String id;
  final String name;
  final GestureType type;
  final int tapCount;
  final Duration duration;
  final DateTime createdAt;

  GesturePattern({
    required this.id,
    required this.name,
    required this.type,
    required this.tapCount,
    required this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'tapCount': tapCount,
      'duration': duration.inMilliseconds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GesturePattern.fromJson(Map<String, dynamic> json) {
    return GesturePattern(
      id: json['id'],
      name: json['name'],
      type: _parseGestureType(json['type']),
      tapCount: json['tapCount'],
      duration: Duration(milliseconds: json['duration']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  static GestureType _parseGestureType(String typeString) {
    switch (typeString) {
      case 'GestureType.DoubleTap':
        return GestureType.DoubleTap;
      case 'GestureType.TripleTap':
        return GestureType.TripleTap;
      case 'GestureType.LongSlap':
        return GestureType.LongSlap;
      default:
        return GestureType.DoubleTap;
    }
  }
}

enum GestureType {
  DoubleTap,
  TripleTap,
  LongSlap,
}

class GestureAction {
  final String id;
  final String gestureId;
  final ActionType actionType;
  final Map<String, dynamic>? parameters;

  GestureAction({
    required this.id,
    required this.gestureId,
    required this.actionType,
    this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gestureId': gestureId,
      'actionType': actionType.toString(),
      'parameters': parameters,
    };
  }

  factory GestureAction.fromJson(Map<String, dynamic> json) {
    return GestureAction(
      id: json['id'],
      gestureId: json['gestureId'],
      actionType: _parseActionType(json['actionType']),
      parameters: json['parameters'],
    );
  }

  static ActionType _parseActionType(String typeString) {
    switch (typeString) {
      case 'ActionType.CapturePhoto':
        return ActionType.CapturePhoto;
      case 'ActionType.RecordVideo':
        return ActionType.RecordVideo;
      case 'ActionType.RecordAudio':
        return ActionType.RecordAudio;
      default:
        return ActionType.CapturePhoto;
    }
  }
}

enum ActionType {
  CapturePhoto,
  RecordVideo,
  RecordAudio,
}