/**
 * VegMitra - 3D Smart City Traffic Digital Twin
 * Three.js (r128) - High-Tech Cybernetic Control Room Visualizer
 * 
 * Features:
 * - Fluid topographical data waves (density wave field)
 * - Rock-solid stabilized isometric camera (NO mouse parallax, NO jitter)
 * - Central holographic multi-axis gimbal signal core with ambient vertical beam
 * - Dynamic color transitions: Emerald (GO), Radiant Amber (TRANSITION), Crimson (STOP)
 * - Directional particle velocity streams flowing along the active green corridor
 */

class Traffic3DVisualizer {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    if (!this.container) return;

    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.wavePoints = null;
    this.centralHub = null;
    this.gimbalRings = [];
    this.particleStream = null;
    this.directionalBeams = {};
    this.verticalBeam = null;
    
    this.activeRoad = 'East';
    this.trafficDensity = 50.0;
    this.isAmber = false;
    this.clock = new THREE.Clock();

    this.init();
  }

  init() {
    const width = this.container.clientWidth || 600;
    const height = this.container.clientHeight || 340;

    // 1. Scene with cybernetic deep space fog
    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.FogExp2(0x060913, 0.012);

    // 2. Fixed, stabilized cinematic isometric camera (strictly NO mouse parallax)
    this.camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 1000);
    this.camera.position.set(0, 48, 64);
    this.camera.lookAt(0, 5, 0);

    // 3. High performance WebGL Renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.3;
    this.container.appendChild(this.renderer.domElement);

    // 4. Lights
    const ambientLight = new THREE.AmbientLight(0x0b162c, 2.5);
    this.scene.add(ambientLight);

    this.hubLight = new THREE.PointLight(0x10b981, 4.5, 100);
    this.hubLight.position.set(0, 12, 0);
    this.scene.add(this.hubLight);

    // 5. Build 3D Visual Layers
    this.buildGroundGrid();
    this.buildUndulatingWaveGrid();
    this.buildCentralHologram();
    this.buildDirectionalBeams();
    this.buildFlowingParticleStream();

    // 6. Handle Resize
    window.addEventListener('resize', () => this.onWindowResize());

    // 7. Start Animation Loop
    this.animate();
  }

  buildGroundGrid() {
    // Cybernetic coordinate grid
    const grid = new THREE.GridHelper(90, 30, 0x1e3a5f, 0x0c1626);
    grid.position.y = -3.2;
    this.scene.add(grid);

    // Concentric range rings
    const ringRadii = [15, 30, 42];
    ringRadii.forEach((r, idx) => {
      const ringGeo = new THREE.RingGeometry(r - 0.15, r + 0.15, 64);
      ringGeo.rotateX(-Math.PI / 2);
      const ringMat = new THREE.MeshBasicMaterial({
        color: idx === 0 ? 0x00e676 : 0x1e3a5f,
        transparent: true,
        opacity: 0.35,
        side: THREE.DoubleSide
      });
      const ringMesh = new THREE.Mesh(ringGeo, ringMat);
      ringMesh.position.y = -3.1;
      this.scene.add(ringMesh);
    });
  }

  buildUndulatingWaveGrid() {
    // 55x55 grid of data wave points
    const countX = 55;
    const countZ = 55;
    const spacing = 1.6;
    const totalPoints = countX * countZ;

    const positions = new Float32Array(totalPoints * 3);
    const colors = new Float32Array(totalPoints * 3);

    let idx = 0;
    for (let ix = 0; ix < countX; ix++) {
      for (let iz = 0; iz < countZ; iz++) {
        const x = (ix - countX / 2) * spacing;
        const z = (iz - countZ / 2) * spacing;
        const y = 0;

        positions[idx * 3] = x;
        positions[idx * 3 + 1] = y;
        positions[idx * 3 + 2] = z;

        // Base cyan/electric blue palette
        colors[idx * 3] = 0.04;     // R
        colors[idx * 3 + 1] = 0.38; // G
        colors[idx * 3 + 2] = 0.72; // B

        idx++;
      }
    }

    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    // Particle texture
    const canvas = document.createElement('canvas');
    canvas.width = 32;
    canvas.height = 32;
    const ctx = canvas.getContext('2d');
    const grad = ctx.createRadialGradient(16, 16, 0, 16, 16, 16);
    grad.addColorStop(0, 'rgba(255,255,255,1)');
    grad.addColorStop(0.3, 'rgba(56,189,248,0.9)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, 32, 32);
    const pTexture = new THREE.CanvasTexture(canvas);

    const material = new THREE.PointsMaterial({
      size: 1.5,
      map: pTexture,
      vertexColors: true,
      transparent: true,
      opacity: 0.88,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    this.wavePoints = new THREE.Points(geometry, material);
    this.scene.add(this.wavePoints);
  }

  buildCentralHologram() {
    this.centralHub = new THREE.Group();

    // Central Pedestal Base
    const pillarGeo = new THREE.CylinderGeometry(2.2, 3.4, 7, 24);
    const pillarMat = new THREE.MeshStandardMaterial({
      color: 0x0f1c30,
      roughness: 0.3,
      metalness: 0.85,
      emissive: 0x060f1c
    });
    const pillar = new THREE.Mesh(pillarGeo, pillarMat);
    pillar.position.y = 3.5;
    this.centralHub.add(pillar);

    // Glowing Holographic Core Octahedron Crystal
    const octGeo = new THREE.OctahedronGeometry(2.4, 0);
    const octMat = new THREE.MeshBasicMaterial({
      color: 0x00e676,
      wireframe: true,
      transparent: true,
      opacity: 0.95
    });
    this.coreCrystal = new THREE.Mesh(octGeo, octMat);
    this.coreCrystal.position.y = 10.5;
    this.centralHub.add(this.coreCrystal);

    // Glowing Inner Sphere
    const sphereGeo = new THREE.SphereGeometry(1.3, 24, 24);
    this.coreSphereMat = new THREE.MeshBasicMaterial({ color: 0x10b981 });
    const sphere = new THREE.Mesh(sphereGeo, this.coreSphereMat);
    sphere.position.y = 10.5;
    this.centralHub.add(sphere);

    // 3 Concentric Gimbal Rings
    const ringRadii = [3.5, 4.6, 5.7];
    for (let i = 0; i < ringRadii.length; i++) {
      const ringGeo = new THREE.TorusGeometry(ringRadii[i], 0.09, 8, 54);
      const ringMat = new THREE.MeshBasicMaterial({
        color: i === 0 ? 0x00e676 : 0x38bdf8,
        transparent: true,
        opacity: 0.8
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.position.y = 10.5;
      ring.rotation.x = Math.PI / 2 + (i * 0.45);
      ring.rotation.y = i * 0.5;
      this.centralHub.add(ring);
      this.gimbalRings.push(ring);
    }

    // Vertical Holographic Light Column
    const vertGeo = new THREE.CylinderGeometry(0.3, 1.2, 28, 16, 1, true);
    const vertMat = new THREE.MeshBasicMaterial({
      color: 0x00e676,
      transparent: true,
      opacity: 0.25,
      side: THREE.DoubleSide
    });
    this.verticalBeam = new THREE.Mesh(vertGeo, vertMat);
    this.verticalBeam.position.y = 18;
    this.centralHub.add(this.verticalBeam);

    this.scene.add(this.centralHub);
  }

  buildDirectionalBeams() {
    const directions = {
      North: { x: 0, z: -36 },
      South: { x: 0, z: 36 },
      East: { x: 36, z: 0 },
      West: { x: -36, z: 0 }
    };

    for (const [road, info] of Object.entries(directions)) {
      const beamGroup = new THREE.Group();

      // Energy beam pointing from center to road approach
      const beamGeo = new THREE.CylinderGeometry(0.4, 1.0, 37, 16, 1, true);
      beamGeo.rotateX(Math.PI / 2);
      
      const isGreen = road === this.activeRoad;
      const beamMat = new THREE.MeshBasicMaterial({
        color: isGreen ? 0x10b981 : 0xef4444,
        transparent: true,
        opacity: isGreen ? 0.85 : 0.2,
        side: THREE.DoubleSide
      });
      const beamMesh = new THREE.Mesh(beamGeo, beamMat);
      beamMesh.position.set(info.x / 2, 9.5, info.z / 2);
      beamMesh.lookAt(info.x, 9.5, info.z);
      beamGroup.add(beamMesh);

      // Terminal Traffic Beacon Pole
      const poleGeo = new THREE.CylinderGeometry(0.5, 0.7, 10, 16);
      const poleMat = new THREE.MeshStandardMaterial({ color: 0x162238, metalness: 0.85 });
      const pole = new THREE.Mesh(poleGeo, poleMat);
      pole.position.set(info.x, 5, info.z);
      beamGroup.add(pole);

      // Terminal Signal Head Lamp
      const lampGeo = new THREE.SphereGeometry(1.6, 20, 20);
      const lampMat = new THREE.MeshBasicMaterial({
        color: isGreen ? 0x10b981 : 0xef4444
      });
      const lamp = new THREE.Mesh(lampGeo, lampMat);
      lamp.position.set(info.x, 11, info.z);
      beamGroup.add(lamp);

      this.scene.add(beamGroup);
      this.directionalBeams[road] = {
        group: beamGroup,
        beam: beamMesh,
        lamp: lamp,
        beamMat: beamMat,
        lampMat: lampMat,
        targetPos: new THREE.Vector3(info.x, 9.5, info.z)
      };
    }
  }

  buildFlowingParticleStream() {
    const count = 400;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(count * 3);
    const progress = new Float32Array(count);
    const speeds = new Float32Array(count);

    for (let i = 0; i < count; i++) {
      progress[i] = Math.random();
      speeds[i] = 0.3 + Math.random() * 0.45;
      positions[i * 3] = 0;
      positions[i * 3 + 1] = 9.5;
      positions[i * 3 + 2] = 0;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    this.particleProgress = progress;
    this.particleSpeeds = speeds;

    const pMat = new THREE.PointsMaterial({
      size: 2.0,
      color: 0x00e676,
      transparent: true,
      opacity: 0.95,
      blending: THREE.AdditiveBlending
    });

    this.particleStream = new THREE.Points(geometry, pMat);
    this.scene.add(this.particleStream);
  }

  setSignalState(activeRoad, density = 50.0, isAmber = false) {
    this.activeRoad = activeRoad;
    this.trafficDensity = Math.min(100.0, Math.max(0.0, density));
    this.isAmber = isAmber;

    const activeColor = isAmber ? 0xf59e0b : 0x10b981;
    const activeCoreColor = isAmber ? 0xfbbf24 : 0x00e676;

    // Update Beams
    for (const [road, obj] of Object.entries(this.directionalBeams)) {
      const isActive = road === activeRoad;
      if (isActive) {
        obj.beamMat.color.setHex(activeColor);
        obj.beamMat.opacity = isAmber ? 0.75 : 0.88;
        obj.lampMat.color.setHex(activeColor);
      } else {
        obj.beamMat.color.setHex(0xef4444);
        obj.beamMat.opacity = 0.2;
        obj.lampMat.color.setHex(0xef4444);
      }
    }

    // Update Central Core Hologram
    if (this.coreCrystal) {
      this.coreCrystal.material.color.setHex(activeCoreColor);
    }
    if (this.coreSphereMat) {
      this.coreSphereMat.color.setHex(activeColor);
    }
    if (this.hubLight) {
      this.hubLight.color.setHex(activeColor);
    }
    if (this.verticalBeam) {
      this.verticalBeam.material.color.setHex(activeCoreColor);
      this.verticalBeam.material.opacity = isAmber ? 0.35 : 0.25;
    }
    if (this.particleStream) {
      this.particleStream.material.color.setHex(activeCoreColor);
    }
  }

  onWindowResize() {
    if (!this.container || !this.renderer || !this.camera) return;
    const width = this.container.clientWidth;
    const height = this.container.clientHeight || 340;
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(width, height);
  }

  animate() {
    requestAnimationFrame(() => this.animate());

    const time = this.clock.getElapsedTime();

    // 1. Undulate 3D Topographical Energy Waves
    if (this.wavePoints) {
      const positions = this.wavePoints.geometry.attributes.position.array;
      const colors = this.wavePoints.geometry.attributes.color.array;
      const count = positions.length / 3;

      const waveSpeed = 1.35;
      const amp = 1.2 + (this.trafficDensity / 100.0) * 2.2;

      for (let i = 0; i < count; i++) {
        const x = positions[i * 3];
        const z = positions[i * 3 + 2];

        const distFromCenter = Math.sqrt(x * x + z * z);
        const y = Math.sin(x * 0.11 + time * waveSpeed) * Math.cos(z * 0.11 + time * waveSpeed) * amp
                + Math.sin(distFromCenter * 0.16 - time * 2.2) * 0.75;
        
        positions[i * 3 + 1] = y;

        const heightNorm = Math.min(1.0, Math.max(0.0, (y + amp) / (amp * 2)));

        // Color wave nodes based on direction
        if (this.activeRoad === 'East' && x > 4) {
          colors[i * 3] = this.isAmber ? 0.9 : 0.05 + heightNorm * 0.1;
          colors[i * 3 + 1] = this.isAmber ? 0.65 : 0.68 + heightNorm * 0.32;
          colors[i * 3 + 2] = this.isAmber ? 0.1 : 0.3;
        } else if (this.activeRoad === 'South' && z > 4) {
          colors[i * 3] = this.isAmber ? 0.9 : 0.05 + heightNorm * 0.1;
          colors[i * 3 + 1] = this.isAmber ? 0.65 : 0.68 + heightNorm * 0.32;
          colors[i * 3 + 2] = this.isAmber ? 0.1 : 0.3;
        } else if (this.activeRoad === 'West' && x < -4) {
          colors[i * 3] = this.isAmber ? 0.9 : 0.05 + heightNorm * 0.1;
          colors[i * 3 + 1] = this.isAmber ? 0.65 : 0.68 + heightNorm * 0.32;
          colors[i * 3 + 2] = this.isAmber ? 0.1 : 0.3;
        } else if (this.activeRoad === 'North' && z < -4) {
          colors[i * 3] = this.isAmber ? 0.9 : 0.05 + heightNorm * 0.1;
          colors[i * 3 + 1] = this.isAmber ? 0.65 : 0.68 + heightNorm * 0.32;
          colors[i * 3 + 2] = this.isAmber ? 0.1 : 0.3;
        } else {
          // Deep electric blue/cyan ambient field
          colors[i * 3] = 0.03;
          colors[i * 3 + 1] = 0.22 + heightNorm * 0.35;
          colors[i * 3 + 2] = 0.58 + heightNorm * 0.42;
        }
      }

      this.wavePoints.geometry.attributes.position.needsUpdate = true;
      this.wavePoints.geometry.attributes.color.needsUpdate = true;
    }

    // 2. Rotate Central Holographic Crystal & Multi-Axis Gimbal Rings
    if (this.coreCrystal) {
      this.coreCrystal.rotation.y = time * 0.95;
      this.coreCrystal.rotation.x = Math.sin(time * 0.6) * 0.25;
    }

    if (this.gimbalRings.length >= 3) {
      this.gimbalRings[0].rotation.z = time * 0.65;
      this.gimbalRings[1].rotation.x = time * -0.52;
      this.gimbalRings[2].rotation.y = time * 0.78;
    }

    if (this.verticalBeam) {
      this.verticalBeam.rotation.y = -time * 0.3;
    }

    // 3. Flow Particle Streams along Active Clearance Path
    if (this.particleStream && this.directionalBeams[this.activeRoad]) {
      const positions = this.particleStream.geometry.attributes.position.array;
      const target = this.directionalBeams[this.activeRoad].targetPos;
      const count = positions.length / 3;
      const speedMult = this.isAmber ? 0.006 : 0.016;

      for (let i = 0; i < count; i++) {
        this.particleProgress[i] += this.particleSpeeds[i] * speedMult;
        if (this.particleProgress[i] > 1) {
          this.particleProgress[i] = 0;
        }

        const t = this.particleProgress[i];
        // Move from center outwards along the green road
        const curX = target.x * t;
        const curZ = target.z * t;
        const curY = 9.5 + Math.sin(t * Math.PI) * 2.2 + Math.sin(i + time * 3.5) * 0.35;

        positions[i * 3] = curX + (Math.sin(i * 12) * 0.9);
        positions[i * 3 + 1] = curY;
        positions[i * 3 + 2] = curZ + (Math.cos(i * 12) * 0.9);
      }

      this.particleStream.geometry.attributes.position.needsUpdate = true;
    }

    // Fixed, stabilized camera render (strictly NO parallax)
    this.renderer.render(this.scene, this.camera);
  }
}

window.Traffic3DVisualizer = Traffic3DVisualizer;
