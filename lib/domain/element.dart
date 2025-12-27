/// The four primary elements in Spellforge.
/// Fire > Earth > Air > Water > Fire (cyclic effectiveness)
enum Element {
  fire,
  water,
  earth,
  air;

  /// Returns the element that this element is strong against.
  Element get strongAgainst {
    switch (this) {
      case Element.fire:
        return Element.earth;
      case Element.earth:
        return Element.air;
      case Element.air:
        return Element.water;
      case Element.water:
        return Element.fire;
    }
  }

  /// Returns the element that this element is weak against.
  Element get weakAgainst {
    switch (this) {
      case Element.fire:
        return Element.water;
      case Element.water:
        return Element.air;
      case Element.air:
        return Element.earth;
      case Element.earth:
        return Element.fire;
    }
  }

  /// Calculates the damage multiplier when this element attacks a target element.
  /// Strong: 1.5×, Weak: 0.75×, Neutral: 1.0×
  double getMultiplierAgainst(Element defender) {
    if (strongAgainst == defender) {
      return 1.5;
    } else if (weakAgainst == defender) {
      return 0.75;
    }
    return 1.0;
  }

  /// Returns a human-readable effectiveness description.
  String getEffectivenessText(Element defender) {
    if (strongAgainst == defender) {
      return 'Strong effectiveness (1.5×)';
    } else if (weakAgainst == defender) {
      return 'Weak effectiveness (0.75×)';
    }
    return 'Neutral effectiveness (1.0×)';
  }

  /// Display name with capitalization.
  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}
