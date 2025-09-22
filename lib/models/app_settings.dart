class AppSettings {
  bool deleteAfterSharing;
  bool autoDeleteOldRecordings;
  int autoDeleteDays;
  String themeMode;
  String audioSampleRate;
  String audioBitRate;
  String videoQuality;
  String imageFormat;
  String defaultCamera;
  String storageLocation;
  bool backgroundServiceEnabled;
  bool discreetMode;
  bool gestureControlsEnabled;
  int volumeButtonPresses;
  
  AppSettings({
    this.deleteAfterSharing = false,
    this.autoDeleteOldRecordings = false,
    this.autoDeleteDays = 30,
    this.themeMode = 'system',
    this.audioSampleRate = '44100',
    this.audioBitRate = '128000',
    this.videoQuality = 'high',
    this.imageFormat = 'jpg',
    this.defaultCamera = 'back',
    this.storageLocation = 'app_vault',
    this.backgroundServiceEnabled = true,
    this.discreetMode = false,
    this.gestureControlsEnabled = true,
    this.volumeButtonPresses = 5,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'deleteAfterSharing': deleteAfterSharing,
      'autoDeleteOldRecordings': autoDeleteOldRecordings,
      'autoDeleteDays': autoDeleteDays,
      'themeMode': themeMode,
      'audioSampleRate': audioSampleRate,
      'audioBitRate': audioBitRate,
      'videoQuality': videoQuality,
      'imageFormat': imageFormat,
      'defaultCamera': defaultCamera,
      'storageLocation': storageLocation,
      'backgroundServiceEnabled': backgroundServiceEnabled,
      'discreetMode': discreetMode,
      'gestureControlsEnabled': gestureControlsEnabled,
      'volumeButtonPresses': volumeButtonPresses,
    };
  }
  
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      deleteAfterSharing: map['deleteAfterSharing'] ?? false,
      autoDeleteOldRecordings: map['autoDeleteOldRecordings'] ?? false,
      autoDeleteDays: map['autoDeleteDays'] ?? 30,
      themeMode: map['themeMode'] ?? 'system',
      audioSampleRate: map['audioSampleRate'] ?? '44100',
      audioBitRate: map['audioBitRate'] ?? '128000',
      videoQuality: map['videoQuality'] ?? 'high',
      imageFormat: map['imageFormat'] ?? 'jpg',
      defaultCamera: map['defaultCamera'] ?? 'back',
      storageLocation: map['storageLocation'] ?? 'app_vault',
      backgroundServiceEnabled: map['backgroundServiceEnabled'] ?? true,
      discreetMode: map['discreetMode'] ?? false,
      gestureControlsEnabled: map['gestureControlsEnabled'] ?? true,
      volumeButtonPresses: map['volumeButtonPresses'] ?? 5,
    );
  }
}