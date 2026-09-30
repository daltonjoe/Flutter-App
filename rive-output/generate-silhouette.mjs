import { writeFileSync } from 'node:fs';
import { RiveFile, PropertyKey, hex } from '@stevysmith/rive-generator';

const riv = new RiveFile();
const artboard = riv.addArtboard({ name: 'Silhouette', width: 800, height: 1200 });

const colors = {
  deep: hex('#0B1035'),
  deepDark: hex('#05060F'),
  mid: hex('#4B2E83'),
  star: hex('#FFFFFF'),
  silhouette: hex('#F5C86B'),
  white: hex('#FFFFFF'),
  orbit: hex('#C9D6FF'),
  orbitOuter: hex('#7FD6FF'),
  lineLow: hex('#4A4A5A'),
  lineHigh: hex('#F5C86B'),
};

const rand = (seed) => {
  const value = Math.sin(seed * 12.9898) * 43758.5453;
  return value - Math.floor(value);
};

function addOpacityAnimation(target, name, values, options = {}) {
  const animation = riv.addLinearAnimation(artboard, {
    name,
    fps: options.fps ?? 60,
    duration: options.duration ?? 60,
    loop: options.loop ?? 'oneShot',
  });
  const keyedObject = riv.addKeyedObject(animation, target);
  const property = riv.addKeyedProperty(keyedObject, PropertyKey.opacity);
  for (const point of values) {
    riv.addKeyFrameDouble(property, {
      frame: point.frame,
      value: point.value,
      interpolation: point.interpolation ?? 'cubic',
    });
  }
  return animation;
}

function addScaleAnimation(target, name, duration, loop = 'loop', low = 1, high = 1.03) {
  const animation = riv.addLinearAnimation(artboard, {
    name,
    fps: 60,
    duration,
    loop,
  });
  const keyedObject = riv.addKeyedObject(animation, target);
  for (const key of [PropertyKey.scaleX, PropertyKey.scaleY]) {
    const property = riv.addKeyedProperty(keyedObject, key);
    riv.addKeyFrameDouble(property, { frame: 0, value: low, interpolation: 'cubic' });
    riv.addKeyFrameDouble(property, { frame: duration / 2, value: high, interpolation: 'cubic' });
    riv.addKeyFrameDouble(property, { frame: duration, value: low, interpolation: 'cubic' });
  }
  return animation;
}

function addRotationAnimation(target, name, duration, direction = 1) {
  const animation = riv.addLinearAnimation(artboard, {
    name,
    fps: 1,
    duration,
    loop: 'loop',
  });
  const keyedObject = riv.addKeyedObject(animation, target);
  const property = riv.addKeyedProperty(keyedObject, PropertyKey.rotation);
  riv.addKeyFrameDouble(property, { frame: 0, value: 0, interpolation: 'linear' });
  riv.addKeyFrameDouble(property, {
    frame: duration,
    value: direction * Math.PI * 2,
    interpolation: 'linear',
  });
}

function addGradient(parent, name, start, end, startColor, endColor, opacity = 1) {
  const gradient = riv.addRadialGradient(parent, {
    name,
    startX: start.x,
    startY: start.y,
    endX: end.x,
    endY: end.y,
    opacity,
  });
  riv.addGradientStop(gradient, { position: 0, color: startColor });
  riv.addGradientStop(gradient, { position: 1, color: endColor });
  return gradient;
}

const background = riv.addNode(artboard, { name: 'Group_A_Background_Depth' });
addScaleAnimation(background, 'Breath', 480, 'loop', 1, 1.01);

const deep = riv.addShape(background, { name: 'A1_Deep_Glow', x: 400, y: 600 });
const deepPath = riv.addEllipse(deep, { name: 'DeepGlowEllipse', width: 1200, height: 1200 });
const deepFill = riv.addFill(deep, { name: 'DeepGlowFill' });
addGradient(deepFill, 'DeepGlowGradient', { x: 0, y: 0 }, { x: 600, y: 600 }, colors.deep, colors.deepDark);
addScaleAnimation(deep, 'DeepGlow_Breathe_8s', 480, 'loop', 1, 1.03);

const mid = riv.addShape(background, { name: 'A2_Mid_Glow', x: 400, y: 600 });
riv.addEllipse(mid, { name: 'MidGlowEllipse', width: 720, height: 720 });
const midFill = riv.addFill(mid, { name: 'MidGlowFill' });
addGradient(midFill, 'MidGlowGradient', { x: 0, y: 0 }, { x: 360, y: 360 }, colors.mid, colors.deepDark, 0.4);
addScaleAnimation(mid, 'MidGlow_Breathe_6s', 360, 'loop', 1.03, 1);

const stars = riv.addNode(background, { name: 'A3_Star_Field' });
for (let i = 0; i < 40; i += 1) {
  const x = 40 + rand(i + 1) * 720;
  const y = 40 + rand(i + 101) * 1120;
  const size = 1 + rand(i + 201) * 2;
  const star = riv.addShape(stars, { name: `Star_${String(i + 1).padStart(2, '0')}`, x, y });
  riv.addEllipse(star, { width: size, height: size });
  const fill = riv.addFill(star, { name: `StarFill_${i + 1}` });
  riv.addSolidColor(fill, colors.star);
  const duration = Math.round(120 + rand(i + 301) * 180);
  const phase = Math.round(rand(i + 401) * duration);
  addOpacityAnimation(fill, `StarTwinkle_${i + 1}`, [
    { frame: phase, value: 0.2 },
    { frame: phase + Math.round(duration / 2), value: 0.8 },
    { frame: phase + duration, value: 0.2 },
  ], { duration, loop: 'loop' });
}

const silhouette = riv.addNode(artboard, { name: 'Group_B_Silhouette' });
const base = riv.addShape(silhouette, { name: 'B1_Silhouette_Base', x: 400, y: 670 });
riv.addEllipse(base, { name: 'SilhouetteBody', width: 430, height: 700 });
const baseFill = riv.addFill(base, { name: 'SilhouetteBaseFill' });
riv.addSolidColor(baseFill, colors.silhouette);

const progress = riv.addLinearAnimation(artboard, {
  name: 'Progress',
  fps: 1,
  duration: 100,
  loop: 'oneShot',
});
const progressObject = riv.addKeyedObject(progress, baseFill);
const baseOpacity = riv.addKeyedProperty(progressObject, PropertyKey.opacity);
for (const [frame, value] of [[0, 0.12], [15, 0.25], [30, 0.4], [45, 0.55], [60, 0.7], [75, 0.85], [90, 0.95], [100, 1]]) {
  riv.addKeyFrameDouble(baseOpacity, { frame, value, interpolation: 'cubic' });
}

const rim = riv.addShape(silhouette, { name: 'B2_Silhouette_Rim', x: 400, y: 670 });
riv.addEllipse(rim, { name: 'SilhouetteRimEllipse', width: 438, height: 708 });
const rimStroke = riv.addStroke(rim, { name: 'RimStroke', thickness: 3 });
const rimColor = riv.addSolidColor(rimStroke, colors.white);
const rimProgress = riv.addKeyedObject(progress, rimStroke);
const rimOpacity = riv.addKeyedProperty(rimProgress, PropertyKey.opacity);
for (const [frame, value] of [[0, 0], [75, 0.5], [90, 0.8], [100, 1]]) {
  riv.addKeyFrameDouble(rimOpacity, { frame, value, interpolation: 'cubic' });
}

const noise = riv.addNode(silhouette, { name: 'B3_Silhouette_Noise_Overlay' });
const noiseFill = riv.addFill(noise, { name: 'NoiseFill' });
riv.addSolidColor(noiseFill, colors.white);
const noiseProgress = riv.addKeyedObject(progress, noiseFill);
const noiseOpacity = riv.addKeyedProperty(noiseProgress, PropertyKey.opacity);
for (const [frame, value] of [[0, 0], [60, 0.3], [100, 0.5]]) {
  riv.addKeyFrameDouble(noiseOpacity, { frame, value, interpolation: 'cubic' });
}
for (let i = 0; i < 30; i += 1) {
  const x = 220 + rand(i + 501) * 360;
  const y = 330 + rand(i + 601) * 680;
  const size = 2 + rand(i + 701) * 2;
  const point = riv.addShape(noise, { name: `NoisePoint_${i + 1}`, x, y });
  riv.addEllipse(point, { width: size, height: size });
  riv.addFill(point, { name: `NoisePointFill_${i + 1}` });
}

const particleLayer = riv.addNode(artboard, { name: 'Group_C_Celestial_Bodies' });
const particleNames = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto'];
const particlePositions = [
  [400, 490], [400, 850], [320, 540], [485, 550], [300, 700],
  [515, 680], [335, 810], [470, 810], [365, 920], [445, 930],
];
const particleIds = new Map();
for (let i = 0; i < particleNames.length; i += 1) {
  const name = particleNames[i];
  const [x, y] = particlePositions[i];
  const coreSize = i < 2 ? 18 : 12;
  const group = riv.addNode(particleLayer, { name: `Particle_${name}` , x, y });
  particleIds.set(name, group);
  const glow = riv.addShape(group, { name: `${name}_Glow` });
  riv.addEllipse(glow, { width: coreSize * 2.5, height: coreSize * 2.5 });
  const glowFill = riv.addFill(glow, { name: `${name}_GlowFill` });
  addGradient(glowFill, `${name}_GlowGradient`, { x: 0, y: 0 }, { x: coreSize, y: coreSize }, colors.silhouette, colors.deepDark, 0.3);
  const core = riv.addShape(group, { name: `${name}_Core` });
  riv.addEllipse(core, { width: coreSize, height: coreSize });
  const coreFill = riv.addFill(core, { name: `${name}_CoreFill` });
  riv.addSolidColor(coreFill, i === 0 ? colors.silhouette : colors.white);
  addScaleAnimation(group, `${name}_Pulse_3s`, 180, 'loop', 1, 1.15);
  const particleProgress = riv.addKeyedObject(progress, group);
  const particleOpacity = riv.addKeyedProperty(particleProgress, PropertyKey.opacity);
  const revealFrame = i === 0 ? 15 : i === 1 ? 30 : i < 5 ? 45 : i < 7 ? 60 : 75;
  riv.addKeyFrameDouble(particleOpacity, { frame: 0, value: 0, interpolation: 'cubic' });
  riv.addKeyFrameDouble(particleOpacity, { frame: revealFrame, value: 1, interpolation: 'cubic' });
}

const orbitLayer = riv.addNode(artboard, { name: 'Group_D_Orbit_System' , x: 400, y: 700 });
const orbitData = [
  ['D1_Orbit_Ring_Inner', 470, 330, colors.orbit, 0.5, 2400, 1],
  ['D2_Orbit_Ring_Mid', 610, 430, colors.orbit, 0.6, 3300, -1],
  ['D3_Orbit_Ring_Outer', 750, 540, colors.orbitOuter, 1, 4200, 1],
];
for (const [name, width, height, color, opacity, duration, direction] of orbitData) {
  const ring = riv.addShape(orbitLayer, { name });
  riv.addEllipse(ring, { width, height });
  const stroke = riv.addStroke(ring, { name: `${name}_Stroke`, thickness: name.includes('Outer') ? 1 : 2 });
  const solid = riv.addSolidColor(stroke, color);
  addOpacityAnimation(stroke, `${name}_ProgressOpacity`, [
    { frame: 0, value: 0 },
    { frame: 30, value: name.includes('Inner') ? 0.5 : 0 },
    { frame: 60, value: name.includes('Outer') ? 0.4 : opacity },
    { frame: 100, value: opacity },
  ], { fps: 1, duration: 100 });
  addRotationAnimation(ring, `${name}_Rotation`, duration, direction);
}

const lineLayer = riv.addNode(artboard, { name: 'Group_E_Aspect_Lines' });
const pairs = [
  ['sun', 'moon'], ['sun', 'mercury'], ['moon', 'venus'], ['mercury', 'mars'],
  ['venus', 'jupiter'], ['mars', 'saturn'], ['jupiter', 'uranus'], ['neptune', 'pluto'],
];
for (let i = 0; i < pairs.length; i += 1) {
  const [from, to] = pairs[i];
  const [x1, y1] = particlePositions[particleNames.indexOf(from)];
  const [x2, y2] = particlePositions[particleNames.indexOf(to)];
  const path = riv.addPointsPath(lineLayer, { name: `AspectLine_${i + 1}`, closed: false });
  riv.addVertex(path, { x: x1, y: y1 });
  riv.addVertex(path, { x: x2, y: y2 });
  const stroke = riv.addStroke(path, { name: `AspectStroke_${i + 1}`, thickness: 1 });
  const solid = riv.addSolidColor(stroke, colors.lineLow);
  addOpacityAnimation(stroke, `AspectDraw_${i + 1}`, [
    { frame: 0, value: 0 },
    { frame: 48 + i * 6, value: 0 },
    { frame: 96 + i * 6, value: 1 },
  ], { fps: 60, duration: 120 });
}

const burst = riv.addNode(artboard, { name: 'Group_F_Reveal_Burst', x: 400, y: 700 });
for (let i = 0; i < 20; i += 1) {
  const angle = (Math.PI * 2 * i) / 20;
  const distance = 80 + rand(i + 801) * 180;
  const particle = riv.addShape(burst, {
    name: `RevealParticle_${i + 1}`,
    x: Math.cos(angle) * distance,
    y: Math.sin(angle) * distance,
  });
  riv.addEllipse(particle, { width: 3, height: 3 });
  const fill = riv.addFill(particle);
  riv.addSolidColor(fill, colors.silhouette);
  addOpacityAnimation(fill, `RevealParticleFade_${i + 1}`, [
    { frame: 0, value: 1 },
    { frame: 60, value: 0 },
  ], { fps: 60, duration: 60 });
  addScaleAnimation(particle, `RevealParticleScale_${i + 1}`, 60, 'oneShot', 0.5, 2);
}

const reveal = riv.addLinearAnimation(artboard, {
  name: 'Reveal',
  fps: 60,
  duration: 108,
  loop: 'oneShot',
});
const revealObject = riv.addKeyedObject(reveal, burst);
for (const key of [PropertyKey.scaleX, PropertyKey.scaleY]) {
  const property = riv.addKeyedProperty(revealObject, key);
  riv.addKeyFrameDouble(property, { frame: 0, value: 1, interpolation: 'cubic' });
  riv.addKeyFrameDouble(property, { frame: 18, value: 1.1, interpolation: 'cubic' });
  riv.addKeyFrameDouble(property, { frame: 72, value: 0.95, interpolation: 'cubic' });
  riv.addKeyFrameDouble(property, { frame: 108, value: 1, interpolation: 'cubic' });
}

writeFileSync('silhouette.riv', riv.export());
