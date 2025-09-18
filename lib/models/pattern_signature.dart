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

  // Match this pattern with another with tolerance
  bool matches(PatternSignature other, {double tolerance = 0.6}) {
    // If both patterns have no taps, they match
    if (timestamps.isEmpty && other.timestamps.isEmpty) return true;
    
    // If one is empty and the other isn't, they don't match
    if (timestamps.isEmpty || other.timestamps.isEmpty) return false;
    
    // If we have very different numbers of taps, they don't match
    if ((timestamps.length - other.timestamps.length).abs() > 1) return false;
    
    // Calculate intervals for both patterns
    List<double> thisIntervals = intervals;
    List<double> otherIntervals = other.intervals;
    
    // If both have no intervals, they match
    if (thisIntervals.isEmpty && otherIntervals.isEmpty) return true;
    
    // If one has no intervals and the other does, they don't match
    if (thisIntervals.isEmpty || otherIntervals.isEmpty) return false;
    
    // Compare intervals with tolerance using dynamic time warping approach
    return _compareIntervalsWithTolerance(thisIntervals, otherIntervals, tolerance);
  }
  
  // Compare intervals with tolerance using a simplified approach
  bool _compareIntervalsWithTolerance(List<double> intervals1, List<double> intervals2, double tolerance) {
    // Use the shorter pattern as reference
    List<double> refIntervals = intervals1.length <= intervals2.length ? intervals1 : intervals2;
    List<double> testIntervals = intervals1.length <= intervals2.length ? intervals2 : intervals1;
    
    // If reference has only one interval, compare directly
    if (refIntervals.length == 1) {
      if (testIntervals.length == 1) {
        // Compare single intervals
        double diff = (refIntervals[0] - testIntervals[0]).abs();
        double maxVal = refIntervals[0] > testIntervals[0] ? refIntervals[0] : testIntervals[0];
        return maxVal == 0 ? true : (diff / maxVal) <= (1 - tolerance);
      } else {
        // Test pattern has more intervals, check if they're similar to reference
        int matchCount = 0;
        for (double interval in testIntervals) {
          double diff = (refIntervals[0] - interval).abs();
          double maxVal = refIntervals[0] > interval ? refIntervals[0] : interval;
          if (maxVal == 0 || (diff / maxVal) <= (1 - tolerance)) {
            matchCount++;
          }
        }
        return matchCount / testIntervals.length >= tolerance;
      }
    }
    
    // For multiple intervals, use a simple matching approach
    int matchCount = 0;
    int totalCount = refIntervals.length;
    
    // Compare up to the length of the shorter pattern
    int compareLength = refIntervals.length < testIntervals.length 
        ? refIntervals.length 
        : testIntervals.length;
    
    for (int i = 0; i < compareLength; i++) {
      // Calculate the difference as a percentage of the larger value
      double diff = (refIntervals[i] - testIntervals[i]).abs();
      double maxVal = refIntervals[i] > testIntervals[i] 
          ? refIntervals[i] 
          : testIntervals[i];
      
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
  
  // Calculate similarity score (0.0 to 1.0)
  double similarityScore(PatternSignature other) {
    if (timestamps.isEmpty && other.timestamps.isEmpty) return 1.0;
    if (timestamps.isEmpty || other.timestamps.isEmpty) return 0.0;
    
    List<double> thisIntervals = intervals;
    List<double> otherIntervals = other.intervals;
    
    if (thisIntervals.isEmpty && otherIntervals.isEmpty) return 1.0;
    if (thisIntervals.isEmpty || otherIntervals.isEmpty) return 0.0;
    
    // Simple average difference calculation
    int minLength = thisIntervals.length < otherIntervals.length 
        ? thisIntervals.length 
        : otherIntervals.length;
    
    double totalDifference = 0.0;
    for (int i = 0; i < minLength; i++) {
      double avg = (thisIntervals[i] + otherIntervals[i]) / 2;
      if (avg > 0) {
        totalDifference += (thisIntervals[i] - otherIntervals[i]).abs() / avg;
      }
    }
    
    double averageDifference = totalDifference / minLength;
    return 1.0 - (averageDifference > 1.0 ? 1.0 : averageDifference);
  }
}