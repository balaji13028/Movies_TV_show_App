import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class FullScreenAd extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const FullScreenAd(
      {super.key, required this.imageUrl, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16, // or make it full screen with BoxFit.cover
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    "https://media9tv.com/public/storage/$imageUrl",
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 15,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class HomeAdPoster extends StatefulWidget {
//   final String imageUrl;
//
//   const HomeAdPoster({super.key, required this.imageUrl});
//
//   @override
//   State<HomeAdPoster> createState() => _HomeAdPosterState();
// }
//
// class _HomeAdPosterState extends State<HomeAdPoster> {
//   bool _isVisible = true;
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isVisible) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(16), // nice rounded edges
//             child: AspectRatio(
//               aspectRatio: 4 / 5, // 1080 x 1350
//               child: Image.network(
//                "https://media9tv.com/public/storage/${widget.imageUrl}",
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, progress) {
//                   if (progress == null) return child;
//                   return const Center(child: CircularProgressIndicator());
//                 },
//                 errorBuilder: (context, error, stackTrace) =>
//                 const Center(child: Icon(Icons.broken_image, size: 40)),
//               ),
//             ),
//           ),
//           Positioned(
//             top: 8,
//             right: 8,
//             child: GestureDetector(
//               onTap: () => setState(() => _isVisible = false),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   shape: BoxShape.circle,
//                 ),
//                 padding: const EdgeInsets.all(6),
//                 child: const Icon(Icons.close, color: Colors.white, size: 18),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
