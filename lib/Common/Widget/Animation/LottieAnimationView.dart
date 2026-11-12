// import 'package:flame_spine/flame_spine.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';

// import 'package:gif_view/gif_view.dart';

class LottieAnimationView extends StatefulWidget {
  const LottieAnimationView({super.key});

  @override
  State<LottieAnimationView> createState() => _LottieAnimationViewState();
}

// class _LottieAnimationViewState extends State<LottieAnimationView> {
//   final SpineWidgetController _controller =
//       SpineWidgetController(onInitialized: (controller) {
//     // Set the walk animation on track 0, let it loop
//     controller.animationState.setAnimationByName(0, "animation", true);
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: SizedBox(
//         width: 90,
//         height: 90,
//         child: SpineWidget.fromAsset("assets/spine/loading/skeleton.atlas",
//             "assets/spine/loading/skeleton.json", _controller),
//       ),
//     );

//     // GifView.asset(
//     //   'assets/JIF/loading.gif',
//     //   height: 90,
//     //   width: 90,
//     //   frameRate: 30,
//     // ),
//   }

class _LottieAnimationViewState extends State<LottieAnimationView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 93,
        height: 93,
        child: // Load a Lottie file from your assets
        Lottie.asset(
          'assets/lottie/loading/loading.json',
        ),
      ),
    );
  }
}
