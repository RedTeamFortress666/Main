#pragma once

#include <phant0m_types.h>

namespace phant0m {
namespace tinyml {

// Ultra-light logistic model (no TFLite) — fits flash budget.
void begin();
RogueVerdict score(const ApFeature *aps, uint8_t count);
void extract_from_scan(ApFeature *out, uint8_t *count, uint8_t max_count);
void ingest_records(ApFeature *out, uint8_t *count, const ApFeature *in,
                    uint8_t in_count, uint8_t max_count);

}  // namespace tinyml
}  // namespace phant0m
