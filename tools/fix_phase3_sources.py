#!/usr/bin/env python3
from pathlib import Path

path = Path('lib/features/truth_dare/presentation/truth_dare_screen.dart')
text = path.read_text()
text = text.replace("import 'dart:math' as math;\n\n", '')
path.write_text(text)
