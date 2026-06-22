// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// animations.jsx
// Reusable animation starter: Stage, Timeline, Sprite, easing helpers.
// Exports (to window): Stage, Sprite, PlaybackBar, TextSprite, ImageSprite, RectSprite,
//   useTime, useTimeline, useSprite, Easing, interpolate, animate, clamp.
//
// Usage (in an HTML file that loads React + Babel):
//
//   <Stage width={1280} height={720} duration={10} background="#f6f4ef">
//     <MyScene />
//   </Stage>
//
// <Stage> auto-scales to the viewport and provides the scrubber, play/pause,
// ←/→ seek, space, and 0-to-reset controls, and persists the playhead.
// Inside <Stage>, any child can call useTime() to read the current
// playhead (seconds). Or wrap content in <Sprite start={1} end={4}>...</Sprite>
// to only render during that window -- children receive a `localTime` and
// `progress` via the useSprite() hook. Use Easing + interpolate()/animate()
// for tweens; TextSprite / ImageSprite / RectSprite have built-in entry/exit.
// Build YOUR scenes by composing Sprites inside a Stage.
/* END USAGE */
// ─────────────────────────────────────────────────────────────────────────────

// ── Easing functions (hand-rolled, Popmotion-style) ─────────────────────────
// All easings take t ∈ [0,1] and return eased t ∈ [0,1] (may overshoot for back/elastic).
const Easing = {
  linear: (t) => t,

  // Quad
  easeInQuad:    (t) => t * t,
  easeOutQuad:   (t) => t * (2 - t),
  easeInOutQuad: (t) => (t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t),

  // Cubic
  easeInCubic:    (t) => t * t * t,
  easeOutCubic:   (t) => (--t) * t * t + 1,
  easeInOutCubic: (t) => (t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1),

  // Quart
  easeInQuart:    (t) => t * t * t * t,
  easeOutQuart:   (t) => 1 - (--t) * t * t * t,
  easeInOutQuart: (t) => (t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (--t) * t * t * t),

  // Expo
  easeInExpo:  (t) => (t === 0 ? 0 : Math.pow(2, 10 * (t - 1))),
  easeOutExpo: (t) => (t === 1 ? 1 : 1 - Math.pow(2, -10 * t)),
  easeInOutExpo: (t) => {
    if (t === 0) return 0;
    if (t === 1) return 1;
    if (t < 0.5) return 0.5 * Math.pow(2, 20 * t - 10);
    return 1 - 0.5 * Math.pow(2, -20 * t + 10);
  },

  // Sine
  easeInSine:    (t) => 1 - Math.cos((t * Math.PI) / 2),
  easeOutSine:   (t) => Math.sin((t * Math.PI) / 2),
  easeInOutSine: (t) => -(Math.cos(Math.PI * t) - 1) / 2,

  // Back (overshoot)
  easeOutBack: (t) => {
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2);
  },
  easeInBack: (t) => {
    const c1 = 1.70158, c3 = c1 + 1;
    return c3 * t * t * t - c1 * t * t;
  },
  easeInOutBack: (t) => {
    const c1 = 1.70158, c2 = c1 * 1.525;
    return t < 0.5
      ? (Math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
      : (Math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2;
  },

  // Elastic
  easeOutElastic: (t) => {
    const c4 = (2 * Math.PI) / 3;
    if (t === 0) return 0;
    if (t === 1) return 1;
    return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
  },
};

// ── Core interpolation helpers ──────────────────────────────────────────────

// Clamp a value to [min, max]
const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

// interpolate([0, 0.5, 1], [0, 100, 50], ease?) -> fn(t)
// Popmotion-style: linearly maps t across input keyframes to output values,
// with optional easing per segment (single fn or array of fns).
function interpolate(input, output, ease = Easing.linear) {
  return (t) => {
    if (t <= input[0]) return output[0];
    if (t >= input[input.length - 1]) return output[output.length - 1];
    for (let i = 0; i < input.length - 1; i++) {
      if (t >= input[i] && t <= input[i + 1]) {
        const span = input[i + 1] - input[i];
        const local = span === 0 ? 0 : (t - input[i]) / span;
        const easeFn = Array.isArray(ease) ? (ease[i] || Easing.linear) : ease;
        const eased = easeFn(local);
        return output[i] + (output[i + 1] - output[i]) * eased;
      }
    }
    return output[output.length - 1];
  };
}

// animate({from, to, start, end, ease})(t) — simpler single-segment tween.
// Returns `from` before `start`, `to` after `end`.
function animate({ from = 0, to = 1, start = 0, end = 1, ease = Easing.easeInOutCubic }) {
  return (t) => {
    if (t <= start) return from;
    if (t >= end) return to;
    const local = (t - start) / (end - start);
    return from + (to - from) * ease(local);
  };
}

// ── Timeline context ────────────────────────────────────────────────────────

const TimelineContext = React.createContext({ time: 0, duration: 10, playing: false });

const useTime = () => React.useContext(TimelineContext).time;
const useTimeline = () => React.useContext(TimelineContext);

// ── Sprite ──────────────────────────────────────────────────────────────────
// Renders children only when the playhead is inside [start, end]. Provides
// a sub-context with `localTime` (seconds since start) and `progress` (0..1).
//
//   <Sprite start={2} end={5}>
//     {({ localTime, progress }) => <Thing x={progress * 100} />}
//   </Sprite>
//
// Or as a plain wrapper — children can call useSprite() themselves.

const SpriteContext = React.createContext({ localTime: 0, progress: 0, duration: 0 });
const useSprite = () => React.useContext(SpriteContext);

function Sprite({ start = 0, end = Infinity, children, keepMounted = false }) {
  const { time } = useTimeline();
  const visible = time >= start && time <= end;
  if (!visible && !keepMounted) return null;

  const duration = end - start;
  const localTime = Math.max(0, time - start);
  const progress = duration > 0 && isFinite(duration)
    ? clamp(localTime / duration, 0, 1)
    : 0;

  const value = { localTime, progress, duration, visible };

  return (
    <SpriteContext.Provider value={value}>
      {typeof children === 'function' ? children(value) : children}
    </SpriteContext.Provider>
  );
}

// ── Sample sprite components ────────────────────────────────────────────────

// TextSprite: fades/slides text in on entry, holds, then fades out on exit.
// Props: text, x, y, size, color, font, entryDur, exitDur, align
function TextSprite({
  text,
  x = 0, y = 0,
  size = 48,
  color = '#111',
  font = 'Inter, system-ui, sans-serif',
  weight = 600,
  entryDur = 0.45,
  exitDur = 0.35,
  entryEase = Easing.easeOutBack,
  exitEase = Easing.easeInCubic,
  align = 'left',
  letterSpacing = '-0.01em',
}) {
  const { localTime, duration } = useSprite();
  const exitStart = Math.max(0, duration - exitDur);

  let opacity = 1;
  let ty = 0;

  if (localTime < entryDur) {
    const t = entryEase(clamp(localTime / entryDur, 0, 1));
    opacity = t;
    ty = (1 - t) * 16;
  } else if (localTime > exitStart) {
    const t = exitEase(clamp((localTime - exitStart) / exitDur, 0, 1));
    opacity = 1 - t;
    ty = -t * 8;
  }

  const translateX = align === 'center' ? '-50%' : align === 'right' ? '-100%' : '0';

  return (
    <div style={{
      position: 'absolute',
      left: x, top: y,
      transform: `translate(${translateX}, ${ty}px)`,
      opacity,
      fontFamily: font,
      fontSize: size,
      fontWeight: weight,
      color,
      letterSpacing,
      whiteSpace: 'pre',
      lineHeight: 1.1,
      willChange: 'transform, opacity',
    }}>
      {text}
    </div>
  );
}

// ImageSprite: scales + fades in; optional Ken Burns drift during hold.
function ImageSprite({
  src,
  x = 0, y = 0,
  width = 400, height = 300,
  entryDur = 0.6,
  exitDur = 0.4,
  kenBurns = false,
  kenBurnsScale = 1.08,
  radius = 12,
  fit = 'cover',
  placeholder = null, // {label: string} for striped placeholder
}) {
  const { localTime, duration } = useSprite();
  const exitStart = Math.max(0, duration - exitDur);

  let opacity = 1;
  let scale = 1;

  if (localTime < entryDur) {
    const t = Easing.easeOutCubic(clamp(localTime / entryDur, 0, 1));
    opacity = t;
    scale = 0.96 + 0.04 * t;
  } else if (localTime > exitStart) {
    const t = Easing.easeInCubic(clamp((localTime - exitStart) / exitDur, 0, 1));
    opacity = 1 - t;
    scale = (kenBurns ? kenBurnsScale : 1) + 0.02 * t;
  } else if (kenBurns) {
    const holdSpan = exitStart - entryDur;
    const holdT = holdSpan > 0 ? (localTime - entryDur) / holdSpan : 0;
    scale = 1 + (kenBurnsScale - 1) * holdT;
  }

  const content = placeholder ? (
    <div style={{
      width: '100%', height: '100%',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'repeating-linear-gradient(135deg, #e9e6df 0 10px, #dcd8cf 10px 20px)',
      color: '#6b6458',
      fontFamily: 'JetBrains Mono, ui-monospace, monospace',
      fontSize: 13,
      letterSpacing: '0.04em',
      textTransform: 'uppercase',
    }}>
      {placeholder.label || 'image'}
    </div>
  ) : (
    <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: fit, display: 'block' }} />
  );

  return (
    <div style={{
      position: 'absolute',
      left: x, top: y,
      width, height,
      opacity,
      transform: `scale(${scale})`,
      transformOrigin: 'center',
      borderRadius: radius,
      overflow: 'hidden',
      willChange: 'transform, opacity',
    }}>
      {content}
    </div>
  );
}

// RectSprite: simple rectangle that animates position/size/color via props.
// Useful demo primitive — takes a `render` fn for per-frame customization.
function RectSprite({
  x = 0, y = 0,
  width = 100, height = 100,
  color = '#111',
  radius = 8,
  entryDur = 0.4,
  exitDur = 0.3,
  render, // optional: (ctx) => style overrides
}) {
  const spriteCtx = useSprite();
  const { localTime, duration } = spriteCtx;
  const exitStart = Math.max(0, duration - exitDur);

  let opacity = 1;
  let scale = 1;

  if (localTime < entryDur) {
    const t = Easing.easeOutBack(clamp(localTime / entryDur, 0, 1));
    opacity = clamp(localTime / entryDur, 0, 1);
    scale = 0.4 + 0.6 * t;
  } else if (localTime > exitStart) {
    const t = Easing.easeInQuad(clamp((localTime - exitStart) / exitDur, 0, 1));
    opacity = 1 - t;
    scale = 1 - 0.15 * t;
  }

  const overrides = render ? render(spriteCtx) : {};

  return (
    <div style={{
      position: 'absolute',
      left: x, top: y,
      width, height,
      background: color,
      borderRadius: radius,
      opacity,
      transform: `scale(${scale})`,
      transformOrigin: 'center',
      willChange: 'transform, opacity',
      ...overrides,
    }} />
  );
}


function Stage({
  width = 1280,
  height = 720,
  duration = 10,
  background = '#f6f4ef',
  fps = 60,
  loop = true,
  autoplay = true,
  persistKey = 'animstage',
  children,
}) {
  const [time, setTime] = React.useState(() => {
    try {
      const v = parseFloat(localStorage.getItem(persistKey + ':t') || '0');
      return isFinite(v) ? clamp(v, 0, duration) : 0;
    } catch { return 0; }
  });
  const [playing, setPlaying] = React.useState(autoplay);
  const [hoverTime, setHoverTime] = React.useState(null);
  const [scale, setScale] = React.useState(1);

  const stageRef = React.useRef(null);
  const canvasRef = React.useRef(null);
  const rafRef = React.useRef(null);
  const lastTsRef = React.useRef(null);

  // Persist playhead
  React.useEffect(() => {
    try { localStorage.setItem(persistKey + ':t', String(time)); } catch {}
  }, [time, persistKey]);

  // Auto-scale to fit viewport
  React.useEffect(() => {
    if (!stageRef.current) return;
    const el = stageRef.current;
    const measure = () => {
      const barH = 44; // playback bar height
      const s = Math.min(
        el.clientWidth / width,
        (el.clientHeight - barH) / height
      );
      setScale(Math.max(0.05, s));
    };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    window.addEventListener('resize', measure);
    return () => {
      ro.disconnect();
      window.removeEventListener('resize', measure);
    };
  }, [width, height]);

  // Animation loop
  React.useEffect(() => {
    if (!playing) {
      lastTsRef.current = null;
      return;
    }
    const step = (ts) => {
      if (lastTsRef.current == null) lastTsRef.current = ts;
      const dt = (ts - lastTsRef.current) / 1000;
      lastTsRef.current = ts;
      setTime((t) => {
        let next = t + dt;
        if (next >= duration) {
          if (loop) next = next % duration;
          else { next = duration; setPlaying(false); }
        }
        return next;
      });
      rafRef.current = requestAnimationFrame(step);
    };
    rafRef.current = requestAnimationFrame(step);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      lastTsRef.current = null;
    };
  }, [playing, duration, loop]);

  // Keyboard: space = play/pause, ← → = seek
  React.useEffect(() => {
    const onKey = (e) => {
      if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) return;
      if (e.code === 'Space') {
        e.preventDefault();
        setPlaying(p => !p);
      } else if (e.code === 'ArrowLeft') {
        setTime(t => clamp(t - (e.shiftKey ? 1 : 0.1), 0, duration));
      } else if (e.code === 'ArrowRight') {
        setTime(t => clamp(t + (e.shiftKey ? 1 : 0.1), 0, duration));
      } else if (e.key === '0' || e.code === 'Home') {
        setTime(0);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [duration]);

  const displayTime = hoverTime != null ? hoverTime : time;

  const ctxValue = React.useMemo(
    () => ({ time: displayTime, duration, playing, setTime, setPlaying }),
    [displayTime, duration, playing]
  );

  return (
    <div
      ref={stageRef}
      style={{
        position: 'absolute', inset: 0,
        display: 'flex', flexDirection: 'column',
        alignItems: 'center',
        background: '#0a0a0a',
        fontFamily: 'Inter, system-ui, sans-serif',
      }}
    >
      {/* Canvas area — vertically centered in remaining space */}
      <div style={{
        flex: 1,
        width: '100%',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        overflow: 'hidden',
        minHeight: 0,
      }}>
        <div
          ref={canvasRef}
          style={{
            width, height,
            background,
            position: 'relative',
            transform: `scale(${scale})`,
            transformOrigin: 'center',
            flexShrink: 0,
            boxShadow: '0 20px 60px rgba(0,0,0,0.4)',
            overflow: 'hidden',
          }}
        >
          <TimelineContext.Provider value={ctxValue}>
            {children}
          </TimelineContext.Provider>
        </div>
      </div>

      {/* Playback bar — stacked below canvas, never overlapping */}
      <PlaybackBar
        time={displayTime}
        actualTime={time}
        duration={duration}
        playing={playing}
        onPlayPause={() => setPlaying(p => !p)}
        onReset={() => { setTime(0); }}
        onSeek={(t) => setTime(t)}
        onHover={(t) => setHoverTime(t)}
      />
    </div>
  );
}

// ── Playback bar ────────────────────────────────────────────────────────────
// Play/pause, return-to-begin, scrub track, time display.
// Uses fixed-width time fields so layout doesn't thrash.

function PlaybackBar({ time, duration, playing, onPlayPause, onReset, onSeek, onHover }) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);

  const timeFromEvent = React.useCallback((e) => {
    const rect = trackRef.current.getBoundingClientRect();
    const x = clamp((e.clientX - rect.left) / rect.width, 0, 1);
    return x * duration;
  }, [duration]);

  const onTrackMove = (e) => {
    if (!trackRef.current) return;
    const t = timeFromEvent(e);
    if (dragging) {
      onSeek(t);
    } else {
      onHover(t);
    }
  };

  const onTrackLeave = () => {
    if (!dragging) onHover(null);
  };

  const onTrackDown = (e) => {
    setDragging(true);
    const t = timeFromEvent(e);
    onSeek(t);
    onHover(null);
  };

  React.useEffect(() => {
    if (!dragging) return;
    const onUp = () => setDragging(false);
    const onMove = (e) => {
      if (!trackRef.current) return;
      const t = timeFromEvent(e);
      onSeek(t);
    };
    window.addEventListener('mouseup', onUp);
    window.addEventListener('mousemove', onMove);
    return () => {
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('mousemove', onMove);
    };
  }, [dragging, timeFromEvent, onSeek]);

  const pct = duration > 0 ? (time / duration) * 100 : 0;
  const fmt = (t) => {
    const total = Math.max(0, t);
    const m = Math.floor(total / 60);
    const s = Math.floor(total % 60);
    const cs = Math.floor((total * 100) % 100);
    return `${String(m).padStart(1, '0')}:${String(s).padStart(2, '0')}.${String(cs).padStart(2, '0')}`;
  };

  const mono = 'JetBrains Mono, ui-monospace, SFMono-Regular, monospace';

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '8px 16px',
      background: 'rgba(20,20,20,0.92)',
      borderTop: '1px solid rgba(255,255,255,0.08)',
      width: '100%',
      maxWidth: 680,
      alignSelf: 'center',

      borderRadius: 8,
      color: '#f6f4ef',
      fontFamily: 'Inter, system-ui, sans-serif',
      userSelect: 'none',
      flexShrink: 0,
    }}>
      <IconButton onClick={onReset} title="Return to start (0)">
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M3 2v10M12 2L5 7l7 5V2z" stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" strokeLinecap="round"/>
        </svg>
      </IconButton>
      <IconButton onClick={onPlayPause} title="Play/pause (space)">
        {playing ? (
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <rect x="3" y="2" width="3" height="10" fill="currentColor"/>
            <rect x="8" y="2" width="3" height="10" fill="currentColor"/>
          </svg>
        ) : (
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M3 2l9 5-9 5V2z" fill="currentColor"/>
          </svg>
        )}
      </IconButton>

      {/* Current time: fixed width so it doesn't thrash */}
      <div style={{
        fontFamily: mono,
        fontSize: 12,
        fontVariantNumeric: 'tabular-nums',
        width: 64, textAlign: 'right',
        color: '#f6f4ef',
      }}>
        {fmt(time)}
      </div>

      {/* Scrub track */}
      <div
        ref={trackRef}
        onMouseMove={onTrackMove}
        onMouseLeave={onTrackLeave}
        onMouseDown={onTrackDown}
        style={{
          flex: 1,
          height: 22,
          position: 'relative',
          cursor: 'pointer',
          display: 'flex', alignItems: 'center',
        }}
      >
        <div style={{
          position: 'absolute',
          left: 0, right: 0, height: 4,
          background: 'rgba(255,255,255,0.12)',
          borderRadius: 2,
        }}/>
        <div style={{
          position: 'absolute',
          left: 0, width: `${pct}%`, height: 4,
          background: 'oklch(72% 0.12 250)',
          borderRadius: 2,
        }}/>
        <div style={{
          position: 'absolute',
          left: `${pct}%`, top: '50%',
          width: 12, height: 12,
          marginLeft: -6, marginTop: -6,
          background: '#fff',
          borderRadius: 6,
          boxShadow: '0 2px 4px rgba(0,0,0,0.4)',
        }}/>
      </div>

      {/* Duration: fixed width */}
      <div style={{
        fontFamily: mono,
        fontSize: 12,
        fontVariantNumeric: 'tabular-nums',
        width: 64, textAlign: 'left',
        color: 'rgba(246,244,239,0.55)',
      }}>
        {fmt(duration)}
      </div>
    </div>
  );
}

function IconButton({ children, onClick, title }) {
  const [hover, setHover] = React.useState(false);
  return (
    <button
      onClick={onClick}
      title={title}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        width: 28, height: 28,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: hover ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.04)',
        border: '1px solid rgba(255,255,255,0.1)',
        borderRadius: 6,
        color: '#f6f4ef',
        cursor: 'pointer',
        padding: 0,
        transition: 'background 120ms',
      }}
    >
      {children}
    </button>
  );
}


Object.assign(window, {
  Easing, interpolate, animate, clamp,
  TimelineContext, useTime, useTimeline,
  Sprite, SpriteContext, useSprite,
  TextSprite, ImageSprite, RectSprite,
  Stage, PlaybackBar,
});



// ===== TOW SCENE =====

// ===================================================================
//  DEEP DIG — Rescue Tow-Drone cutscene (portrait 540×960, 15s)
//  A tow-drone drops down the dug shaft, clamps the stranded pod,
//  and hauls it up to the surface base. Reuses the drill-scene world.
// ===================================================================

const COL = {
  void:'#06091a', sky1:'#34508f', sky2:'#16234f',
  soilTop:'#6a5e82', soilBot:'#473c5e',
  stone:'#3a4a86', stoneDk:'#2a3768',
  rock:'#4a3a78', rockDk:'#2c2050', bedrock:'#120e2c',
  pod1:'#ffe2a0', pod2:'#ffb451', pod3:'#ff9128', podStroke:'#c66a16',
  glass1:'#e6fcff', glass2:'#4fccf0', glass3:'#1f7fb8',
  steel1:'#e9edf8', steel2:'#c2cbe6', steel3:'#8a96bd', steelStroke:'#5b6890',
  cyan:'#5fe6ff', amber:'#ffb451', amberD:'#e07d1e', amberS:'#c66a16', red:'#ff6b6b',
  text:'#eaf0ff', mut:'#9fb0e8',
  mono:"'Space Mono', ui-monospace, monospace",
  disp:"'Fredoka', system-ui, sans-serif",
  ui:"'Nunito', system-ui, sans-serif",
};

const W = 540, H = 960, PPM = 1.55, PODSCREEN = 600, CAMMIN = 300;
const POD_REST = 1240;          // where the drill scene left the pod
const HANG = 90;                // drone hovers this far above pod top while towing
const CLAMP_T = 6.3;            // moment of attachment

// drone world-depth over the cutscene
const DRONE_D = interpolate(
  [0,   1.6,  5.0,  CLAMP_T, 11.6, 13.2, 15],
  [-260,-210, 1150, 1150,    -34,  -86,  -86],
  [Easing.easeInOutSine, Easing.easeInCubic, Easing.easeOutCubic, Easing.easeInOutCubic,
   Easing.easeOutBack, Easing.easeInOutSine, Easing.linear]
);
function podDepth(t){ return t < CLAMP_T ? POD_REST : DRONE_D(t) + HANG; }
function camDepth(t){ return Math.max(podDepth(t), CAMMIN); }

// ---------- POD ----------
function Pod({ t, stranded, swing }) {
  const blink = stranded ? (Math.sin(t*7)>0?1:0.15) : 0.4+0.6*Math.abs(Math.sin(t*4));
  const lightCol = stranded ? COL.red : COL.cyan;
  return (
    <div style={{position:'relative',width:76,height:118,transform:`rotate(${swing||0}deg)`,transformOrigin:'50% -28px'}}>
      <div style={{position:'absolute',left:'50%',top:0,transform:'translateX(-50%)',width:2.5,height:14,background:COL.podStroke,borderRadius:2}}/>
      <div style={{position:'absolute',left:'50%',top:-5,transform:'translateX(-50%)',width:10,height:10,borderRadius:'50%',background:lightCol,boxShadow:`0 0 12px ${lightCol}`,opacity:blink}}/>
      <div style={{position:'absolute',left:4,top:62,width:15,height:26,clipPath:'polygon(100% 0,100% 100%,0 70%)',background:`linear-gradient(180deg,${COL.pod2},${COL.amberD})`,borderRadius:3}}/>
      <div style={{position:'absolute',right:4,top:62,width:15,height:26,clipPath:'polygon(0 0,0 100%,100% 70%)',background:`linear-gradient(180deg,${COL.pod2},${COL.amberD})`,borderRadius:3}}/>
      <div style={{position:'absolute',left:'50%',top:14,transform:'translateX(-50%)',width:62,height:72,borderRadius:'31px 31px 25px 25px',background:`linear-gradient(180deg,${COL.pod1},${COL.pod2} 46%,${COL.pod3})`,border:`2.5px solid ${COL.podStroke}`,boxShadow:'inset 0 3px 0 rgba(255,255,255,.5),inset 0 -9px 13px rgba(170,75,10,.35)'}}/>
      <div style={{position:'absolute',left:'50%',top:28,transform:'translateX(-50%)',width:35,height:35,borderRadius:'50%',background:`radial-gradient(circle at 36% 28%, ${COL.glass1}, ${COL.glass2} 55%, ${COL.glass3})`,border:`2.5px solid ${COL.podStroke}`,boxShadow:'inset 0 0 0 2px rgba(255,255,255,.25)'}}/>
      <div style={{position:'absolute',left:'42%',top:32,transform:'translateX(-50%)',width:8,height:8,borderRadius:'50%',background:'rgba(255,255,255,.75)'}}/>
      <div style={{position:'absolute',left:'50%',bottom:30,transform:'translateX(-50%)',width:52,height:8,borderRadius:5,background:'linear-gradient(180deg,#c2cbe6,#8a96bd)',border:'2px solid #6c79ac'}}/>
      <div style={{position:'absolute',left:'50%',bottom:-2,transform:'translateX(-50%)',width:48,height:38,clipPath:'polygon(0 0,100% 0,50% 100%)',background:`repeating-linear-gradient(125deg,${COL.steel2} 0 6px,${COL.steel3} 6px 12px)`,borderRadius:'0 0 4px 4px'}}/>
    </div>
  );
}

// ---------- DRONE ----------
function Drone({ t, towing }) {
  const spin = (t*1500) % 360;
  const beacon = 0.4+0.6*Math.abs(Math.sin(t*5));
  const eyePulse = 0.85+0.15*Math.sin(t*3);
  const rotor = (dir) => (
    <div style={{position:'absolute',top:6,[dir<0?'left':'right']:-22,width:74,height:26,transform:'translateZ(0)'}}>
      <div style={{position:'absolute',left:'50%',top:'50%',width:2,height:14,background:COL.steel3,transform:`translate(-50%,-90%)`}}/>
      <div style={{position:'absolute',inset:0,borderRadius:'50%',background:'radial-gradient(ellipse at center, rgba(150,190,255,.05), rgba(120,170,255,.26) 88%, rgba(120,170,255,0))',transform:`rotate(${spin*dir}deg)`}}/>
      <div style={{position:'absolute',left:'50%',top:'50%',width:10,height:10,borderRadius:'50%',background:COL.steelStroke,transform:'translate(-50%,-50%)'}}/>
    </div>
  );
  return (
    <div style={{position:'relative',width:150,height:80}}>
      {rotor(-1)}{rotor(1)}
      {/* beacon */}
      <div style={{position:'absolute',left:'50%',top:-12,transform:'translateX(-50%)',width:11,height:11,borderRadius:'50%',background:COL.cyan,boxShadow:`0 0 12px ${COL.cyan}`,opacity:beacon}}/>
      <div style={{position:'absolute',left:'50%',top:-3,transform:'translateX(-50%)',width:3,height:12,background:COL.steel3}}/>
      {/* body */}
      <div style={{position:'absolute',left:'50%',top:14,transform:'translateX(-50%)',width:150,height:62,borderRadius:31,background:`linear-gradient(180deg,${COL.steel1},${COL.steel2} 50%,${COL.steel3})`,border:`2px solid ${COL.steelStroke}`,boxShadow:'0 8px 16px rgba(0,0,0,.4),inset 0 3px 0 rgba(255,255,255,.5)',overflow:'hidden'}}>
        {/* amber hazard belly */}
        <div style={{position:'absolute',left:0,right:0,bottom:0,height:24,background:`repeating-linear-gradient(115deg,${COL.amber} 0 11px,${COL.amberD} 11px 22px)`,borderTop:`2px solid ${COL.amberS}`}}/>
      </div>
      {/* cyan eye */}
      <div style={{position:'absolute',left:'50%',top:28,transform:`translateX(-50%) scale(${eyePulse})`,width:40,height:40,borderRadius:'50%',background:`radial-gradient(circle at 36% 30%, ${COL.glass1}, ${COL.glass2} 52%, ${COL.glass3})`,border:`3px solid ${COL.amberS}`,boxShadow:`0 0 16px rgba(95,230,255,.7),inset 0 0 0 2px rgba(255,255,255,.25)`}}/>
      <div style={{position:'absolute',left:'43%',top:32,transform:'translateX(-50%)',width:9,height:9,borderRadius:'50%',background:'rgba(255,255,255,.85)'}}/>
    </div>
  );
}

// magnet clamp head
function Clamp({ locked, t }) {
  const glow = locked ? 0.9 : 0.3+0.4*Math.abs(Math.sin(t*8));
  return (
    <div style={{position:'relative',width:50,height:34}}>
      <div style={{position:'absolute',left:'50%',top:0,transform:'translateX(-50%)',width:46,height:13,borderRadius:'6px 6px 2px 2px',background:`linear-gradient(180deg,${COL.steel2},${COL.steel3})`,border:`2px solid ${COL.steelStroke}`}}/>
      <div style={{position:'absolute',left:2,top:9,width:12,height:22,borderRadius:'0 0 4px 4px',background:`linear-gradient(180deg,${COL.amber},${COL.amberD})`,border:`2px solid ${COL.amberS}`}}/>
      <div style={{position:'absolute',right:2,top:9,width:12,height:22,borderRadius:'0 0 4px 4px',background:`linear-gradient(180deg,${COL.amber},${COL.amberD})`,border:`2px solid ${COL.amberS}`}}/>
      <div style={{position:'absolute',left:'50%',bottom:-3,transform:'translateX(-50%)',width:26,height:8,borderRadius:'50%',background:COL.cyan,filter:'blur(2px)',opacity:glow}}/>
    </div>
  );
}

// ---------- WORLD ----------
function TowWorld() {
  const t = useTime();
  const cam = camDepth(t);
  const dD = DRONE_D(t);
  const pD = podDepth(t);
  const towing = t >= CLAMP_T;
  const yOf = (m) => PODSCREEN + (m - cam)*PPM;

  // gentle pendulum sway while towing
  const swing = towing ? Math.sin((t-CLAMP_T)*2.2)*6*Math.max(0,1-(t-11.6)) : 0;
  const swingX = towing ? Math.sin((t-CLAMP_T)*2.2)*10*Math.max(0,1-(t-11.6)*0.7) : 0;

  // clamp lands on pod top during attach window
  const podTopD = pD - 64/PPM;        // pod top in world depth-ish
  const droneBotD = dD + 52/PPM;
  let clampD;
  if (t < 5.0) clampD = droneBotD + 30/PPM;
  else if (t < CLAMP_T) clampD = droneBotD + (podTopD-droneBotD)*Easing.easeInOutCubic((t-5.0)/(CLAMP_T-5.0));
  else clampD = podTopD;

  const droneX = W/2 + (towing? swingX*0.35 : 0);
  const podX   = W/2 + swingX;
  const clampX = W/2 + (towing? swingX : swingX*0.5);

  const droneY = yOf(dD);
  const podY   = yOf(pD);
  const clampY = yOf(clampD);

  const surfaceY = yOf(0);

  // impact flash at clamp moment
  const clampFlash = Math.max(0, 1 - Math.abs(t-CLAMP_T)/0.35);

  const stars=[[0.16,-60],[0.72,-120],[0.46,-40],[0.86,-150],[0.30,-200],[0.60,-260]];
  const deco=[{x:0.78,m:250},{x:0.20,m:600},{x:0.82,m:1020}];

  const terrainGrad = `linear-gradient(180deg,
    ${COL.soilTop} 0%, ${COL.soilBot} 12.5%, ${COL.stone} 14%,
    ${COL.stoneDk} 40%, ${COL.rock} 53%, ${COL.rockDk} 78%,
    ${COL.bedrock} 83%, ${COL.bedrock} 100%)`;

  return (
    <div style={{position:'absolute',inset:0,overflow:'hidden',background:`linear-gradient(180deg,${COL.sky1} 0%,${COL.sky2} 58%,${COL.void} 100%)`}}>

      {/* stars (only above surface) */}
      {stars.map((s,i)=>{ const sy=yOf(s[1]); if(sy<-10||sy>surfaceY) return null;
        return <div key={'st'+i} style={{position:'absolute',left:s[0]*W,top:sy,width:3,height:3,borderRadius:'50%',background:'#fff',opacity:0.4+0.6*Math.abs(Math.sin(t*2+i)),transform:'translate(-50%,-50%)'}}/>; })}

      {/* terrain */}
      <div style={{position:'absolute',left:-40,right:-40,top:surfaceY,height:1700*PPM,background:terrainGrad}}/>
      <div style={{position:'absolute',left:-40,right:-40,top:surfaceY,height:1700*PPM,opacity:0.5,backgroundImage:'radial-gradient(circle at 20% 8%, rgba(255,255,255,.07) 2px, transparent 3px),radial-gradient(circle at 68% 17%, rgba(0,0,0,.22) 2px, transparent 3px),radial-gradient(circle at 44% 30%, rgba(160,200,255,.08) 2px, transparent 3px),radial-gradient(circle at 82% 40%, rgba(0,0,0,.2) 2px, transparent 3px)',backgroundSize:'120px 120px'}}/>
      <div style={{position:'absolute',left:0,right:0,top:surfaceY,height:7,background:'linear-gradient(180deg,rgba(255,255,255,.16),rgba(0,0,0,.15))'}}/>

      {/* the dug shaft — from surface down to the pod's resting depth */}
      <div style={{position:'absolute',left:'50%',transform:'translateX(-50%)',top:surfaceY,width:92,height:Math.max(0,yOf(POD_REST+30)-surfaceY),background:'linear-gradient(180deg,rgba(6,8,22,.30) 0%,rgba(6,8,22,.6) 40%,rgba(6,8,22,.72) 100%)',borderRadius:'0 0 46px 46px',boxShadow:'inset 0 0 26px rgba(0,0,0,.5)'}}/>

      {/* embedded deco gems */}
      {deco.map((g,i)=>{ const gy=yOf(g.m); if(gy<-40||gy>H+40) return null;
        return (<div key={'d'+i} style={{position:'absolute',left:g.x*W,top:gy,transform:'translate(-50%,-50%)',width:30,height:39,filter:'drop-shadow(0 0 10px rgba(95,230,255,.7))'}}>
          <div style={{position:'absolute',inset:0,clipPath:'polygon(50% 0,100% 35%,50% 100%,0 35%)',background:'linear-gradient(160deg,#b6f6ff,#33bdec 55%,#1879c0)'}}/>
          <div style={{position:'absolute',inset:0,clipPath:'polygon(50% 0,100% 35%,0 35%)',background:'#dafbff',opacity:.85}}/>
        </div>); })}

      {/* ===== SURFACE BASE (scrolls in near the end) ===== */}
      <div style={{position:'absolute',left:0,right:0,top:surfaceY-6,display:surfaceY>-80&&surfaceY<H+120?'block':'none'}}>
        {/* landing pad */}
        <div style={{position:'absolute',left:'50%',top:-26,transform:'translateX(-50%)',width:184,height:30,borderRadius:'14px 14px 6px 6px',background:'linear-gradient(180deg,#46538c,#2b3566)',border:'2px solid #5b6aa0',boxShadow:'0 -4px 14px rgba(95,230,255,.18)'}}/>
        <div style={{position:'absolute',left:'50%',top:-22,transform:'translateX(-50%)',width:150,height:6,borderRadius:4,background:'repeating-linear-gradient(90deg,#ffd574 0 14px,#2b3566 14px 24px)'}}/>
        {/* pad beacons */}
        <div style={{position:'absolute',left:'calc(50% - 84px)',top:-30,width:8,height:8,borderRadius:'50%',background:COL.cyan,boxShadow:`0 0 8px ${COL.cyan}`,opacity:0.5+0.5*Math.abs(Math.sin(t*4))}}/>
        <div style={{position:'absolute',left:'calc(50% + 76px)',top:-30,width:8,height:8,borderRadius:'50%',background:COL.cyan,boxShadow:`0 0 8px ${COL.cyan}`,opacity:0.5+0.5*Math.abs(Math.sin(t*4+1))}}/>
        {/* little base hut + flag, to the side */}
        <div style={{position:'absolute',left:'calc(50% + 104px)',top:-44,width:56,height:38,borderRadius:'12px 12px 4px 4px',background:'linear-gradient(180deg,#5a6699,#39437a)',border:'2px solid #6b78ad'}}/>
        <div style={{position:'absolute',left:'calc(50% + 120px)',top:-30,width:22,height:16,borderRadius:4,background:`radial-gradient(circle at 40% 35%,${COL.glass1},${COL.glass2} 60%,${COL.glass3})`,border:`2px solid ${COL.steelStroke}`}}/>
        <div style={{position:'absolute',left:'calc(50% - 150px)',top:-74,width:3,height:48,background:'#6b78ad'}}/>
        <div style={{position:'absolute',left:'calc(50% - 147px)',top:-74,width:30,height:20,clipPath:'polygon(0 0,100% 12%,86% 100%,0 80%)',background:COL.amber}}/>
      </div>

      {/* ===== CABLE (drone bottom → clamp) ===== */}
      <svg style={{position:'absolute',inset:0,width:'100%',height:'100%',pointerEvents:'none'}}>
        <line x1={droneX} y1={droneY+38} x2={clampX} y2={clampY-12} stroke="#7a86b4" strokeWidth="3" strokeLinecap="round"/>
        <line x1={droneX} y1={droneY+38} x2={clampX} y2={clampY-12} stroke="rgba(255,255,255,.25)" strokeWidth="1"/>
      </svg>

      {/* ===== POD ===== */}
      <div style={{position:'absolute',left:podX,top:podY,transform:'translate(-50%,-50%)'}}>
        <Pod t={t} stranded={!towing} swing={swing}/>
      </div>

      {/* ===== CLAMP ===== */}
      <div style={{position:'absolute',left:clampX,top:clampY,transform:'translate(-50%,-50%)'}}>
        <Clamp locked={towing} t={t}/>
      </div>
      {clampFlash>0 && <div style={{position:'absolute',left:clampX-40,top:clampY-40,width:80,height:80,borderRadius:'50%',background:'radial-gradient(circle,rgba(255,255,255,.8),transparent 60%)',opacity:clampFlash*0.7,transform:`scale(${0.5+clampFlash})`}}/>}

      {/* ===== DRONE ===== */}
      <div style={{position:'absolute',left:droneX,top:droneY,transform:'translate(-50%,-50%)'}}>
        <Drone t={t} towing={towing}/>
      </div>

      {/* engine downwash dust when drone near pod */}
      {Math.abs(t-CLAMP_T)<1.4 && [...Array(6)].map((_,i)=>{
        const ph=((t*1.6)+i/6)%1; const dir=i%2?1:-1;
        return <div key={'dw'+i} style={{position:'absolute',left:clampX+dir*(8+ph*26),top:clampY+ph*30,width:7*(1-ph),height:7*(1-ph),borderRadius:'50%',background:'#6a5e88',opacity:(1-ph)*0.6,transform:'translate(-50%,-50%)'}}/>;
      })}
    </div>
  );
}

// ---------- caption banner ----------
function Caption() {
  const t = useTime();
  let txt='', sub='', col=COL.red;
  if (t < 1.8){ txt='DISTRESS BEACON'; sub='Out of fuel · 1,240m'; col=COL.red; }
  else if (t < 5.2){ txt='TOW-DRONE INBOUND'; sub='Descending the shaft'; col=COL.cyan; }
  else if (t < 6.6){ txt='CLAMP LOCKED'; sub='Magnet engaged'; col=COL.amber; }
  else if (t < 11.4){ txt='HAULING TO BASE'; sub='Hang tight, miner'; col=COL.cyan; }
  else { txt='RESCUED!'; sub='Welcome home'; col='#62f0a8'; }
  // fade between phases
  const edges=[0,1.8,5.2,6.6,11.4,15];
  let near=1; for(const e of edges){ const d=Math.abs(t-e); if(d<0.3) near=Math.min(near,d/0.3); }
  return (
    <div style={{position:'absolute',top:30,left:0,right:0,textAlign:'center',opacity:near,pointerEvents:'none'}}>
      <div style={{display:'inline-block',padding:'10px 24px',borderRadius:18,background:'rgba(7,11,30,.66)',border:'1px solid rgba(150,170,255,.2)',backdropFilter:'blur(4px)',whiteSpace:'nowrap'}}>
        <div style={{fontFamily:COL.disp,fontWeight:700,fontSize:22,lineHeight:1.1,color:col,letterSpacing:.5,textShadow:`0 0 14px ${col}66`,whiteSpace:'nowrap'}}>{txt}</div>
        <div style={{fontFamily:COL.ui,fontWeight:700,fontSize:11,lineHeight:1.2,letterSpacing:2,color:COL.mut,marginTop:4,textTransform:'uppercase',whiteSpace:'nowrap'}}>{sub}</div>
      </div>
    </div>
  );
}

function Vignette(){
  const t=useTime(); const deep=clamp((podDepth(t)-300)/940,0,1);
  return <div style={{position:'absolute',inset:0,pointerEvents:'none',background:`radial-gradient(125% 95% at 50% 42%, transparent 40%, rgba(4,6,16,${0.20+0.4*deep}) 100%)`}}/>;
}

// arrival sparkle burst
function ArrivalFX(){
  const { localTime, duration } = useSprite();
  const p = clamp(localTime/duration,0,1);
  const op = Math.min(clamp(localTime/0.2,0,1), 1-clamp((localTime-1.2)/(duration-1.2),0,1));
  const cx=W/2, cy=PODSCREEN + (podDepth(11.7+localTime)-camDepth(11.7+localTime))*PPM;
  const parts=[];
  for(let i=0;i<14;i++){ const a=(i/14)*Math.PI*2; const d=p*90; const sz=8*(1-p);
    parts.push(<div key={i} style={{position:'absolute',left:cx+Math.cos(a)*d,top:(cy||140)+Math.sin(a)*d,width:sz,height:sz,clipPath:'polygon(50% 0,61% 39%,100% 50%,61% 61%,50% 100%,39% 61%,0 50%,39% 39%)',background:i%2?'#62f0a8':'#5fe6ff',opacity:(1-p)*op,transform:'translate(-50%,-50%)'}}/>); }
  return <div style={{position:'absolute',inset:0,pointerEvents:'none'}}>{parts}</div>;
}

function TowScene() {
  return (
    <Stage width={540} height={960} duration={15} background={COL.void} persistKey="deepdig-tow">
      <TowWorld/>
      <Vignette/>
      <Sprite start={11.6} end={14}><ArrivalFX/></Sprite>
      <Caption/>
    </Stage>
  );
}

window.TowScene = TowScene;
try { module.exports = { TowScene }; } catch (e) {}
