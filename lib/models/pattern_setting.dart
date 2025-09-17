class PatternSetting {
  final int tapCount;
  final String functionName;
  final String functionType; // audio, video, image, sos

  PatternSetting({
    required this.tapCount,
    required this.functionName,
    required this.functionType,
  });

  Map<String, dynamic> toMap() {
    return {
      'tapCount': tapCount,
      'functionName': functionName,
      'functionType': functionType,
    };
  }

  factory PatternSetting.fromMap(Map<String, dynamic> map) {
    return PatternSetting(
      tapCount: map['tapCount'],
      functionName: map['functionName'],
      functionType: map['functionType'],
    );
  }
}