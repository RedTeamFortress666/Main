/* Arduino esp32-hal-misc calls esp_bt_controller_mem_release() at boot.
 * Providing this symbol prevents the linker from pulling libbt + libbtdm_app
 * (~100 KiB) into size-constrained solar builds that do not use Bluetooth. */

#include <stdint.h>

typedef int esp_err_t;
typedef int esp_bt_mode_t;

#define ESP_OK 0

esp_err_t esp_bt_controller_mem_release(esp_bt_mode_t mode) {
  (void)mode;
  return ESP_OK;
}
