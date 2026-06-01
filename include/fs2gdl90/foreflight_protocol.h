#ifndef FS2GDL90_FOREFLIGHT_PROTOCOL_H
#define FS2GDL90_FOREFLIGHT_PROTOCOL_H

#include <cstdint>
#include <vector>

namespace fs2gdl90::foreflight {

bool ParseDiscoveryBroadcast(const std::vector<uint8_t> &packet,
                             uint16_t *out_port);

} // namespace fs2gdl90::foreflight

#endif // FS2GDL90_FOREFLIGHT_PROTOCOL_H
