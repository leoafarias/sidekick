import 'package:flutter/material.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../atoms/typography.dart';

// TODO: Make this generic
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 80,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepOrange.withAlpha((255 * 0.1).round()),
            border: Border.all(
              color: Colors.deepOrange,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Subheading(context.i18n('components:molecules.master')),
              const SizedBox(width: 20),
              Expanded(
                child: Caption(context.i18n(
                    'modules:releases.theCurrentTipoftreeAbsoluteLatestCuttingEdgeBuildUsuallyFunctional')),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
