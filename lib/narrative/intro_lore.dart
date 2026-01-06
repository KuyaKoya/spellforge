import 'package:flutter/foundation.dart';
import 'narrative_node.dart';

/// Contains the intro lore sequence shown on first game launch.
class IntroLore {
  IntroLore._();

  /// The complete intro lore sequence (6 screens).
  static NarrativeNode getIntroSequence({VoidCallback? onComplete}) {
    return NarrativeNode.worldNarration(
      id: 'intro_lore',
      pages: [
        // Screen 1 – Arrival
        '''You awaken not by chance,
but by invitation.

A world unfolds before you —
forged, fractured, and waiting.''',

        // Screen 2 – Exodia
        '''This place is called Exodia.

A realm shaped by spellcraft,
where fire, water, earth, and air
define both survival and failure.''',

        // Screen 3 – The Loop
        '''Many have stood where you stand now.

They fought.
They fell.

And when they fell,
they fought again.''',

        // Screen 4 – The Watcher
        '''There is something here that watches.

It does not rule.
It does not save.

It observes.
It measures.
It waits.''',

        // Screen 5 – The Myth
        '''There is a myth whispered between failures:

That mastery of all paths
may break the cycle.

None have proven it true.''',

        // Screen 6 – The Question
        '''And now you are here.

Another variable in a perfect loop.

Is there truly an end to this?''',
      ],
      onComplete: onComplete,
    );
  }
}
