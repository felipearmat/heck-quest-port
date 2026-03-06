#pragma once

// Local replacement for tracks/shared/VariableMovementHelper.hpp (not present in tracks 2.4.x).
// Provides a simple wrapper that reads jumpDuration and moveDuration from any
// IVariableMovementDataProvider-compatible pointer on construction.

#include "GlobalNamespace/IVariableMovementDataProvider.hpp"

template <typename T>
struct VariableMovementWrapper {
  float jumpDuration;
  float moveDuration;

  explicit VariableMovementWrapper(T* provider) {
    if (provider) {
      jumpDuration = provider->get_jumpDuration();
      moveDuration = provider->get_moveDuration();
    } else {
      jumpDuration = 0.0f;
      moveDuration = 0.0f;
    }
  }
};

using VariableMovementW = VariableMovementWrapper<GlobalNamespace::IVariableMovementDataProvider>;
