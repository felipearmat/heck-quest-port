#pragma once

#include "Animation/NoodleMovementDataProvider.hpp"
#include "tracks/shared/Vector.h"

// Local replacement for tracks/shared/VariableMovementHelper.hpp (not present in tracks 2.4.3).
// Eagerly copies all IVariableMovementDataProvider properties for easy access.
template <typename T>
struct VariableMovementWrapper {
  T* provider;
  bool wasUpdatedThisFrame;
  float jumpDuration;
  float halfJumpDuration;
  float moveDuration;
  NEVector::Vector3 moveStartPosition;
  NEVector::Vector3 moveEndPosition;
  NEVector::Vector3 jumpEndPosition;

  VariableMovementWrapper(T* p) : provider(p) {
    if (p) {
      wasUpdatedThisFrame = p->get_wasUpdatedThisFrame();
      jumpDuration = p->get_jumpDuration();
      halfJumpDuration = p->get_halfJumpDuration();
      moveDuration = p->get_moveDuration();
      moveStartPosition = p->get_moveStartPosition();
      moveEndPosition = p->get_moveEndPosition();
      jumpEndPosition = p->get_jumpEndPosition();
    } else {
      wasUpdatedThisFrame = false;
      jumpDuration = 0.0f;
      halfJumpDuration = 0.0f;
      moveDuration = 0.0f;
      moveStartPosition = NEVector::Vector3::zero();
      moveEndPosition = NEVector::Vector3::zero();
      jumpEndPosition = NEVector::Vector3::zero();
    }
  }

  float CalculateCurrentNoteJumpGravity(float gravityBase) const {
    if (provider) return provider->CalculateCurrentNoteJumpGravity(gravityBase);
    return 0.0f;
  }
};

// Use IVariableMovementDataProvider so callers can pass any compatible pointer
using VariableMovementW = VariableMovementWrapper<GlobalNamespace::IVariableMovementDataProvider>;
