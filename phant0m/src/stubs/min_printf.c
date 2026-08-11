/* Tiny integer-only printf stand-ins.
 * Linked as .o so the full newlib vfprintf/dtoa (~40 KiB) are never pulled. */

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/reent.h>
#include <unistd.h>

typedef struct _reent *rptr;

static int put_buf(char *dst, size_t dst_sz, size_t *pos, char c) {
  if (dst) {
    if (*pos + 1 < dst_sz) dst[*pos] = c;
  } else {
    const char ch = c;
    write(1, &ch, 1);
  }
  (*pos)++;
  return 1;
}

static int put_str(char *dst, size_t dst_sz, size_t *pos, const char *s) {
  int n = 0;
  if (!s) s = "(null)";
  while (*s) {
    put_buf(dst, dst_sz, pos, *s++);
    n++;
  }
  return n;
}

static int put_uint(char *dst, size_t dst_sz, size_t *pos, unsigned long v,
                    int base, int upper) {
  char tmp[32];
  const char *digits = upper ? "0123456789ABCDEF" : "0123456789abcdef";
  int i = 0;
  if (v == 0) tmp[i++] = '0';
  while (v && i < (int)sizeof(tmp)) {
    tmp[i++] = digits[v % (unsigned)base];
    v /= (unsigned)base;
  }
  int n = 0;
  while (i--) {
    put_buf(dst, dst_sz, pos, tmp[i]);
    n++;
  }
  return n;
}

static int format(char *dst, size_t dst_sz, const char *fmt, va_list ap) {
  size_t pos = 0;
  int out = 0;
  while (*fmt) {
    if (*fmt != '%') {
      put_buf(dst, dst_sz, &pos, *fmt++);
      out++;
      continue;
    }
    ++fmt;
    if (*fmt == '%') {
      put_buf(dst, dst_sz, &pos, '%');
      out++;
      fmt++;
      continue;
    }
    int long_mod = 0;
    if (*fmt == 'l') {
      long_mod = 1;
      fmt++;
    }
    switch (*fmt++) {
      case 's':
        out += put_str(dst, dst_sz, &pos, va_arg(ap, const char *));
        break;
      case 'c':
        put_buf(dst, dst_sz, &pos, (char)va_arg(ap, int));
        out++;
        break;
      case 'd':
      case 'i': {
        long v = long_mod ? va_arg(ap, long) : va_arg(ap, int);
        if (v < 0) {
          put_buf(dst, dst_sz, &pos, '-');
          out++;
          v = -v;
        }
        out += put_uint(dst, dst_sz, &pos, (unsigned long)v, 10, 0);
        break;
      }
      case 'u': {
        unsigned long v =
            long_mod ? va_arg(ap, unsigned long) : va_arg(ap, unsigned);
        out += put_uint(dst, dst_sz, &pos, v, 10, 0);
        break;
      }
      case 'x': {
        unsigned long v =
            long_mod ? va_arg(ap, unsigned long) : va_arg(ap, unsigned);
        out += put_uint(dst, dst_sz, &pos, v, 16, 0);
        break;
      }
      case 'X': {
        unsigned long v =
            long_mod ? va_arg(ap, unsigned long) : va_arg(ap, unsigned);
        out += put_uint(dst, dst_sz, &pos, v, 16, 1);
        break;
      }
      case 'p': {
        put_str(dst, dst_sz, &pos, "0x");
        out += 2;
        out += put_uint(dst, dst_sz, &pos, (unsigned long)va_arg(ap, void *),
                        16, 0);
        break;
      }
      case 'f':
      case 'g':
      case 'e':
        (void)va_arg(ap, double);
        out += put_str(dst, dst_sz, &pos, "0");
        break;
      default:
        break;
    }
  }
  if (dst && dst_sz) {
    size_t term = pos < dst_sz ? pos : dst_sz - 1;
    dst[term] = 0;
  }
  return out;
}

int vsnprintf(char *dst, size_t n, const char *fmt, va_list ap) {
  return format(dst, n, fmt, ap);
}
int vsprintf(char *dst, const char *fmt, va_list ap) {
  return format(dst, (size_t)-1, fmt, ap);
}
int snprintf(char *dst, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = format(dst, n, fmt, ap);
  va_end(ap);
  return r;
}
int sprintf(char *dst, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = format(dst, (size_t)-1, fmt, ap);
  va_end(ap);
  return r;
}
int vprintf(const char *fmt, va_list ap) { return format(NULL, 0, fmt, ap); }
int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = format(NULL, 0, fmt, ap);
  va_end(ap);
  return r;
}

int _vsnprintf_r(rptr r, char *dst, size_t n, const char *fmt, va_list ap) {
  (void)r;
  return format(dst, n, fmt, ap);
}
int _vfprintf_r(rptr r, FILE *fp, const char *fmt, va_list ap) {
  (void)r;
  (void)fp;
  return format(NULL, 0, fmt, ap);
}
int _svfprintf_r(rptr r, FILE *fp, const char *fmt, va_list ap) {
  return _vfprintf_r(r, fp, fmt, ap);
}
int _vfiprintf_r(rptr r, FILE *fp, const char *fmt, va_list ap) {
  return _vfprintf_r(r, fp, fmt, ap);
}
int _svfiprintf_r(rptr r, FILE *fp, const char *fmt, va_list ap) {
  return _vfprintf_r(r, fp, fmt, ap);
}
int _fprintf_r(rptr r, FILE *fp, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int n = _vfprintf_r(r, fp, fmt, ap);
  va_end(ap);
  return n;
}
int fprintf(FILE *fp, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int n = _vfprintf_r(_REENT, fp, fmt, ap);
  va_end(ap);
  return n;
}

/* Block dtoa pull if anything still references it. */
char *_dtoa_r(rptr r, double d, int mode, int ndigits, int *decpt, int *sign,
              char **rve) {
  (void)r;
  (void)d;
  (void)mode;
  (void)ndigits;
  static char z[] = "0";
  if (decpt) *decpt = 1;
  if (sign) *sign = 0;
  if (rve) *rve = z + 1;
  return z;
}
