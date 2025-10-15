/// Spiritual Models and Data Classes
/// Central data models for spiritual analytics and AI components

/// Spiritual Trend Data Structure
class SpiritualTrends {
  final Map<String, double> trendData;
  final DateTime? lastUpdated;
  final List<String> identifiedPatterns;

  const SpiritualTrends({
    required this.trendData,
    this.lastUpdated,
    this.identifiedPatterns = const [],
  });

  factory SpiritualTrends.empty() => const SpiritualTrends(
    trendData: {},
    lastUpdated: null,
    identifiedPatterns: [],
  );
}

/// User Spiritual Profile
class UserSpiritualProfile {
  final String userId;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<PrayerSession> prayerHistory;
  final double spiritualEngagement;
  final List<CommunityActivity> communityActivities;
  final SpiritualLevel spiritualLevel;
  final List<SpiritualChallenge> challenges;
  final String spiritualLevelString; // String representing current level
  final List<String> strengths;
  final List<SpiritualGoal> goals;
  final List<SpiritualMilestone> achievements;

  const UserSpiritualProfile({
    required this.userId,
    required this.createdAt,
    required this.lastUpdated,
    required this.prayerHistory,
    required this.spiritualEngagement,
    required this.communityActivities,
    required this.spiritualLevel,
    required this.challenges,
    required this.spiritualLevelString,
    required this.strengths,
    this.goals = const [],
    this.achievements = const [],
  });

  /// Create builder for user spiritual profile
  factory UserSpiritualProfile.create({required String userId}) {
    return UserSpiritualProfile(
      userId: userId,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      prayerHistory: const [],
      spiritualEngagement: 0.5,
      communityActivities: const [],
      spiritualLevel: SpiritualLevel.beginner,
      challenges: const [],
      spiritualLevelString: 'beginner',
      strengths: const [],
      goals: const [],
      achievements: const [],
    );
  }
}

enum SpiritualLevel {
  beginner,
  intermediate,
  advanced,
  scholar;

  factory SpiritualLevel.fromScore(double score) {
    if (score < 0.3) return SpiritualLevel.beginner;
    if (score < 0.6) return SpiritualLevel.intermediate;
    if (score < 0.8) return SpiritualLevel.advanced;
    return SpiritualLevel.scholar;
  }
}

/// Spiritual Challenge Data
class SpiritualChallenge {
  final String type;
  final String description;

  const SpiritualChallenge(this.type, this.description);
}

/// Spiritual Goal Data
class SpiritualGoal {
  final String id;
  final String title;
  final String description;
  final String category;
  final double progress; // 0.0 to 1.0
  final String priority;
  final DateTime deadline;

  const SpiritualGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.progress,
    this.priority = 'medium',
    required this.deadline,
  });
}

/// Spiritual Milestone Data
class SpiritualMilestone {
  final String id;
  final String title;
  final String description;
  final String category;
  final String criteria;
  final double currentProgress;
  final DateTime expectedDate;
  final String significance;

  const SpiritualMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.criteria,
    required this.currentProgress,
    required this.expectedDate,
    required this.significance,
  });
}

/// Predictive Model Data Structure
class PredictiveModel {
  final String name;
  final String type;
  final double accuracy;
  final DateTime lastTrained;
  final Map<String, dynamic> parameters;

  const PredictiveModel({
    required this.name,
    required this.type,
    required this.accuracy,
    required this.lastTrained,
    required this.parameters,
  });
}

/// Recommendation Engine Data Structure
class RecommendationEngine {
  final String name;
  final String category;
  final double accuracy;
  final List<RecommendationRule> rules;
  final DateTime lastUpdated;

  const RecommendationEngine({
    required this.name,
    required this.category,
    required this.accuracy,
    required this.rules,
    required this.lastUpdated,
  });
}

/// Recommendation Rule Data Structure
class RecommendationRule {
  final String condition;
  final String action;
  final double priority;
  final String category;
  final Map<String, dynamic> parameters;

  const RecommendationRule({
    required this.condition,
    required this.action,
    this.priority = 1.0,
    required this.category,
    required this.parameters,
  });
}

/// Prayer Session Data Structure
class PrayerSession {
  final String sessionId;
  final String userId;
  final String prayerName;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double quality; // 1-10 quality score
  final bool completed;
  final Map<String, dynamic> factors; // Environmental and personal factors

  const PrayerSession({
    required this.sessionId,
    required this.userId,
    required this.prayerName,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.quality,
    required this.completed,
    this.factors = const {},
  });
}

/// Community Activity Data Structure
class CommunityActivity {
  final String id;
  final String name;
  final String description;
  final String category;
  final DateTime date;
  final String location;
  final List<String> participants;
  final bool isOnline;
  final String impact;

  const CommunityActivity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.date,
    required this.location,
    this.participants = const [],
    required this.isOnline,
    this.impact = 'medium',
  });
}

/// Spiritual Dashboard Data Structure
class SpiritualDashboard {
  final UserSpiritualProfile userProfile;
  final List<RealtimeInsight> realtimeInsights;
  final List<AIRecommendation> aiRecommendations;
  final PredictiveInsights predictiveInsights;
  final double spiritualHealthScore;
  final CommunityEngagementMetrics communityEngagementMetrics;
  final SpiritualGrowth spiritualGrowth;
  final List<SpiritualMilestone> nextMilestones;

  const SpiritualDashboard({
    required this.userProfile,
    required this.realtimeInsights,
    required this.aiRecommendations,
    required this.predictiveInsights,
    required this.spiritualHealthScore,
    required this.communityEngagementMetrics,
    required this.spiritualGrowth,
    required this.nextMilestones,
  });

  factory SpiritualDashboard.fallback() {
    return SpiritualDashboard(
      userProfile: UserSpiritualProfile.create(userId: 'anonymous'),
      realtimeInsights: const [],
      aiRecommendations: const [],
      predictiveInsights: PredictiveInsights.empty(),
      spiritualHealthScore: 0.7,
      communityEngagementMetrics: CommunityEngagementMetrics.basic(),
      spiritualGrowth: SpiritualGrowth.basic(),
      nextMilestones: const [],
    );
  }
}

/// Realtime Insight Data Structure
class RealtimeInsight {
  final String type;
  final String message;
  final String actionRecommended;
  final String urgency;
  final DateTime timestamp;

  const RealtimeInsight({
    required this.type,
    required this.message,
    required this.actionRecommended,
    required this.urgency,
    required this.timestamp,
  });
}

/// AI Recommendation Data Structure
class AIRecommendation {
  final String category;
  final String title;
  final String description;
  final String impact;
  final String effort;
  final String timeframe;
  final double relevance;
  final List<String> actions;

  const AIRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.impact,
    required this.effort,
    required this.timeframe,
    required this.relevance,
    required this.actions,
  });
}

/// Predictive Insights Data Structure
class PredictiveInsights {
  final List<String> next30days;
  final List<String> next3months;
  final List<String> next6months;
  final double confidence;

  const PredictiveInsights({
    required this.next30days,
    required this.next3months,
    required this.next6months,
    required this.confidence,
  });

  factory PredictiveInsights.empty() => const PredictiveInsights(
    next30days: const [],
    next3months: const [],
    next6months: const [],
    confidence: 0.7,
  );
}

/// Community Engagement Metrics
class CommunityEngagementMetrics {
  final double participationRate;
  final int leadershipRoles;
  final int mentorshipConnections;
  final List<CommunityContribution> communityContributions;
  final double socialImpact;

  const CommunityEngagementMetrics({
    required this.participationRate,
    required this.leadershipRoles,
    required this.mentorshipConnections,
    required this.communityContributions,
    required this.socialImpact,
  });

  factory CommunityEngagementMetrics.basic() {
    return CommunityEngagementMetrics(
      participationRate: 0.5,
      leadershipRoles: 0,
      mentorshipConnections: 0,
      communityContributions: const [],
      socialImpact: 0.4,
    );
  }
}

/// Spiritual Growth Data Structure
class SpiritualGrowth {
  final double overallScore;
  final Map<String, List<double>> aspects;
  final List<String> improvements;
  final double growthRate;

  const SpiritualGrowth({
    required this.overallScore,
    required this.aspects,
    required this.improvements,
    required this.growthRate,
  });

  factory SpiritualGrowth.basic() {
    return SpiritualGrowth(
      overallScore: 0.7,
      aspects: const {
        'prayer': [0.8, 0.75, 0.82],
        'engagement': [0.6, 0.8, 0.75],
        'character': [0.7, 0.8, 0.65],
      },
      improvements: const [
        'consistent_prayer',
        'increased_reading',
        'improved_patience',
      ],
      growthRate: 0.05,
    );
  }
}

class CommunityContribution {
  final String id;
  final String type;
  final String description;
  final String impact;
  final DateTime date;
  final int participantsCount;

  const CommunityContribution({
    required this.id,
    required this.type,
    required this.description,
    this.impact = 'medium',
    required this.date,
    required this.participantsCount,
  });
}

class PrayerPatternAnalysis {
  final double consistencyScore;
  final DailyPattern dailyPattern;
  final WeeklyPattern? weeklyPattern;
  final SeasonalPattern? seasonalPattern;
  final List<double> improvementTrends;
  final List<String> identifiedStrengths;
  final List<String> areasForImprovement;
  final List<AIInsight> aiInsights;
  final List<PrayerRecommendation> recommendations;

  const PrayerPatternAnalysis({
    required this.consistencyScore,
    required this.dailyPattern,
    this.weeklyPattern,
    this.seasonalPattern,
    required this.improvementTrends,
    required this.identifiedStrengths,
    required this.areasForImprovement,
    this.aiInsights = const [],
    required this.recommendations,
  });

  factory PrayerPatternAnalysis.fallback() => const PrayerPatternAnalysis(
    consistencyScore: 0.7,
    dailyPattern: DailyPattern.basic,
    improvementTrends: [0.05],
    identifiedStrengths: ['early prayer', 'consistent routine'],
    areasForImprovement: ['evening prayer times', 'deeper focus'],
    aiInsights: const [],
    recommendations: const [],
  );
}

class DailyPattern {
  final Map<String, double> dailyRatios;
  final double overallConsistency;
  final String? peakTime;
  final List<String> weaknesses;

  const DailyPattern({
    required this.dailyRatios,
    required this.overallConsistency,
    this.peakTime,
    this.weaknesses = const [],
  });

  static const DailyPattern basic = DailyPattern(
    dailyRatios: {'morning': 0.8, 'afternoon': 0.7, 'evening': 0.9},
    overallConsistency: 0.8,
    peakTime: '6:00 AM',
    weaknesses: ['occasional late prayers'],
  );
}

class WeeklyPattern {
  final Map<String, double> weeklyRatios;
  final double overallConsistency;
  final bool fridaySpecial;
  final double weekendVariation;
  final double weekdayConsistency;
  final double weeklyAverage;
  final List<String> patterns;

  const WeeklyPattern({
    required this.weeklyRatios,
    required this.overallConsistency,
    required this.fridaySpecial,
    required this.weekendVariation,
    required this.weekdayConsistency,
    required this.weeklyAverage,
    required this.patterns,
  });

  factory WeeklyPattern.basic() {
    return WeeklyPattern(
      weeklyRatios: const {'friday': 0.9, 'weekend': 0.75, 'weekday': 0.85},
      overallConsistency: 0.82,
      fridaySpecial: true,
      weekendVariation: 0.1,
      weekdayConsistency: 0.85,
      weeklyAverage: 0.8,
      patterns: const [],
    );
  }
}

class SeasonalPattern {
  final Map<String, double> seasonalRatios;
  final double ramadanElevation;
  final double winterConsistency;
  final double summerConsistency;
  final double seasonalAverage;

  const SeasonalPattern({
    required this.seasonalRatios,
    this.ramadanElevation = 1.2, // 20% enhancement
    this.winterConsistency = 0.88, // Maintained in colder weather
    this.summerConsistency = 0.78, // Summer flexibility
    this.seasonalAverage = 0.8,
  });
}

class AIInsight {
  final String category;
  final String insight;
  final String recommendation;
  final String priority;
  final double confidence;

  const AIInsight({
    required this.category,
    required this.insight,
    required this.recommendation,
    required this.priority,
    required this.confidence,
  });
}

class PrayerRecommendation {
  final String category;
  final String title;
  final String description;
  final List<String> actions;
  final String timeframe;
  final String expectedBenefit;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final int effort; // 1-5 scale
  final double expectedImpact; // 0.0-1.0 value

  const PrayerRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actions,
    required this.timeframe,
    required this.expectedBenefit,
    this.priority = 'medium',
    this.effort = 3,
    this.expectedImpact = 0.7,
  });
}

class SpiritualHealthReport {
  final double overallScore;
  final Map<String, double> metrics;
  final List<String> strongAreas;
  final List<String> areasForImprovement;
  final String healthTrend;
  final List<HealthRecommendation> recommendations;
  final double spiritualVitality;
  final double resilience;

  const SpiritualHealthReport({
    required this.overallScore,
    required this.metrics,
    required this.strongAreas,
    required this.areasForImprovement,
    required this.healthTrend,
    required this.recommendations,
    required this.spiritualVitality,
    required this.resilience,
  });

  factory SpiritualHealthReport.fallback() {
    return SpiritualHealthReport(
      overallScore: 0.6,
      metrics: const {},
      strongAreas: const [],
      areasForImprovement: const [],
      healthTrend: 'stable',
      recommendations: const [],
      spiritualVitality: 0.7,
      resilience: 0.6,
    );
  }
}

class HealthRecommendation {
  final String category;
  final String recommendation;
  final String rationale;
  final String priority;
  final List<String> actions;

  const HealthRecommendation({
    required this.category,
    required this.recommendation,
    required this.rationale,
    required this.priority,
    required this.actions,
  });
}

class SpiritualPredictions {
  final int predictionPeriod;
  final Prediction prayerConsistencyPrediction;
  final Prediction spiritualGrowthPrediction;
  final List<Prediction> challengePredictions;
  final List<Prediction> opportunityPredictions;
  final Prediction communityEngagementPrediction;
  final double confidenceLevel;
  final Map<String, double> seasonalAdjustments;
  final Map<String, double> personalizedFactors;

  const SpiritualPredictions({
    required this.predictionPeriod,
    required this.prayerConsistencyPrediction,
    required this.spiritualGrowthPrediction,
    this.challengePredictions = const [],
    this.opportunityPredictions = const [],
    required this.communityEngagementPrediction,
    required this.confidenceLevel,
    required this.seasonalAdjustments,
    required this.personalizedFactors,
  });

  factory SpiritualPredictions.fallback() {
    return SpiritualPredictions(
      predictionPeriod: 30,
      prayerConsistencyPrediction: Prediction.average,
      spiritualGrowthPrediction: Prediction.stable,
      challengePredictions: const [],
      opportunityPredictions: const [],
      communityEngagementPrediction: Prediction.decreasing,
      confidenceLevel: 0.7,
      seasonalAdjustments: const {},
      personalizedFactors: const {},
    );
  }
}

class Prediction {
  final String
  outlook; // 'positive', 'negative', 'stable', 'improving', 'declining'
  final double probability; // 0.0-1.0
  final String description; // Prediction detail

  const Prediction({
    required this.outlook,
    required this.probability,
    required this.description,
  });

  static const Prediction average = Prediction(
    outlook: 'stable',
    probability: 0.7,
    description: 'No significant change expected',
  );

  static const Prediction moderate = Prediction(
    outlook: 'growth',
    probability: 0.6,
    description: 'Moderate growth expected',
  );

  static const Prediction increasing = Prediction(
    outlook: 'improvement',
    probability: 0.8,
    description: 'Improvement expected',
  );

  static const Prediction stable = Prediction(
    outlook: 'stable',
    probability: 0.7,
    description: 'Stable pattern expected',
  );

  static const Prediction decreasing = Prediction(
    outlook: 'declining',
    probability: 0.6,
    description: 'Decline expected',
  );
}

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool get isNotEmpty => start.isBefore(end);
}

class GrowthRecommendation {
  final SpiritualCategory category;
  final String title;
  final String description;
  final List<String> actions;
  final String timeframe;
  final List<String> prerequisites;
  final String expectedImpact;

  const GrowthRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actions,
    required this.timeframe,
    this.prerequisites = const [],
    required this.expectedImpact,
  });
}

enum SpiritualCategory {
  prayer,
  community,
  knowledge,
  character,
  worship,
  family,
  service,
}

class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final bool success;
  final Map<String, dynamic>? context;
  final String category;

  const PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.success,
    this.context,
    required this.category,
  });
}

class Threshold {
  final String thresholdName;
  final double thresholdValue; // Target value in MS or appropriate unit
  final String warningLevel; // 'warning', 'critical', 'info', 'info'
  final String criticalLevel; // same options as warning

  const Threshold({
    required this.thresholdName,
    required this.thresholdValue,
    required this.warningLevel,
    required this.criticalLevel,
  });
}

class PerformanceThreshold {
  final String name;
  final double value;
  final String severity;

  const PerformanceThreshold({
    required this.name,
    required this.value,
    required this.severity,
  });
}

class PerformanceAlert {
  final String id;
  final String operation;
  final Duration duration;
  final String severity; // 'warning', 'critical', 'info'
  final DateTime timestamp;
  final PerformanceThreshold? threshold;
  final bool resolved;

  const PerformanceAlert({
    required this.id,
    required this.operation,
    required this.duration,
    required this.severity,
    required this.timestamp,
    this.threshold,
    required this.resolved,
  });
}

class PerformanceSnapshot {
  final double cpuUsage;
  final double memoryUsage;
  final double networkUsage;
  final double batteryLevel;
  final Duration appStartTime;
  final double frameRate;
  final Duration responseTime;
  final double errorRate;
  final double cacheHitRate;
  final DateTime timestamp;

  const PerformanceSnapshot({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.networkUsage,
    required this.batteryLevel,
    required this.appStartTime,
    required this.frameRate,
    required this.responseTime,
    required this.errorRate,
    required this.cacheHitRate,
    required this.timestamp,
  });

  factory PerformanceSnapshot.empty() => PerformanceSnapshot(
    cpuUsage: 0.0,
    memoryUsage: 0.0,
    networkUsage: 0.0,
    batteryLevel: 1.0,
    appStartTime: Duration.zero,
    frameRate: 0.0,
    responseTime: Duration.zero,
    errorRate: 0.0,
    cacheHitRate: 0.0,
    timestamp: DateTime.now(),
  );
}

class PerformanceDashboard {
  final PerformanceSnapshot snapshot;
  final List<PerformanceTrend> trends;
  final List<OptimizationRecommendation> recommendations;
  final List<PerformanceAlert> alerts;
  final double performanceScore;

  const PerformanceDashboard({
    required this.snapshot,
    required this.trends,
    required this.recommendations,
    required this.alerts,
    required this.performanceScore,
  });
}

class PerformanceTrend {
  final String category;
  final String direction; // 'increasing', 'decreasing', 'stable'
  final double percentChange;
  final String timeframe;

  const PerformanceTrend({
    required this.category,
    required this.direction,
    required this.percentChange,
    required this.timeframe,
  });
}

class OptimizationRecommendation {
  final String category;
  final String title;
  final String description;
  final String priority;
  final String effort;
  final String estimatedImpact;
  final List<String> actions;

  const OptimizationRecommendation({
    required this.category,
    required this.title,
    required this.description,
    this.priority = 'medium',
    this.effort = 'medium',
    this.estimatedImpact = 'moderate',
    this.actions = const [],
  });
}

class NotificationTestResult {
  final bool testCompleted;
  final bool audioWorking;
  final bool vibrationWorking;
  final bool permissionsGranted;
  final List<String> recommendations;

  const NotificationTestResult({
    required this.testCompleted,
    required this.audioWorking,
    required this.vibrationWorking,
    required this.permissionsGranted,
    this.recommendations = const [],
  });

  factory NotificationTestResult.testFailed() => const NotificationTestResult(
    testCompleted: false,
    audioWorking: false,
    vibrationWorking: false,
    permissionsGranted: false,
    recommendations: const [],
  );
}

class NotificationAnalytics {
  final int totalNotifications;
  final int deliveredNotifications;
  final int openedNotifications;
  final int dismissedNotifications;
  final Duration averageResponseTime;
  final List<String> optimalTimes;
  final Map<String, int> categoriesBreakdown;
  final UserPreferenceAnalysis userPreferences;
  final List<NotificationOptimization> recommendations;

  const NotificationAnalytics({
    required this.totalNotifications,
    required this.deliveredNotifications,
    required this.openedNotifications,
    required this.dismissedNotifications,
    required this.averageResponseTime,
    required this.optimalTimes,
    required this.categoriesBreakdown,
    required this.userPreferences,
    required this.recommendations,
  });
}

class UserPreferenceAnalysis {
  final Map<String, double> categoryPreferences;
  final List<String> preferredTimes;
  final double notificationTolerance;
  final List<String> suppressedCategories;

  const UserPreferenceAnalysis({
    required this.categoryPreferences,
    required this.preferredTimes,
    required this.notificationTolerance,
    required this.suppressedCategories,
  });
}

class NotificationOptimization {
  final String type;
  final String recommendation;
  final double expectedImpact;
  final String effort;

  const NotificationOptimization({
    required this.type,
    required this.recommendation,
    required this.expectedImpact,
    required this.effort,
  });
}

class SpiritualGrowthAnalysis {
  final List<GrowthInsight> insights;
  final List<SpiritualTrendPrediction> trends;
  final List<String> recommendations;
  final double growthScore;
  final DateTime lastUpdated;

  const SpiritualGrowthAnalysis({
    required this.insights,
    required this.trends,
    required this.recommendations,
    required this.growthScore,
    required this.lastUpdated,
  });
}

class GrowthInsight {
  final String type;
  final String message;
  final String recommendation;
  final String priority;
  final double confidence;

  const GrowthInsight({
    required this.type,
    required this.message,
    required this.recommendation,
    required this.priority,
    required this.confidence,
  });
}

class SpiritualTrendPrediction {
  final String pattern;
  final String trend;
  final double probability;
  final String timeframe;
  final List<String> factors;

  const SpiritualTrendPrediction({
    required this.pattern,
    required this.trend,
    required this.probability,
    required this.timeframe,
    required this.factors,
  });
}
