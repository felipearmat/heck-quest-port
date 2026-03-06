#include "GlobalNamespace/BeatmapCallbacksController.hpp"
#include "GlobalNamespace/BeatmapObjectSpawnController.hpp"
#include "GlobalNamespace/StaticBeatmapObjectSpawnMovementData.hpp"
#include "GlobalNamespace/BeatmapObjectSpawnMovementData.hpp"
#include "custom-json-data/shared/CustomBeatmapData.h"
#include "tracks/shared/Animation/PointDefinition.h"
#include "Animation/AnimationHelper.h"
#include "AssociatedData.h"
#include "NELogger.h"
#include "NECaches.h"

using namespace AnimationHelper;
using namespace GlobalNamespace;
using namespace NEVector;
using namespace CustomJSONData;
using namespace Animation;

// BeatmapObjectCallbackController.cpp
extern BeatmapCallbacksController* callbackController;

// Events.cpp
extern BeatmapObjectSpawnController* spawnController;

constexpr std::optional<Vector3> operator+(std::optional<Vector3> const& a, std::optional<Vector3> const& b) {
  if (a && b) {
    return *a + *b;
  }
  if (a) {
    return a;
  }

  if (b) {
    return b;
  }

  return std::nullopt;
}

template <typename T> constexpr std::optional<T> operator*(std::optional<T> const& a, std::optional<T> const& b) {
  if (a && b) {
    return *a * *b;
  }
  if (a) {
    return a;
  }
  if (b) {
    return b;
  }
  return std::nullopt;
}

std::optional<NEVector::Vector3> AnimationHelper::GetDefinitePositionOffset(AnimationObjectData const& animationData,
                                                                            std::span<TrackW const> tracks,
                                                                            float time) {
  auto const& localDefinitePosition = animationData.definitePosition;

  std::optional<Vector3> pathDefinitePosition =
      localDefinitePosition ? std::optional(localDefinitePosition.InterpolateVec3(time)) : std::nullopt;

  // track animation only
  if (!pathDefinitePosition && !tracks.empty()) {
    if (tracks.size() == 1) {
      auto track = tracks.front();
      bool dummy = false;
      auto defPosProp = track.GetPathPropertyNamed(PropertyNames::DefinitePosition);
      if (defPosProp) pathDefinitePosition = defPosProp.InterpolateVec3(time, dummy);
    } else {
      auto positions = Animation::getPathPropertiesVec3(tracks, PropertyNames::DefinitePosition, time);
      pathDefinitePosition = Animation::addVector3s(positions);
    }
  }

  if (!pathDefinitePosition) return std::nullopt;

  auto const& position = animationData.position;
  std::optional<Vector3> pathPosition = position ? std::optional(position.InterpolateVec3(time)) : std::nullopt;
  std::optional<Vector3> trackPosition;

  std::optional<Vector3> positionOffset;

  if (!tracks.empty()) {
    if (tracks.size() == 1) {
      auto track = tracks.front();

      if (!pathPosition) {
        auto pathProp = track.GetPathPropertyNamed(PropertyNames::Position);
        bool dummy = false;
        if (pathProp) pathPosition = pathProp.InterpolateVec3(time, dummy);
      }

      trackPosition = track.GetPropertyNamed(PropertyNames::Position).GetVec3();
    } else {
      trackPosition =
          Animation::addVector3s(Animation::getPropertiesVec3(tracks, PropertyNames::Position, TimeUnit()));

      if (!pathPosition)
        pathPosition =
            Animation::addVector3s(Animation::getPathPropertiesVec3(tracks, PropertyNames::Position, time));
    }

    positionOffset = pathPosition + trackPosition;
  } else {
    positionOffset = pathPosition;
  }

  std::optional<Vector3> definitePosition = positionOffset + pathDefinitePosition;

  if (definitePosition) {
    definitePosition =
        definitePosition.value() * GlobalNamespace::StaticBeatmapObjectSpawnMovementData::kNoteLinesDistance;
  }

  if (NECaches::LeftHandedMode) {
    definitePosition = Animation::MirrorVectorNullable(definitePosition);
  }

  return definitePosition;
}

ObjectOffset AnimationHelper::GetObjectOffset(AnimationObjectData const& animationData, std::span<TrackW const> tracks,
                                              float time) {
  ObjectOffset offset;

  auto const& position = animationData.position;
  auto const& rotation = animationData.rotation;
  auto const& scale = animationData.scale;
  auto const& localRotation = animationData.localRotation;
  auto const& dissolve = animationData.dissolve;
  auto const& dissolveArrow = animationData.dissolveArrow;
  auto const& cuttable = animationData.cuttable;

  // Get path properties from animation data
  std::optional<Vector3> pathPosition = position ? std::optional(position.InterpolateVec3(time)) : std::nullopt;
  std::optional<Quaternion> pathRotation =
      rotation ? std::optional(rotation.InterpolateQuaternion(time)) : std::nullopt;
  std::optional<Vector3> pathScale = scale ? std::optional(scale.InterpolateVec3(time)) : std::nullopt;
  std::optional<Quaternion> pathLocalRotation =
      localRotation ? std::optional(localRotation.InterpolateQuaternion(time)) : std::nullopt;
  std::optional<float> pathDissolve = dissolve ? std::optional(dissolve.InterpolateLinear(time)) : std::nullopt;
  std::optional<float> pathDissolveArrow =
      dissolveArrow ? std::optional(dissolveArrow.InterpolateLinear(time)) : std::nullopt;
  std::optional<float> pathCuttable = cuttable ? std::optional(cuttable.InterpolateLinear(time)) : std::nullopt;

  if (!tracks.empty()) {
    if (tracks.size() == 1) {
      auto const track = tracks.front();

      // Fetch path properties individually (tracks 2.4.3 has no GetPathPropertiesValuesW)
      bool dummy = false;
      auto pathPropPos = track.GetPathPropertyNamed(PropertyNames::Position);
      auto pathPropRot = track.GetPathPropertyNamed(PropertyNames::Rotation);
      auto pathPropScale = track.GetPathPropertyNamed(PropertyNames::Scale);
      auto pathPropLocalRot = track.GetPathPropertyNamed(PropertyNames::LocalRotation);
      auto pathPropDissolve = track.GetPathPropertyNamed(PropertyNames::Dissolve);
      auto pathPropDissolveArrow = track.GetPathPropertyNamed(PropertyNames::DissolveArrow);
      auto pathPropCuttable = track.GetPathPropertyNamed(PropertyNames::Cuttable);

      if (!pathPosition && pathPropPos) pathPosition = pathPropPos.InterpolateVec3(time, dummy);
      if (!pathRotation && pathPropRot) pathRotation = pathPropRot.InterpolateQuat(time, dummy);
      if (!pathScale && pathPropScale) pathScale = pathPropScale.InterpolateVec3(time, dummy);
      if (!pathLocalRotation && pathPropLocalRot) pathLocalRotation = pathPropLocalRot.InterpolateQuat(time, dummy);
      if (!pathDissolve && pathPropDissolve) pathDissolve = pathPropDissolve.InterpolateLinear(time, dummy);
      if (!pathDissolveArrow && pathPropDissolveArrow) pathDissolveArrow = pathPropDissolveArrow.InterpolateLinear(time, dummy);
      if (!pathCuttable && pathPropCuttable) pathCuttable = pathPropCuttable.InterpolateLinear(time, dummy);

      // Fetch instant properties (tracks 2.4.3 has no GetPropertiesValuesW)
      auto propPos = track.GetPropertyNamed(PropertyNames::Position);
      auto propRot = track.GetPropertyNamed(PropertyNames::Rotation);
      auto propScale = track.GetPropertyNamed(PropertyNames::Scale);
      auto propLocalRot = track.GetPropertyNamed(PropertyNames::LocalRotation);
      auto propDissolve = track.GetPropertyNamed(PropertyNames::Dissolve);
      auto propDissolveArrow = track.GetPropertyNamed(PropertyNames::DissolveArrow);
      auto propCuttable = track.GetPropertyNamed(PropertyNames::Cuttable);

      // Combine with track properties
      offset.positionOffset = pathPosition + propPos.GetVec3();
      offset.rotationOffset = pathRotation * propRot.GetQuat();
      offset.scaleOffset = pathScale * propScale.GetVec3();
      offset.localRotationOffset = pathLocalRotation * propLocalRot.GetQuat();
      offset.dissolve = pathDissolve * propDissolve.GetFloat();
      offset.dissolveArrow = pathDissolveArrow * propDissolveArrow.GetFloat();
      offset.cuttable = pathCuttable * propCuttable.GetFloat();
    } else {
      // Multiple tracks - combine their properties
      if (!pathPosition) {
        auto positionPaths = Animation::getPathPropertiesVec3(tracks, PropertyNames::Position, time);
        pathPosition = Animation::addVector3s(positionPaths);
      }
      if (!pathRotation) {
        auto rotationPaths = Animation::getPathPropertiesQuat(tracks, PropertyNames::Rotation, time);
        pathRotation = Animation::multiplyQuaternions(rotationPaths);
      }
      if (!pathScale) {
        auto scalePaths = Animation::getPathPropertiesVec3(tracks, PropertyNames::Scale, time);
        pathScale = Animation::multiplyVector3s(scalePaths);
      }
      if (!pathLocalRotation) {
        auto localRotationPaths = Animation::getPathPropertiesQuat(tracks, PropertyNames::LocalRotation, time);
        pathLocalRotation = Animation::multiplyQuaternions(localRotationPaths);
      }
      if (!pathDissolve) {
        auto dissolvePaths = Animation::getPathPropertiesFloat(tracks, PropertyNames::Dissolve, time);
        pathDissolve = Animation::multiplyFloats(dissolvePaths);
      }
      if (!pathDissolveArrow) {
        auto dissolveArrowPaths = Animation::getPathPropertiesFloat(tracks, PropertyNames::DissolveArrow, time);
        pathDissolveArrow = Animation::multiplyFloats(dissolveArrowPaths);
      }
      if (!pathCuttable) {
        auto cuttablePaths = Animation::getPathPropertiesFloat(tracks, PropertyNames::Cuttable, time);
        pathCuttable = Animation::multiplyFloats(cuttablePaths);
      }


      // Combine track properties with path properties
      auto trackPositions =
          Animation::getPropertiesVec3(tracks, PropertyNames::Position, {});
      auto trackRotations = Animation::getPropertiesQuat(tracks, PropertyNames::Rotation, {});
      auto trackScales = Animation::getPropertiesVec3(tracks, PropertyNames::Scale, {});
      auto trackLocalRotations = Animation::getPropertiesQuat(tracks, PropertyNames::LocalRotation, {});
      auto trackDissolves = Animation::getPropertiesFloat(tracks, PropertyNames::Dissolve, {});
      auto trackDissolveArrows = Animation::getPropertiesFloat(tracks, PropertyNames::DissolveArrow, {});
      auto trackCuttables = Animation::getPropertiesFloat(tracks, PropertyNames::Cuttable, {});

      // Calculate combined track values (as optionals: nullopt if no track had the property)
      auto toOptVec3 = [](std::vector<Vector3> const& v) -> std::optional<Vector3> {
        return v.empty() ? std::nullopt : std::optional(Animation::addVector3s(v));
      };
      auto toOptQuat = [](std::vector<Quaternion> const& v) -> std::optional<Quaternion> {
        return v.empty() ? std::nullopt : std::optional(Animation::multiplyQuaternions(v));
      };
      auto toOptFloat = [](std::vector<float> const& v) -> std::optional<float> {
        return v.empty() ? std::nullopt : std::optional(Animation::multiplyFloats(v));
      };

      auto combinedTrackPositions = toOptVec3(trackPositions);
      auto combinedTrackRotations = toOptQuat(trackRotations);
      auto combinedTrackScales = toOptVec3(trackScales);
      auto combinedTrackLocalRotations = toOptQuat(trackLocalRotations);
      auto combinedTrackDissolves = toOptFloat(trackDissolves);
      auto combinedTrackDissolveArrows = toOptFloat(trackDissolveArrows);
      auto combinedTrackCuttables = toOptFloat(trackCuttables);

      // Set final property values
      offset.positionOffset = pathPosition + combinedTrackPositions;
      offset.rotationOffset = pathRotation * combinedTrackRotations;
      offset.scaleOffset = pathScale * combinedTrackScales;
      offset.localRotationOffset = pathLocalRotation * combinedTrackLocalRotations;
      offset.dissolve = pathDissolve * combinedTrackDissolves;
      offset.dissolveArrow = pathDissolveArrow * combinedTrackDissolveArrows;
      offset.cuttable = pathCuttable * combinedTrackCuttables;
    }
  } else {
    // No tracks - use animation data only
    offset.positionOffset = pathPosition;
    offset.rotationOffset = pathRotation;
    offset.scaleOffset = pathScale;
    offset.localRotationOffset = pathLocalRotation;
    offset.dissolve = pathDissolve;
    offset.dissolveArrow = pathDissolveArrow;
    offset.cuttable = pathCuttable;
  }

  // Apply scale and mirroring
  if (offset.positionOffset)
    offset.positionOffset = offset.positionOffset.value() * StaticBeatmapObjectSpawnMovementData::kNoteLinesDistance;

  if (NECaches::LeftHandedMode) {
    offset.rotationOffset = Animation::MirrorQuaternionNullable(offset.rotationOffset);
    offset.localRotationOffset = Animation::MirrorQuaternionNullable(offset.localRotationOffset);
    offset.positionOffset = Animation::MirrorVectorNullable(offset.positionOffset);
    offset.scaleOffset = Animation::MirrorVectorNullable(offset.scaleOffset);
  }

  return offset;
}
