import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtualcityguess/models/app_localizations.dart';
import 'package:virtualcityguess/services/ad_service.dart';

class CoinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context);
    final AppLocalizations? appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations?.translate('coin_screen_title') ?? 'Coin Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            if (adService.isAdLoaded) {
              adService.showRewardedAd();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(appLocalizations?.translate('ad_not_loaded_yet') ?? 'Ad not loaded yet, please try again later.')),
              );
            }
          },
          child: Text(appLocalizations?.translate('earncoin') ?? 'Earn Coins'),
        ),
      ),
    );
  }
}
