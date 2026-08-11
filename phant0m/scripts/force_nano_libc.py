Import("env")

# Placeholder hook: full newlib-nano conflicts with Espressif libnewlib locks.
# Flash reduction uses src/stubs/min_printf.c + bt_release_stub.c instead.
print("Phant0m: size stubs active (min_printf, bt_release)")
