import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The login page's wallet illustration, built from layers so it can move:
/// the wallet slides up, the coins pop out one by one, the top coin bounces,
/// then everything floats gently.
///
/// [intro] runs once from 0 to 1 and is owned by the caller, so the text
/// below can fade in on the same timeline. The float starts when [intro]
/// completes, and only when [animate] is true (it is false with Reduce
/// Motion).
class AnimatedWallet extends StatefulWidget {
  const AnimatedWallet({
    super.key,
    required this.intro,
    required this.animate,
    this.size = 220,
  });

  final Animation<double> intro;
  final bool animate;
  final double size;

  @override
  State<AnimatedWallet> createState() => _AnimatedWalletState();
}

/// One coin layer: the asset and where its coin sits, as a fraction of the
/// image (used as the centre for its pop).
class _Coin {
  const _Coin(this.asset, this.x, this.y);

  final String asset;
  final double x;
  final double y;
}

/// Coin layers in pop order: nearest the wallet first, the top coin last.
/// Each layer is full-size, so stacked together they recreate the artwork.
const _coins = [
  _Coin('assets/images/login/coin_1.png', 0.484, 0.375),
  _Coin('assets/images/login/coin_2.png', 0.266, 0.338),
  _Coin('assets/images/login/coin_3.png', 0.698, 0.359),
  _Coin('assets/images/login/coin_4.png', 0.571, 0.323),
  _Coin('assets/images/login/coin_5.png', 0.380, 0.292),
  _Coin('assets/images/login/coin_6.png', 0.659, 0.240),
  _Coin('assets/images/login/coin_7.png', 0.328, 0.193),
  _Coin('assets/images/login/coin_8.png', 0.500, 0.229),
  _Coin('assets/images/login/coin_9.png', 0.484, 0.120),
];

const _walletAsset = 'assets/images/login/wallet.png';

class _AnimatedWalletState extends State<AnimatedWallet>
    with SingleTickerProviderStateMixin {
  /// One float cycle (up and back down) takes twice this.
  static const _floatHalfCycle = Duration(milliseconds: 1750);

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: _floatHalfCycle,
  );

  late final Animation<double> _walletIn = CurvedAnimation(
    parent: widget.intro,
    curve: const Interval(0, 0.3, curve: Curves.easeOutCubic),
  );

  late final List<Animation<double>> _coinPops = [
    for (var i = 0; i < _coins.length; i++)
      CurvedAnimation(
        parent: widget.intro,
        curve: Interval(
          0.25 + i * 0.055,
          0.40 + i * 0.055,
          curve: Curves.easeOutBack,
        ),
      ),
  ];

  late final Animation<double> _bounce = CurvedAnimation(
    parent: widget.intro,
    curve: const Interval(0.86, 1),
  );

  @override
  void initState() {
    super.initState();
    widget.intro.addStatusListener(_startFloat);
    _startFloat(widget.intro.status);
  }

  void _startFloat(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.animate) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedWallet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) {
      _float
        ..stop()
        ..value = 0;
    } else {
      _startFloat(widget.intro.status);
    }
  }

  @override
  void dispose() {
    widget.intro.removeStatusListener(_startFloat);
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.size / 100;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.intro, _float]),
        builder: (context, _) {
          final floatOffset =
              -Curves.easeInOut.transform(_float.value) * 2.5 * unit;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Stack(
              children: [
                for (var i = 0; i < _coins.length; i++) _coin(i, unit),
                _wallet(unit),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _wallet(double unit) {
    final t = _walletIn.value;
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 14 * unit),
        child: _layer(_walletAsset),
      ),
    );
  }

  Widget _coin(int index, double unit) {
    final coin = _coins[index];
    final t = _coinPops[index].value;
    // Small moves keep each layer close to its final place, so the cut edges
    // between overlapping coins never show. easeOutBack overshoots past 1;
    // that overshoot is the "pop".
    final rise = (1 - t) * 4 * unit;
    var scale = 0.85 + 0.15 * t;
    if (index == _coins.length - 1) {
      // The top coin's bounce is a brief swell: growing only covers more, so
      // nothing behind it is uncovered.
      scale += math.sin(_bounce.value * math.pi) * 0.08;
    }
    return Opacity(
      opacity: t.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, rise),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment(coin.x * 2 - 1, coin.y * 2 - 1),
          child: _layer(coin.asset),
        ),
      ),
    );
  }

  Widget _layer(String asset) => Image.asset(
    asset,
    width: widget.size,
    height: widget.size,
    // Decorative: the "Fundly" title below names the app.
    excludeFromSemantics: true,
  );
}
