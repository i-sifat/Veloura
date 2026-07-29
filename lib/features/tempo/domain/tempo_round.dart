import 'package:veloura/features/tempo/domain/tempo_stage.dart';

/// The closed, content-free 90-second pacing round.
const kDefaultRound = <TempoStage>[
  TempoStage(bpm: 60, length: Duration(seconds: 30), label: 'SLOW'),
  TempoStage(bpm: 92, length: Duration(seconds: 30), label: 'BUILD'),
  TempoStage(bpm: 128, length: Duration(seconds: 30), label: 'FASTER'),
];

/// Brief focus prompts shown at the start of each stage.
const kTempoFocusWords = <String>[
  'HANDS',
  'LIPS',
  'NECK',
  'SLOWER',
  'CLOSER',
  'EYES',
];

const kTempoFinaleLength = Duration(seconds: 3);
const kTempoFocusLength = Duration(seconds: 6);
