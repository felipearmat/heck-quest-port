#pragma once

#include "Chroma.hpp"
#include "tracks/shared/AssociatedData.h"

#include "beatsaber-hook/shared/config/rapidjson-utils.hpp"
#include "sombrero/shared/Vector3Utils.hpp"
#include "sombrero/shared/QuaternionUtils.hpp"
#include "UnityEngine/Transform.hpp"
#include "UnityEngine/Quaternion.hpp"

#include <optional>
#include <string_view>
#include <cmath>

namespace {
// Unity uses degrees; convert euler (degrees) to quaternion (ZXY order).
inline UnityEngine::Quaternion EulerToQuaternion(float xDeg, float yDeg, float zDeg) {
  float const kDeg2Rad = 3.14159265358979323846f / 180.0f;
  float x = xDeg * kDeg2Rad * 0.5f;
  float y = yDeg * kDeg2Rad * 0.5f;
  float z = zDeg * kDeg2Rad * 0.5f;
  float cx = std::cos(x), sx = std::sin(x);
  float cy = std::cos(y), sy = std::sin(y);
  float cz = std::cos(z), sz = std::sin(z);
  return UnityEngine::Quaternion(
      sx * cy * cz - cx * sy * sz,
      cx * sy * cz + sx * cy * sz,
      cx * cy * sz - sx * sy * cz,
      cx * cy * cz + sx * sy * sz);
}
} // namespace

namespace Tracks {

// Local replacement for tracks/shared/Animation/TransformData.hpp when the
// tracks package does not provide it (e.g. tracks 2.4.x). Parses environment
// enhancement transform fields from JSON and applies them to a Unity Transform.
struct TransformData {
  std::optional<Sombrero::FastVector3> position;
  std::optional<Sombrero::FastVector3> localPosition;
  std::optional<Sombrero::FastVector3> rotation;     // Euler angles
  std::optional<Sombrero::FastVector3> localRotation; // Euler angles
  std::optional<Sombrero::FastVector3> scale;

  TransformData(rapidjson::Value const& data, bool v2) {
    auto getVec3 = [&](std::string_view name) -> std::optional<Sombrero::FastVector3> {
      auto it = data.FindMember(name.data());
      if (it == data.MemberEnd() || !it->value.IsArray() || it->value.Empty()) return std::nullopt;
      auto const& arr = it->value.GetArray();
      if (arr.Size() < 3) return std::nullopt;
      return Sombrero::FastVector3{ arr[0].GetFloat(), arr[1].GetFloat(), arr[2].GetFloat() };
    };
    namespace C = TracksAD::Constants;
    if (v2) {
      position = getVec3(C::V2_POSITION);
      localPosition = getVec3(C::V2_LOCAL_POSITION);
      rotation = getVec3(C::V2_ROTATION);
      localRotation = getVec3(C::V2_LOCAL_ROTATION);
      scale = getVec3(C::V2_SCALE);
    } else {
      position = getVec3(C::POSITION);
      localPosition = getVec3(C::LOCAL_POSITION);
      rotation = getVec3(C::ROTATION);
      localRotation = getVec3(C::LOCAL_ROTATION);
      scale = getVec3(C::SCALE);
    }
  }

  void Apply(UnityEngine::Transform* transform, bool leftHanded, bool v2) const {
    auto mirrorX = [leftHanded](Sombrero::FastVector3 const& v) {
      if (!leftHanded) return v;
      return Sombrero::FastVector3{ -v.x, v.y, v.z };
    };
    if (position) {
      transform->set_position(mirrorX(*position));
    }
    if (localPosition) {
      transform->set_localPosition(mirrorX(*localPosition));
    }
    if (rotation) {
      auto const& e = mirrorX(*rotation);
      transform->set_rotation(EulerToQuaternion(e.x, e.y, e.z));
    }
    if (localRotation) {
      auto const& e = mirrorX(*localRotation);
      transform->set_localRotation(EulerToQuaternion(e.x, e.y, e.z));
    }
    if (scale) {
      transform->set_localScale(*scale);
    }
  }
};

} // namespace Tracks
