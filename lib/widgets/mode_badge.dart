import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';

String modeLabel(AlgorithmMode mode) {
  switch (mode) {
    case AlgorithmMode.batch: return 'Step-by-step';
    case AlgorithmMode.streaming: return 'Streaming';
    case AlgorithmMode.live: return 'Live';
    case AlgorithmMode.interactive: return 'Interactive';
  }
}

Color modeColor(AlgorithmMode mode, ColorScheme cs) {
  switch (mode) {
    case AlgorithmMode.batch: return cs.tertiaryContainer;
    case AlgorithmMode.streaming: return cs.primaryContainer;
    case AlgorithmMode.live: return cs.errorContainer;
    case AlgorithmMode.interactive: return cs.inversePrimary;
  }
}

Color modeTextColor(AlgorithmMode mode, ColorScheme cs) {
  switch (mode) {
    case AlgorithmMode.batch: return cs.onTertiaryContainer;
    case AlgorithmMode.streaming: return cs.onPrimaryContainer;
    case AlgorithmMode.live: return cs.onErrorContainer;
    case AlgorithmMode.interactive: return cs.inverseSurface;
  }
}
