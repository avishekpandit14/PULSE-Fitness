#!/usr/bin/env node
/**
 * Generates the PULSE launcher icons from vector-ish drawing code so the
 * assets are reproducible instead of hand-edited bitmaps.
 *
 * Palette comes from lib/core/constants/app_colors.dart:
 *   electric lime #D4FF00 on a near-black #090A0D background.
 *
 * Output:
 *   mipmap-*\/ic_launcher.png            legacy square icon
 *   mipmap-*\/ic_launcher_foreground.png adaptive foreground (safe zone)
 *
 * Usage: node tool/generate_app_icons.js
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const RES = path.join(__dirname, '..', 'android', 'app', 'src', 'main', 'res');

const LIME = [0xd4, 0xff, 0x00];
const BG_TOP = [0x17, 0x1b, 0x22];
const BG_BOTTOM = [0x0a, 0x0c, 0x11];

const SS = 4; // supersampling factor for anti-aliasing

const DENSITIES = [
  ['mdpi', 1],
  ['hdpi', 1.5],
  ['xhdpi', 2],
  ['xxhdpi', 3],
  ['xxxhdpi', 4],
];

// --- PNG encoding ---------------------------------------------------------

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) {
    c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ -1) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, crc]);
}

function encodePng(width, height, rgba) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const stride = width * 4;
  const raw = Buffer.alloc((stride + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (stride + 1)] = 0; // filter: none
    rgba.copy(raw, y * (stride + 1) + 1, y * stride, y * stride + stride);
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// --- geometry -------------------------------------------------------------

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/** Anti-aliased coverage of a rounded rectangle covering the whole canvas. */
function roundedRectCoverage(x, y, size, radius) {
  const cx = Math.abs(x - size / 2) - (size / 2 - radius);
  const cy = Math.abs(y - size / 2) - (size / 2 - radius);
  const dx = Math.max(cx, 0);
  const dy = Math.max(cy, 0);
  const d =
    Math.sqrt(dx * dx + dy * dy) + Math.min(Math.max(cx, cy), 0) - radius;
  return clamp01(0.5 - d);
}

function segmentDistance(px, py, ax, ay, bx, by) {
  const vx = bx - ax;
  const vy = by - ay;
  const wx = px - ax;
  const wy = py - ay;
  const len2 = vx * vx + vy * vy;
  const t =
    len2 <= 0 ? 0 : Math.max(0, Math.min(1, (wx * vx + wy * vy) / len2));
  const dx = px - (ax + vx * t);
  const dy = py - (ay + vy * t);
  return Math.sqrt(dx * dx + dy * dy);
}

/** Heartbeat glyph in normalised (0..1) content coordinates. */
const PULSE = [
  [0.06, 0.5],
  [0.3, 0.5],
  [0.38, 0.41],
  [0.46, 0.72],
  [0.55, 0.27],
  [0.64, 0.5],
  [0.94, 0.5],
];

function distanceToPulse(x, y, box) {
  let best = Infinity;
  for (let i = 0; i < PULSE.length - 1; i++) {
    const [ax, ay] = PULSE[i];
    const [bx, by] = PULSE[i + 1];
    const d = segmentDistance(
      x,
      y,
      box.x + ax * box.w,
      box.y + ay * box.h,
      box.x + bx * box.w,
      box.y + by * box.h,
    );
    if (d < best) best = d;
  }
  return best;
}

// --- rendering ------------------------------------------------------------

const blend = (dst, i, r, g, b, a) => {
  if (a <= 0) return;
  const da = dst[i + 3];
  const outA = a + da * (1 - a);
  if (outA <= 0) return;
  dst[i] = (r * a + dst[i] * da * (1 - a)) / outA;
  dst[i + 1] = (g * a + dst[i + 1] * da * (1 - a)) / outA;
  dst[i + 2] = (b * a + dst[i + 2] * da * (1 - a)) / outA;
  dst[i + 3] = outA;
};

/**
 * @param {number} size output pixel size
 * @param {'legacy'|'adaptive'} mode
 */
function render(size, mode) {
  const S = Math.round(size * SS);
  const buf = new Float64Array(S * S * 4); // straight alpha accumulation

  const radius = mode === 'legacy' ? S * 0.235 : 0;
  const inset = S * (mode === 'legacy' ? 0.14 : 0.22);
  const box = {
    x: inset,
    y: S * 0.5 - (S - 2 * inset) * 0.5,
    w: S - 2 * inset,
    h: S - 2 * inset,
  };
  const halfStroke = box.w * 0.043;

  for (let y = 0; y < S; y++) {
    for (let x = 0; x < S; x++) {
      const i = (y * S + x) * 4;
      const px = x + 0.5;
      const py = y + 0.5;

      // 1. background: rounded square with a soft vertical gradient
      if (mode === 'legacy') {
        const cover = roundedRectCoverage(px, py, S, radius);
        const t = py / S;
        blend(
          buf,
          i,
          (BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t) / 255,
          (BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t) / 255,
          (BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t) / 255,
          cover,
        );
      }

      // 2. lime glow behind the glyph, lifts it off dark launchers. The
      // adaptive foreground sits on a solid brand colour instead, so it only
      // needs a whisper of glow.
      const dx = (px - S / 2) / (S * 0.5);
      const dy = (py - S / 2) / (S * 0.5);
      const glow = clamp01(1 - Math.sqrt(dx * dx + dy * dy));
      const glowAlpha = mode === 'legacy' ? 0.1 : 0.03;
      blend(
        buf,
        i,
        LIME[0] / 255,
        LIME[1] / 255,
        LIME[2] / 255,
        glowAlpha * glow,
      );

      // 3. heartbeat stroke: soft halo, then the crisp line
      const d = distanceToPulse(px, py, box);
      const halo = clamp01(halfStroke * 1.9 - d + 1);
      blend(buf, i, LIME[0] / 255, LIME[1] / 255, LIME[2] / 255, 0.14 * halo);
      const ink = clamp01(halfStroke - d + 0.75);
      blend(buf, i, LIME[0] / 255, LIME[1] / 255, LIME[2] / 255, ink);
    }
  }

  // box filter down to the target size
  const out = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      let r = 0;
      let g = 0;
      let b = 0;
      let a = 0;
      for (let sy = 0; sy < SS; sy++) {
        for (let sx = 0; sx < SS; sx++) {
          const i = ((y * SS + sy) * S + (x * SS + sx)) * 4;
          const pa = buf[i + 3];
          r += buf[i] * pa;
          g += buf[i + 1] * pa;
          b += buf[i + 2] * pa;
          a += pa;
        }
      }
      const n = SS * SS;
      const o = (y * size + x) * 4;
      if (a > 0) {
        out[o] = Math.round((r / a) * 255);
        out[o + 1] = Math.round((g / a) * 255);
        out[o + 2] = Math.round((b / a) * 255);
      }
      out[o + 3] = Math.round((a / n) * 255);
    }
  }
  return out;
}

for (const [density, scale] of DENSITIES) {
  const dir = path.join(RES, `mipmap-${density}`);
  fs.mkdirSync(dir, { recursive: true });

  const legacySize = Math.round(48 * scale);
  fs.writeFileSync(
    path.join(dir, 'ic_launcher.png'),
    encodePng(legacySize, legacySize, render(legacySize, 'legacy')),
  );

  const foregroundSize = Math.round(108 * scale);
  fs.writeFileSync(
    path.join(dir, 'ic_launcher_foreground.png'),
    encodePng(
      foregroundSize,
      foregroundSize,
      render(foregroundSize, 'adaptive'),
    ),
  );

  console.log(
    `mipmap-${density}: ic_launcher ${legacySize}px, foreground ${foregroundSize}px`,
  );
}
