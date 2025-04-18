import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';  // HTML 렌더링 패키지
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: YouTubeSummarizer(),
      supportedLocales: const [
        Locale('en', ''), // 영어
        Locale('ko', ''), // 한국어
        // 필요한 다른 언어를 추가할 수 있습니다
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class YouTubeSummarizer extends StatefulWidget {
  const YouTubeSummarizer({super.key});

  @override
  State<YouTubeSummarizer> createState() => _YouTubeSummarizerState();
}

class _YouTubeSummarizerState extends State<YouTubeSummarizer> {
  final TextEditingController _controller = TextEditingController();
  String _summary = '';
  bool _isLoading = false;

  Future<void> summarizeVideo() async {
    final videoUrl = _controller.text.trim();
    if (videoUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
      _summary = '';
    });

    final uri = Uri.parse('http://localhost:8000/summarize-youtube');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'videoUrl': videoUrl}),
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody);
      setState(() {
        _summary = data['summary'] ?? '요약이 비어있습니다';
      });
    } else {
      setState(() {
        _summary = '요약 실패: ${response.body}';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,  // 차분한 색으로 변경
        title: const Text(
          'YouTube 요약', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2, // 타이틀 간격을 조금 더 넓게
          )
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '유튜브 링크를 입력하고 요약을 받아보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF616161), // 부드러운 색상
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=abc123',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: summarizeVideo,
                  icon: const Icon(Icons.summarize, color: Colors.white),
                  label: const Text('요약하기', style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // 색상 설정
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 로딩 인디케이터 추가
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_summary.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Html(
                        data: _summary,  // HTML 콘텐츠를 렌더링
                        style: {
                          "p": Style(fontSize: FontSize(16), color: Color(0xFF2B2B2B)),
                          "h1": Style(fontSize: FontSize(28), fontWeight: FontWeight.bold, color: Color(0xFF37474F)), // 수정된 부분
                          "h2": Style(fontSize: FontSize(24), fontWeight: FontWeight.w600, color: Color(0xFF37474F)), // 수정된 부분
                          "strong": Style(
                            fontWeight: FontWeight.bold,  // 굵은 폰트로 강조
                            color: Color(0xFF00897B),  // 민트 그린 색상
                            backgroundColor: Color(0xFFE0F2F1),  // 연한 민트 배경
                          ),  
                          "mark": Style(
                            color: Color(0xFF00897B),  // 민트 그린 텍스트 색상
                            backgroundColor: Color(0xFFE0F2F1),  // 연한 민트 배경
                            fontWeight: FontWeight.bold,  // 텍스트 굵게
                          ),
                          "ul": Style(fontSize: FontSize(16), color: Color(0xFF2B2B2B)),
                          "li": Style(fontSize: FontSize(16), color: Color(0xFF4E4E4E)),
                          "blockquote": Style(fontSize: FontSize(18), fontStyle: FontStyle.italic, color: Color(0xFF808080)),
                          "hr": Style(border: Border.all(color: Colors.grey.shade300)),
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
