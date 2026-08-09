class QuizQuestion {
  final int id;
  final String title;
  final String sender;
  final String content;
  final String type; // 'phish' or 'legit'
  final String category; // 'Email' or 'SMS'
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.title,
    required this.sender,
    required this.content,
    required this.type,
    required this.category,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'phish',
      category: json['category'] ?? 'Email',
      explanation: json['explanation'] ?? '',
    );
  }
}

class LeaderboardScore {
  final int? id;
  final String username;
  final int score;
  final int total;
  final DateTime timestamp;

  LeaderboardScore({
    this.id,
    required this.username,
    required this.score,
    required this.total,
    required this.timestamp,
  });

  factory LeaderboardScore.fromJson(Map<String, dynamic> json) {
    return LeaderboardScore(
      id: json['id'],
      username: json['username'] ?? 'Anonymous',
      score: json['score'] ?? 0,
      total: json['total'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
