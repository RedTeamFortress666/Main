Import("env")
import os

BUDGET = 256 * 1024


def after_build(source, target, env):
    firmware = str(target[0])
    if not os.path.isfile(firmware):
        print("Phant0m size_check: firmware missing:", firmware)
        return
    size = os.path.getsize(firmware)
    name = env["PIOENV"]
    cpp = env.subst("$CPPDEFINES")
    strict = ("PHANT0M_STRICT_SIZE", 1) in env.get("CPPDEFINES", []) or name == "solar"
    # CPPDEFINES entries can be tuples or strings depending on SCons version
    if not strict:
        for d in env.get("CPPDEFINES", []):
            if d == "PHANT0M_STRICT_SIZE=1" or d == ("PHANT0M_STRICT_SIZE", 1) or d == ("PHANT0M_STRICT_SIZE", "1"):
                strict = True
                break
            if isinstance(d, str) and "PHANT0M_STRICT_SIZE=1" in d:
                strict = True
                break
    if name == "solar":
        strict = True
    print("Phant0m image: %s = %d bytes (%.1f KiB)" % (name, size, size / 1024.0))
    if strict:
        if size > BUDGET:
            print("ERROR: %s exceeds 256 KiB budget (%d > %d)" % (name, size, BUDGET))
            env.Exit(1)
        print("OK: within 256 KiB budget (%d free)" % (BUDGET - size))
    else:
        print("NOTE: non-strict env (native WiFi/BLE stacks exceed 256 KiB)")


env.AddPostAction("$BUILD_DIR/${PROGNAME}.bin", after_build)
