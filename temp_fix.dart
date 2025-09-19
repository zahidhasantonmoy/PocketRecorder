        ),
      ),
    );
  }
  
  void _exportData() {
    // In a real app, you would export the data to a file or share it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data exported successfully!'),
      ),
    );
  }
  
  void _copyDataToClipboard() {
