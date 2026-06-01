#ifndef FS2GDL90_PROTOCOL_UTILS_H
#define FS2GDL90_PROTOCOL_UTILS_H

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace fs2gdl90::protocol {

std::string SanitizeCallsign(std::string_view input);
bool IsValidIpv4Address(std::string_view input);

bool IsValidNic(uint8_t value);
bool IsValidNacp(uint8_t value);
bool IsValidEmitterCategory(uint8_t value);

bool HasValidOwnshipPosition(double latitude, double longitude);

} // namespace fs2gdl90::protocol

#endif // FS2GDL90_PROTOCOL_UTILS_H
