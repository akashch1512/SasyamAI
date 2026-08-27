import 'package:flutter_test/flutter_test.dart';
import 'package:flutterfrontend/main.dart';
import 'package:flutterfrontend/models/admin_model.dart';
import 'package:flutterfrontend/models/chat_model.dart';
import 'package:flutterfrontend/models/user_model.dart';
import 'package:flutterfrontend/widgets/app_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SasyamAIApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SasyamAIApp());
    expect(find.byType(AppLogo), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
  });

  test('UserModel JSON serialization test', () {
    final user = UserModel(
      id: 1,
      email: 'farmer@sasyamai.com',
      fullName: 'Ramesh Patel',
      role: 'user',
      state: 'Gujarat',
      district: 'Rajkot',
      soilType: 'Black Soil',
      landSizeAcres: 12.5,
      irrigationSource: 'Drip',
      primaryCrops: 'Cotton, Groundnut',
      isOnboarded: true,
    );

    final json = user.toJson();
    expect(json['email'], 'farmer@sasyamai.com');
    expect(json['state'], 'Gujarat');
    expect(json['land_size_acres'], 12.5);

    final recreated = UserModel.fromJson(json);
    expect(recreated.fullName, 'Ramesh Patel');
    expect(recreated.isOnboarded, true);
    expect(recreated.isAdmin, false);
  });

  test('ChatMessageModel and ChatSessionModel JSON test', () {
    final message = ChatMessageModel(
      id: 'msg-1',
      sessionId: 'sess-1',
      role: 'assistant',
      content: 'Recommended crops: Wheat, Mustard',
      createdAt: DateTime.now(),
    );

    expect(message.isUser, false);
    expect(message.content, contains('Wheat'));

    final session = ChatSessionModel(
      id: 'sess-1',
      userId: 1,
      title: 'Winter Crop Selection',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: 1,
      messages: [message],
    );

    expect(session.title, 'Winter Crop Selection');
    expect(session.messages.length, 1);
  });

  test('AdminStatsModel JSON parsing test', () {
    final rawData = {
      'total_users': 25,
      'total_queries': 140,
      'total_disease_scans': 45,
      'total_crop_recommendations': 60,
      'category_breakdown': [
        {'category': 'crop_recommendation', 'count': 60, 'percentage': 42.8},
        {'category': 'disease_detection', 'count': 45, 'percentage': 32.1},
      ],
      'top_crops_searched': [
        {'crop_name': 'Cotton', 'inquiry_count': 35},
      ],
      'state_distribution': [
        {'state': 'Maharashtra', 'query_count': 50},
      ],
    };

    final stats = AdminStatsModel.fromJson(rawData);
    expect(stats.totalUsers, 25);
    expect(stats.totalQueries, 140);
    expect(stats.categoryBreakdown.length, 2);
    expect(stats.topCrops.first.cropName, 'Cotton');
  });
}
