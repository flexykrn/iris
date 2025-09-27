import 'dart:math';

class MockAIService {
  static final MockAIService _instance = MockAIService._internal();
  factory MockAIService() => _instance;
  MockAIService._internal();

  final Random _random = Random();
  final List<String> _sceneDescriptions = [
    "A person walking in front of you",
    "A door ahead with a handle on the right",
    "A staircase going up",
    "A table with chairs around it",
    "A wall directly ahead",
    "An open space with no obstacles",
    "A car parked on the left side",
    "A tree trunk on the right",
    "A bench to sit on",
    "A crosswalk with traffic lights",
    "A building entrance with steps",
    "A sidewalk with cracks",
    "A trash can on the right",
    "A mailbox on the left",
    "A street sign ahead",
  ];

  final List<Map<String, dynamic>> _navigationResponses = [
    {"directions": "Obstacle ahead on left", "alert": true},
    {"directions": "Clear path straight ahead", "alert": false},
    {"directions": "Turn right to avoid obstacle", "alert": true},
    {"directions": "Step up - curb ahead", "alert": true},
    {"directions": "Step down - curb ahead", "alert": true},
    {"directions": "Door on the right", "alert": false},
    {"directions": "Stairs going up ahead", "alert": true},
    {"directions": "Narrow passage - walk carefully", "alert": true},
    {"directions": "Wide open area", "alert": false},
    {"directions": "Uneven surface ahead", "alert": true},
  ];

  Future<String> getSceneDescription() async {
    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: 500));

    return _sceneDescriptions[_random.nextInt(_sceneDescriptions.length)];
  }

  Future<Map<String, dynamic>> getNavigationGuidance() async {
    // Simulate processing delay
    await Future.delayed(Duration(milliseconds: 500));

    return _navigationResponses[_random.nextInt(_navigationResponses.length)];
  }

  Future<String> processImage(String imagePath) async {
    // Simulate image processing delay
    await Future.delayed(Duration(milliseconds: 800));

    // Randomly return either scene description or navigation guidance
    if (_random.nextBool()) {
      return await getSceneDescription();
    } else {
      final nav = await getNavigationGuidance();
      return nav['directions'];
    }
  }

  // Future method for real AI integration
  Future<String> processImageWithRealAI(String imagePath) async {
    // This would be replaced with actual AI service call
    // For now, return mock data
    return await processImage(imagePath);
  }
}
