const canvas = document.getElementById("previewCanvas");
const ctx = canvas.getContext("2d", { willReadFrequently: true });
const emptyState = document.getElementById("emptyState");
const compareBadge = document.getElementById("compareBadge");
const fileInput = document.getElementById("fileInput");
const cameraInput = document.getElementById("cameraInput");
const autoBtn = document.getElementById("autoBtn");
const compareBtn = document.getElementById("compareBtn");
const undoBtn = document.getElementById("undoBtn");
const redoBtn = document.getElementById("redoBtn");
const resetBtn = document.getElementById("resetBtn");
const saveBtn = document.getElementById("saveBtn");
const shareBtn = document.getElementById("shareBtn");
const presetStrip = document.getElementById("presetStrip");
const sliderList = document.getElementById("sliderList");
const dropZone = document.getElementById("dropZone");

const defaultSettings = {
  brightness: 0,
  contrast: 1,
  saturation: 1,
  shadows: 0,
  highlights: 0,
  warmth: 0,
  tint: 0,
  sharpness: 0,
  vignette: 0,
  grain: 0,
  blurBackground: 0,
  skinSmoothing: 0
};

const PREVIEW_MAX_DPR = 3;

const controls = [
  ["brightness", "Brightness", -1, 1, 0.01],
  ["contrast", "Contrast", 0.65, 1.65, 0.01],
  ["saturation", "Saturation", 0, 2, 0.01],
  ["shadows", "Shadows", -1, 1, 0.01],
  ["highlights", "Highlights", -1, 1, 0.01],
  ["warmth", "Warmth", -1, 1, 0.01],
  ["tint", "Tint", -1, 1, 0.01],
  ["sharpness", "Sharpness", 0, 1.5, 0.01],
  ["vignette", "Vignette", 0, 1, 0.01],
  ["grain", "Grain", 0, 1, 0.01],
  ["blurBackground", "Blur background", 0, 1, 0.01],
  ["skinSmoothing", "Skin smoothing", 0, 1, 0.01]
];

const presets = [
  ["Natural", "linear-gradient(145deg,#66c28f,#4aa6b7)", { brightness: 0.04, contrast: 1.08, saturation: 1.08, shadows: 0.18, highlights: -0.12, warmth: 0.08, sharpness: 0.28, vignette: 0.05 }],
  ["Portrait Pro", "linear-gradient(145deg,#ee8bb5,#c98a55)", { brightness: 0.1, contrast: 1.16, saturation: 1.08, shadows: 0.34, highlights: -0.22, warmth: 0.14, tint: 0.03, sharpness: 0.42, vignette: 0.1, blurBackground: 0.08, skinSmoothing: 0.38 }],
  ["Cinematic", "linear-gradient(145deg,#227e83,#07090c)", { brightness: 0, contrast: 1.3, saturation: 0.96, shadows: 0.16, highlights: -0.32, warmth: -0.1, tint: 0.08, sharpness: 0.48, vignette: 0.3, grain: 0.08, blurBackground: 0 }],
  ["Instagram Clean", "linear-gradient(145deg,#f5f5f1,#8fd5c4)", { brightness: 0.12, contrast: 1.12, saturation: 1.12, shadows: 0.26, highlights: -0.16, warmth: 0.06, sharpness: 0.24, vignette: 0.03, skinSmoothing: 0.16 }],
  ["Moody", "linear-gradient(145deg,#777,#050608)", { brightness: -0.1, contrast: 1.28, saturation: 0.82, shadows: -0.18, highlights: -0.22, warmth: -0.04, tint: 0.05, sharpness: 0.3, vignette: 0.45, grain: 0.18 }],
  ["Warm Film", "linear-gradient(145deg,#c9a246,#974d54)", { brightness: 0.05, contrast: 1.04, saturation: 0.96, shadows: 0.1, highlights: -0.2, warmth: 0.36, tint: 0.06, sharpness: 0.12, vignette: 0.18, grain: 0.22 }],
  ["Cold Urban", "linear-gradient(145deg,#527da6,#8c9399)", { brightness: -0.02, contrast: 1.2, saturation: 0.88, shadows: 0.02, highlights: -0.18, warmth: -0.34, tint: 0.04, sharpness: 0.42, vignette: 0.25, grain: 0.08 }],
  ["Black & White", "linear-gradient(145deg,#e8e8e8,#07090c)", { brightness: 0.02, contrast: 1.35, saturation: 0, shadows: 0.12, highlights: -0.18, sharpness: 0.5, vignette: 0.36, grain: 0.14 }],
  ["Luxury Look", "linear-gradient(145deg,#705d83,#c6a85a)", { brightness: 0.08, contrast: 1.28, saturation: 1.08, shadows: 0.22, highlights: -0.28, warmth: 0.18, tint: 0.08, sharpness: 0.5, vignette: 0.24, grain: 0.03, blurBackground: 0, skinSmoothing: 0.18 }],
  ["Soft Skin", "linear-gradient(145deg,#db9daf,#f0e7dc)", { brightness: 0.12, contrast: 1.08, saturation: 1.04, shadows: 0.28, highlights: -0.16, warmth: 0.12, tint: 0.04, sharpness: 0.18, vignette: 0.06, blurBackground: 0.04, skinSmoothing: 0.52 }]
];

let sourceImage = null;
let sourceBitmap = null;
let settings = { ...defaultSettings };
let history = [{ ...settings }];
let historyIndex = 0;
let exportQuality = 0.96;
let showingOriginal = false;

function clamp(value, min = 0, max = 255) {
  return Math.max(min, Math.min(max, value));
}

function commitHistory() {
  const latest = JSON.stringify(history[historyIndex]);
  const next = JSON.stringify(settings);
  if (latest === next) return;
  history = history.slice(0, historyIndex + 1);
  history.push({ ...settings });
  historyIndex = history.length - 1;
  updateHistoryButtons();
}

function updateHistoryButtons() {
  undoBtn.disabled = historyIndex === 0;
  redoBtn.disabled = historyIndex === history.length - 1;
}

function fitCanvasToStage() {
  const rect = dropZone.getBoundingClientRect();
  const dpr = Math.min(window.devicePixelRatio || 1, PREVIEW_MAX_DPR);
  canvas.width = Math.max(1, Math.round(rect.width * dpr));
  canvas.height = Math.max(1, Math.round(rect.height * dpr));
  ctx.imageSmoothingEnabled = true;
  ctx.imageSmoothingQuality = "high";
}

async function loadFile(file) {
  if (!file) return;
  sourceImage = await createImageBitmap(file, { imageOrientation: "from-image" });
  sourceBitmap = sourceImage;
  settings = { ...defaultSettings };
  history = [{ ...settings }];
  historyIndex = 0;
  emptyState.classList.add("hidden");
  compareBadge.classList.add("visible");
  updateSliders();
  updateHistoryButtons();
  render();
}

function drawSource(targetCtx, width, height) {
  if (!sourceBitmap) return null;
  const ratio = Math.min(width / sourceBitmap.width, height / sourceBitmap.height);
  const drawWidth = sourceBitmap.width * ratio;
  const drawHeight = sourceBitmap.height * ratio;
  const x = (width - drawWidth) / 2;
  const y = (height - drawHeight) / 2;
  targetCtx.clearRect(0, 0, width, height);
  targetCtx.fillStyle = "#000";
  targetCtx.fillRect(0, 0, width, height);
  targetCtx.imageSmoothingEnabled = true;
  targetCtx.imageSmoothingQuality = "high";
  targetCtx.drawImage(sourceBitmap, x, y, drawWidth, drawHeight);
  return { x, y, width: drawWidth, height: drawHeight };
}

function processPixels(imageData, bounds, activeSettings) {
  const data = imageData.data;
  const cx = bounds.x + bounds.width / 2;
  const cy = bounds.y + bounds.height / 2;
  const maxDist = Math.hypot(bounds.width / 2, bounds.height / 2);
  const brightness = activeSettings.brightness * 90;
  const contrast = activeSettings.contrast;
  const saturation = activeSettings.saturation;
  const shadowLift = activeSettings.shadows * 82;
  const highlightPull = activeSettings.highlights * 72;
  const warmth = activeSettings.warmth * 34;
  const tint = activeSettings.tint * 24;
  const vignette = activeSettings.vignette;
  const grain = activeSettings.grain;
  const skinSoft = activeSettings.skinSmoothing;

  for (let y = 0; y < imageData.height; y++) {
    for (let x = 0; x < imageData.width; x++) {
      const i = (y * imageData.width + x) * 4;
      if (data[i + 3] === 0) continue;

      let r = data[i];
      let g = data[i + 1];
      let b = data[i + 2];
      const lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      const shadowWeight = Math.max(0, 1 - lum / 150);
      const highlightWeight = Math.max(0, (lum - 145) / 110);

      r += brightness + shadowLift * shadowWeight + highlightPull * highlightWeight + warmth + tint * 0.25;
      g += brightness + shadowLift * shadowWeight + highlightPull * highlightWeight - tint * 0.18;
      b += brightness + shadowLift * shadowWeight + highlightPull * highlightWeight - warmth + tint;

      r = (r - 128) * contrast + 128;
      g = (g - 128) * contrast + 128;
      b = (b - 128) * contrast + 128;

      const gray = 0.299 * r + 0.587 * g + 0.114 * b;
      r = gray + (r - gray) * saturation;
      g = gray + (g - gray) * saturation;
      b = gray + (b - gray) * saturation;

      const cinematic = Math.max(0, contrast - 1) * 12;
      r += cinematic * 0.28;
      g += cinematic * 0.08;
      b -= cinematic * 0.16;

      if (skinSoft > 0) {
        const skinMask = r > 80 && g > 45 && b > 30 && r > b * 1.08 && r > g * 0.9;
        if (skinMask) {
          r = r * (1 - skinSoft * 0.055) + 240 * skinSoft * 0.055;
          g = g * (1 - skinSoft * 0.045) + 204 * skinSoft * 0.045;
          b = b * (1 - skinSoft * 0.035) + 184 * skinSoft * 0.035;
        }
      }

      if (vignette > 0) {
        const d = Math.hypot(x - cx, y - cy) / maxDist;
        const v = 1 - Math.max(0, d - 0.44) * vignette * 0.72;
        r *= v;
        g *= v;
        b *= v;
      }

      if (grain > 0) {
        const noise = (Math.random() - 0.5) * grain * 28;
        r += noise;
        g += noise;
        b += noise;
      }

      data[i] = clamp(r);
      data[i + 1] = clamp(g);
      data[i + 2] = clamp(b);
    }
  }
  return imageData;
}

function sharpen(targetCtx, bounds, amount) {
  if (amount <= 0.001) return;
  const imageData = targetCtx.getImageData(0, 0, canvas.width, canvas.height);
  const src = new Uint8ClampedArray(imageData.data);
  const data = imageData.data;
  const w = imageData.width;
  const intensity = Math.min(amount * 0.48, 0.72);
  for (let y = 1; y < imageData.height - 1; y++) {
    for (let x = 1; x < imageData.width - 1; x++) {
      const i = (y * w + x) * 4;
      if (src[i + 3] === 0) continue;
      for (let c = 0; c < 3; c++) {
        const value = src[i + c] * (1 + 4 * intensity)
          - src[i - 4 + c] * intensity
          - src[i + 4 + c] * intensity
          - src[i - w * 4 + c] * intensity
          - src[i + w * 4 + c] * intensity;
        data[i + c] = clamp(value);
      }
    }
  }
  targetCtx.putImageData(imageData, 0, 0);
}

function render(activeSettings = settings) {
  fitCanvasToStage();
  if (!sourceBitmap) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    return;
  }

  const bounds = drawSource(ctx, canvas.width, canvas.height);
  if (!bounds) return;

  if (showingOriginal) {
    compareBadge.textContent = "Before";
    return;
  }

  compareBadge.textContent = "After";
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
  ctx.putImageData(processPixels(imageData, bounds, activeSettings), 0, 0);
  sharpen(ctx, bounds, activeSettings.sharpness);

  applySoftEdgeBlur(activeSettings.blurBackground, bounds);
}

function autoEnhance() {
  if (!sourceBitmap) return;
  settings = {
    brightness: 0.14,
    contrast: 1.28,
    saturation: 1.18,
    shadows: 0.42,
    highlights: -0.3,
    warmth: 0.1,
    tint: 0.02,
    sharpness: 0.72,
    vignette: 0.1,
    grain: 0,
    blurBackground: 0,
    skinSmoothing: 0.22
  };
  updateSliders();
  commitHistory();
  render();
}

function applySoftEdgeBlur(amount, bounds) {
  if (amount <= 0.001) return;

  const snapshot = ctx.getImageData(0, 0, canvas.width, canvas.height);
  ctx.save();
  ctx.filter = `blur(${Math.round(amount * 5)}px)`;
  ctx.globalAlpha = Math.min(0.28, amount * 0.32);
  ctx.drawImage(canvas, 0, 0);
  ctx.restore();

  const blurred = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const data = snapshot.data;
  const blurData = blurred.data;
  const cx = bounds.x + bounds.width / 2;
  const cy = bounds.y + bounds.height / 2;
  const radiusX = bounds.width * 0.42;
  const radiusY = bounds.height * 0.42;

  for (let y = 0; y < snapshot.height; y++) {
    for (let x = 0; x < snapshot.width; x++) {
      const i = (y * snapshot.width + x) * 4;
      const dx = (x - cx) / radiusX;
      const dy = (y - cy) / radiusY;
      const edge = Math.max(0, Math.min(1, (Math.hypot(dx, dy) - 0.72) / 0.48)) * amount;
      if (edge <= 0) continue;
      data[i] = data[i] * (1 - edge) + blurData[i] * edge;
      data[i + 1] = data[i + 1] * (1 - edge) + blurData[i + 1] * edge;
      data[i + 2] = data[i + 2] * (1 - edge) + blurData[i + 2] * edge;
    }
  }

  ctx.putImageData(snapshot, 0, 0);
}

function updateSliders() {
  for (const [key] of controls) {
    const slider = document.querySelector(`[data-slider="${key}"]`);
    const output = document.querySelector(`[data-output="${key}"]`);
    if (slider) slider.value = settings[key];
    if (output) output.value = Number(settings[key]).toFixed(2);
  }
}

function buildUI() {
  presetStrip.innerHTML = "";
  presets.forEach(([name, background, presetSettings]) => {
    const button = document.createElement("button");
    button.className = "preset";
    button.innerHTML = `<div class="preset-swatch" style="background:${background}"></div><span>${name}</span>`;
    button.addEventListener("click", () => {
      settings = { ...defaultSettings, ...presetSettings };
      updateSliders();
      commitHistory();
      render();
    });
    presetStrip.appendChild(button);
  });

  sliderList.innerHTML = "";
  controls.forEach(([key, label, min, max, step]) => {
    const row = document.createElement("div");
    row.className = "slider-row";
    row.innerHTML = `
      <div class="slider-head">
        <span>${label}</span>
        <output data-output="${key}">${settings[key].toFixed(2)}</output>
      </div>
      <input data-slider="${key}" type="range" min="${min}" max="${max}" step="${step}" value="${settings[key]}" />
    `;
    const input = row.querySelector("input");
    input.addEventListener("input", () => {
      settings[key] = Number(input.value);
      row.querySelector("output").value = settings[key].toFixed(2);
      render();
    });
    input.addEventListener("change", commitHistory);
    sliderList.appendChild(row);
  });
}

async function exportBlob() {
  if (!sourceBitmap) return null;
  render();
  return new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", exportQuality));
}

fileInput.addEventListener("change", (event) => loadFile(event.target.files[0]));
cameraInput.addEventListener("change", (event) => loadFile(event.target.files[0]));
autoBtn.addEventListener("click", autoEnhance);

compareBtn.addEventListener("pointerdown", () => {
  showingOriginal = true;
  render();
});
compareBtn.addEventListener("pointerup", () => {
  showingOriginal = false;
  render();
});
dropZone.addEventListener("pointerdown", () => {
  if (!sourceBitmap) return;
  showingOriginal = true;
  render();
});
dropZone.addEventListener("pointerup", () => {
  showingOriginal = false;
  render();
});

undoBtn.addEventListener("click", () => {
  if (historyIndex === 0) return;
  historyIndex -= 1;
  settings = { ...history[historyIndex] };
  updateSliders();
  updateHistoryButtons();
  render();
});
redoBtn.addEventListener("click", () => {
  if (historyIndex >= history.length - 1) return;
  historyIndex += 1;
  settings = { ...history[historyIndex] };
  updateSliders();
  updateHistoryButtons();
  render();
});
resetBtn.addEventListener("click", () => {
  settings = { ...defaultSettings };
  updateSliders();
  commitHistory();
  render();
});

document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => {
    document.querySelectorAll(".tab").forEach((item) => item.classList.remove("active"));
    document.querySelectorAll(".panel").forEach((item) => item.classList.remove("active"));
    tab.classList.add("active");
    document.getElementById(`${tab.dataset.tab}Panel`).classList.add("active");
  });
});

document.querySelectorAll(".quality").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".quality").forEach((item) => item.classList.remove("active"));
    button.classList.add("active");
    exportQuality = Number(button.dataset.quality);
  });
});

saveBtn.addEventListener("click", async () => {
  const blob = await exportBlob();
  if (!blob) return;
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "pro-auto-edit.jpg";
  link.click();
  URL.revokeObjectURL(url);
});

shareBtn.addEventListener("click", async () => {
  const blob = await exportBlob();
  if (!blob) return;
  const file = new File([blob], "pro-auto-edit.jpg", { type: "image/jpeg" });
  if (navigator.canShare?.({ files: [file] })) {
    await navigator.share({ files: [file], title: "Pro Auto Edit" });
  } else {
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank");
  }
});

window.addEventListener("resize", render);

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("./sw.js").catch(() => {});
}

buildUI();
fitCanvasToStage();
