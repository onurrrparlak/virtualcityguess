import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  bool get isAdLoaded => _isAdLoaded;

  AdService() {
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    print('[AdService] Loading rewarded ad...');
    
    RewardedAd.load(
      adUnitId: "ca-app-pub-3940256099942544/5224354917", // Test ad unit ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('[AdService] Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isAdLoaded = true;

          // Set up full-screen content callbacks
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('[AdService] Ad showed full screen content.');
            },
            onAdImpression: (ad) {
              print('[AdService] Ad impression recorded.');
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              print('[AdService] Ad failed to show full screen content: $err');
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              notifyListeners();
              _loadRewardedAd(); // Try loading a new ad
            },
            onAdDismissedFullScreenContent: (ad) {
              print('[AdService] Ad dismissed full screen content.');
              ad.dispose();
              _rewardedAd = null;
              _isAdLoaded = false;
              notifyListeners();
              _loadRewardedAd(); // Load a new ad
            },
            onAdClicked: (ad) {
              print('[AdService] Ad clicked.');
            },
          );

          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('[AdService] Failed to load rewarded ad: $error');
          _isAdLoaded = false;
          notifyListeners();
        },
      ),
    );
  }

  void showRewardedAd() {
    if (_rewardedAd != null) {
      print('[AdService] Showing rewarded ad...');
      
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('[AdService] User earned reward: ${reward.amount} ${reward.type}');
          _loadRewardedAd(); // Load a new ad after showing the current one
        },
      );

      _rewardedAd = null; // Clear the ad reference to avoid reuse
      _isAdLoaded = false;
      notifyListeners();
    } else {
      print('[AdService] No rewarded ad available to show.');
    }
  }
}
