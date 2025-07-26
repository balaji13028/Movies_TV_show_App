import 'package:flutter/material.dart';
import 'package:media9/utils/color.dart';
import 'package:media9/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final String title;
  final String url;
  const PrivacyPolicyScreen(
      {super.key, required this.title, required this.url});
  @override
  PrivacyPolicyScreenState createState() {
    return PrivacyPolicyScreenState();
  }
}

class PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<String> localLoader() async {
    return "https://policies.google.com/privacy?hl=en-US";
  }

  late final WebViewController _controller;
  bool _isLoading = true; // Initialize as true to show the loader initially

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(appBgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // You can use this to update a custom loading bar if needed
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true; // Start loading
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Finished loading
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Handle web resource errors here if needed
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: Utils.myAppBarWithBack(context, widget.title, false),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
          ),
          if (_isLoading) // Show the loader if isLoading is true
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
