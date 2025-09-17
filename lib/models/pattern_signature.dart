class PatternSignature {
  final String id;
  final String name;
  final List<double> timestamps; // Timestamps of taps in milliseconds
  final DateTime createdAt;
  final String assignedFunction; // audio, video, image, sos, or custom

  PatternSignature({
    required this.id,
    required this.name,
    required this.timestamps,
    required this.createdAt,
    this.assignedFunction = 'custom',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'timestamps': timestamps,
      'createdAt': createdAt.toIso8601String(),
      'assignedFunction': assignedFunction,
    };
  }

  factory PatternSignature.fromMap(Map<String, dynamic> map) {
    return PatternSignature(
      id: map['id'],
      name: map['name'],
      timestamps: List<double>.from(map['timestamps']),
      createdAt: DateTime.parse(map['createdAt']),
      assignedFunction: map['assignedFunction'] ?? 'custom',
    );
  }

  // Calculate the intervals between taps
  List<double> get intervals {
    if (timestamps.length <= 1) return [];
    List<double> result = [];
    for (int i = 1; i < timestamps.length; i++) {
      result.add(timestamps[i] - timestamps[i - 1]);
    }
    return result;
  }

  // Match this pattern with another with 60% tolerance
  bool matches(PatternSignature other, {double tolerance = 0.6}) {
    // If both patterns have no taps, they match
    if (timestamps.isEmpty && other.timestamps.isEmpty) return true;
    
    // If one is empty and the other isn't, they don't match
    if (timestamps.isEmpty || other.timestamps.isEmpty) return false;
    
    // Calculate intervals for both patterns
    List<double> thisIntervals = intervals;
    List<double> otherIntervals = other.intervals;
    
    // If both have no intervals, they match
    if (thisIntervals.isEmpty && otherIntervals.isEmpty) return true;
    
    // If one has no intervals and the other does, they don't match
    if (thisIntervals.isEmpty || otherIntervals.isEmpty) return false;
    
    // Compare intervals with tolerance
    int matchCount = 0;
    int totalCount = thisIntervals.length;
    
    // Compare up to the length of the shorter pattern
    int compareLength = thisIntervals.length < otherIntervals.length 
        ? thisIntervals.length 
        : otherIntervals.length;
    
    for (int i = 0; i < compareLength; i++) {
      // Calculate the difference as a percentage of the larger value
      double diff = (thisIntervals[i] - otherIntervals[i]).abs();
      double maxVal = thisIntervals[i] > otherIntervals[i] 
          ? thisIntervals[i] 
          : otherIntervals[i];
      
      // If maxVal is 0, and both are 0, they match
      if (maxVal == 0) {
        matchCount++;
        continue;
      }
      
      // Calculate percentage difference
      double percentDiff = diff / maxVal;
      
      // If difference is less than (1 - tolerance), it's a match
      if (percentDiff <= (1 - tolerance)) {
        matchCount++;
      }
    }
    
    // Calculate match percentage
    double matchPercentage = matchCount / totalCount;
    return matchPercentage >= tolerance;
  }
}