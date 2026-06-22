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



// ===== SCENE =====

// ===================================================================
//  DEEP DIG — Drilling gameplay-loop animation (portrait 540×960, 20s)
//  Composes the animations.jsx engine (Stage / Sprite / interpolate…)
// ===================================================================

const COL = {
  void:'#06091a', sky1:'#34508f', sky2:'#16234f',
  soilTop:'#6a5e82', soilBot:'#473c5e',
  stone:'#3a4a86', stoneDk:'#2a3768',
  rock:'#4a3a78', rockDk:'#2c2050', bedrock:'#120e2c',
  pod1:'#ffe2a0', pod2:'#ffb451', pod3:'#ff9128', podStroke:'#c66a16',
  glass1:'#e6fcff', glass2:'#4fccf0', glass3:'#1f7fb8',
  steel1:'#dde3f2', steel2:'#9aa6cc',
  cyan:'#5fe6ff', green:'#62f0a8', amber:'#ffb33c', purple:'#b58cff', pink:'#ff7bb0',
  text:'#eaf0ff', mut:'#9fb0e8',
  mono:"'Space Mono', ui-monospace, monospace",
  disp:"'Fredoka', system-ui, sans-serif",
  ui:"'Nunito', system-ui, sans-serif",
};

const GEM = {
  green:{light:'#bff7d8',mid:'#54e39a',dark:'#1f9e63',glow:'rgba(98,240,168,.85)',top:'#d9fcea',shade:'rgba(8,60,40,.25)'},
  purple:{light:'#e0ccff',mid:'#a877ff',dark:'#6f3fd6',glow:'rgba(181,140,255,.95)',top:'#efe4ff',shade:'rgba(40,12,70,.25)'},
  amber:{light:'#ffe9a8',mid:'#ffb33c',dark:'#d6841a',glow:'rgba(255,200,80,.85)',top:'#fff1c2',shade:'rgba(70,40,8,.22)'},
  pink:{light:'#ffc2dd',mid:'#ff6fa9',dark:'#cf3f78',glow:'rgba(255,123,176,.85)',top:'#ffd9e9',shade:'rgba(70,12,40,.22)'},
};

// depth in meters over time
const DEPTH = interpolate(
  [0, 2.5, 7, 8.4, 14, 15.6, 19, 20],
  [0,   4, 400, 400, 880, 880, 1240, 1240],
  [Easing.easeInSine, Easing.easeInQuad, Easing.easeOutQuad, Easing.linear,
   Easing.easeInOutSine, Easing.linear, Easing.easeOutCubic, Easing.linear]
);
const CASH = interpolate([0,7,7.7,14,14.9,20],[12480,12480,12555,12555,13455,13455], Easing.easeOutCubic);
const FUEL = interpolate([0,2.5,19,20],[68,68,49,49]);

const W = 540, H = 960, PODY = 388, PPM = 1.55;

// ---------- building-block sprites ----------

function Gem({ size=60, pal }) {
  const w = size, h = size*1.3;
  return (
    <div style={{position:'relative',width:w,height:h,filter:`drop-shadow(0 0 ${size*0.26}px ${pal.glow})`}}>
      <div style={{position:'absolute',inset:0,clipPath:'polygon(50% 0,100% 35%,50% 100%,0 35%)',background:`linear-gradient(160deg,${pal.light},${pal.mid} 55%,${pal.dark})`}}/>
      <div style={{position:'absolute',inset:0,clipPath:'polygon(50% 0,100% 35%,0 35%)',background:pal.top,opacity:.85}}/>
      <div style={{position:'absolute',inset:0,clipPath:'polygon(0 35%,50% 35%,50% 100%)',background:pal.shade}}/>
      <div style={{position:'absolute',left:'50%',top:0,width:2,height:'100%',background:'rgba(255,255,255,.5)',transform:'translateX(-50%)'}}/>
    </div>
  );
}

function Pod({ t, drilling }) {
  const sx = drilling ? Math.sin(t*55)*1.7 : 0;
  const blink = 0.35 + 0.65*Math.abs(Math.sin(t*5));
  return (
    <div style={{position:'relative',width:76,height:118}}>
      <div style={{position:'absolute',left:'50%',top:0,transform:'translateX(-50%)',width:2.5,height:14,background:COL.podStroke,borderRadius:2}}/>
      <div style={{position:'absolute',left:'50%',top:-5,transform:'translateX(-50%)',width:10,height:10,borderRadius:'50%',background:COL.cyan,boxShadow:`0 0 12px ${COL.cyan}`,opacity:blink}}/>
      <div style={{position:'absolute',left:4,top:62,width:15,height:26,clipPath:'polygon(100% 0,100% 100%,0 70%)',background:`linear-gradient(180deg,${COL.pod2},#e07d1e)`,borderRadius:3}}/>
      <div style={{position:'absolute',right:4,top:62,width:15,height:26,clipPath:'polygon(0 0,0 100%,100% 70%)',background:`linear-gradient(180deg,${COL.pod2},#e07d1e)`,borderRadius:3}}/>
      <div style={{position:'absolute',left:'50%',top:14,transform:'translateX(-50%)',width:62,height:72,borderRadius:'31px 31px 25px 25px',background:`linear-gradient(180deg,${COL.pod1},${COL.pod2} 46%,${COL.pod3})`,border:`2.5px solid ${COL.podStroke}`,boxShadow:'inset 0 3px 0 rgba(255,255,255,.5),inset 0 -9px 13px rgba(170,75,10,.35)'}}/>
      <div style={{position:'absolute',left:'50%',top:28,transform:'translateX(-50%)',width:35,height:35,borderRadius:'50%',background:`radial-gradient(circle at 36% 28%, ${COL.glass1}, ${COL.glass2} 55%, ${COL.glass3})`,border:`2.5px solid ${COL.podStroke}`,boxShadow:'inset 0 0 0 2px rgba(255,255,255,.25)'}}/>
      <div style={{position:'absolute',left:'42%',top:32,transform:'translateX(-50%)',width:8,height:8,borderRadius:'50%',background:'rgba(255,255,255,.75)'}}/>
      <div style={{position:'absolute',left:'50%',bottom:30,transform:'translateX(-50%)',width:52,height:8,borderRadius:5,background:'linear-gradient(180deg,#c2cbe6,#8a96bd)',border:'2px solid #6c79ac'}}/>
      <div style={{position:'absolute',left:'50%',bottom:-2,transform:`translateX(calc(-50% + ${sx}px))`,width:48,height:38,clipPath:'polygon(0 0,100% 0,50% 100%)',background:`repeating-linear-gradient(125deg,${COL.steel1} 0 6px,${COL.steel2} 6px 12px)`,borderRadius:'0 0 4px 4px'}}/>
    </div>
  );
}

function Dust({ t, x, y }) {
  const parts = [];
  for (let i=0;i<8;i++){
    const ph = ((t*1.7) + i/8) % 1;
    const dir = i%2 ? 1 : -1;
    const px = x + dir*(6 + ph*30) + (i*2-8);
    const py = y + ph*34;
    const sz = 8*(1 - ph*0.6);
    parts.push(<div key={i} style={{position:'absolute',left:px,top:py,width:sz,height:sz,borderRadius:'50%',background:i%3?'#6a5e88':'#5a5078',opacity:(1-ph)*0.85,transform:'translate(-50%,-50%)'}}/>);
  }
  return <React.Fragment>{parts}</React.Fragment>;
}

// ---------- the dig world (camera follows pod) ----------

function DigWorld() {
  const t = useTime();
  const depth = DEPTH(t);
  const vel = DEPTH(t+0.06) - DEPTH(t-0.06);
  const drilling = vel > 1.2;
  const surfaceY = PODY - depth*PPM;
  const yOf = (m) => PODY + (m - depth)*PPM;

  const shakeAt = (tc) => { const d = Math.abs(t-tc); return d<0.5 ? Math.sin(t*70)*(0.5-d)*9 : 0; };
  const camShake = shakeAt(7.0) + shakeAt(14.0);

  const collect = [
    {x:0.31, m:400, tc:7.0, pal:GEM.green, s:50},
    {x:0.69, m:880, tc:14.0, pal:GEM.purple, s:58},
  ];
  const deco = [
    {x:0.76, m:250, pal:GEM.amber, s:30},
    {x:0.20, m:600, pal:GEM.pink, s:28},
    {x:0.80, m:1030, pal:GEM.green, s:30},
    {x:0.22, m:1150, pal:GEM.amber, s:26},
  ];
  const stars = [{x:0.18,m:-60},{x:0.72,m:-110},{x:0.46,m:-40},{x:0.86,m:-150},{x:0.32,m:-180}];

  const terrainGrad = `linear-gradient(180deg,
    ${COL.soilTop} 0%, ${COL.soilBot} 12.5%, ${COL.stone} 14%,
    ${COL.stoneDk} 40%, ${COL.rock} 53%, ${COL.rockDk} 78%,
    ${COL.bedrock} 83%, ${COL.bedrock} 100%)`;

  return (
    <div style={{position:'absolute',inset:0,overflow:'hidden',background:`linear-gradient(180deg,${COL.sky1} 0%,${COL.sky2} 60%,${COL.void} 100%)`,transform:`translateY(${camShake}px)`}}>

      {stars.map((s,i)=>{
        const sy = yOf(s.m);
        if (sy < -10 || sy > surfaceY) return null;
        return <div key={'st'+i} style={{position:'absolute',left:s.x*W,top:sy,width:3,height:3,borderRadius:'50%',background:'#fff',opacity:0.4+0.6*Math.abs(Math.sin(t*2+i)),transform:'translate(-50%,-50%)'}}/>;
      })}

      {/* terrain */}
      <div style={{position:'absolute',left:-40,right:-40,top:surfaceY,height:1600*PPM,background:terrainGrad}}/>
      {/* speckle layer */}
      <div style={{position:'absolute',left:-40,right:-40,top:surfaceY,height:1600*PPM,opacity:0.5,backgroundImage:'radial-gradient(circle at 20% 8%, rgba(255,255,255,.07) 2px, transparent 3px),radial-gradient(circle at 68% 17%, rgba(0,0,0,.22) 2px, transparent 3px),radial-gradient(circle at 44% 30%, rgba(160,200,255,.08) 2px, transparent 3px),radial-gradient(circle at 82% 40%, rgba(0,0,0,.2) 2px, transparent 3px)',backgroundSize:'120px 120px'}}/>
      {/* surface highlight */}
      <div style={{position:'absolute',left:0,right:0,top:surfaceY,height:7,background:'linear-gradient(180deg,rgba(255,255,255,.16),rgba(0,0,0,.15))'}}/>

      {/* carved tunnel above pod */}
      <div style={{position:'absolute',left:'50%',transform:'translateX(-50%)',top:Math.max(-30,surfaceY),width:86,height:Math.max(0,(PODY+10)-Math.max(-30,surfaceY)),background:'linear-gradient(180deg,rgba(6,8,22,0) 0%,rgba(6,8,22,.5) 30%,rgba(6,8,22,.66) 100%)',borderRadius:'0 0 44px 44px',boxShadow:'inset 0 0 24px rgba(0,0,0,.45)'}}/>

      {/* decorative embedded gems */}
      {deco.map((g,i)=>{
        const gy = yOf(g.m);
        if (gy < -40 || gy > H+40) return null;
        return <div key={'d'+i} style={{position:'absolute',left:g.x*W,top:gy,transform:'translate(-50%,-50%)'}}><Gem size={g.s} pal={g.pal}/></div>;
      })}

      {/* collectible gems (disappear once collected) */}
      {collect.map((g,i)=>{
        if (t >= g.tc) return null;
        const gy = yOf(g.m);
        const pop = t > g.tc-0.4 ? 1 + (t-(g.tc-0.4))/0.4*0.4 : 1;
        return <div key={'c'+i} style={{position:'absolute',left:g.x*W,top:gy,transform:`translate(-50%,-50%) scale(${pop})`}}><Gem size={g.s} pal={g.pal}/></div>;
      })}

      {/* the pod */}
      <div style={{position:'absolute',left:W/2,top:PODY,transform:'translate(-50%,-50%)'}}><Pod t={t} drilling={drilling}/></div>
      {drilling && <Dust t={t} x={W/2} y={PODY+58}/>}
    </div>
  );
}

function Vignette(){
  const t = useTime();
  const deep = clamp((DEPTH(t)-300)/940,0,1);
  return <div style={{position:'absolute',inset:0,pointerEvents:'none',background:`radial-gradient(125% 95% at 50% 42%, transparent 38%, rgba(4,6,16,${0.22+0.4*deep}) 100%)`}}/>;
}

// ---------- collect burst + popup ----------

function CollectFX({ x, pal, value, label, color }) {
  const { localTime, duration } = useSprite();
  const p = clamp(localTime/duration,0,1);
  const burst = Easing.easeOutCubic(clamp(localTime/0.55,0,1));
  const up = -78*Easing.easeOutCubic(clamp(localTime/1.0,0,1));
  const opIn = clamp(localTime/0.15,0,1);
  const opOut = 1 - clamp((localTime-0.9)/(duration-0.9),0,1);
  const op = Math.min(opIn, opOut);
  const flash = clamp(1 - localTime/0.22, 0, 1);

  const rays = [];
  for (let i=0;i<10;i++){
    const a = (i/10)*Math.PI*2;
    const dist = burst*52;
    const sz = 9*(1-burst);
    rays.push(<div key={i} style={{position:'absolute',left:x+Math.cos(a)*dist,top:PODY+Math.sin(a)*dist,width:sz,height:sz,borderRadius:'50%',background:color,boxShadow:`0 0 8px ${color}`,opacity:(1-burst),transform:'translate(-50%,-50%)'}}/>);
  }

  return (
    <div style={{position:'absolute',inset:0,pointerEvents:'none'}}>
      <div style={{position:'absolute',left:x,top:PODY,width:140,height:140,marginLeft:-70,marginTop:-70,borderRadius:'50%',background:`radial-gradient(circle, ${color} 0%, transparent 60%)`,opacity:0.45*(1-burst),transform:`scale(${0.4+burst})`}}/>
      {rays}
      <div style={{position:'absolute',inset:0,background:'#fff',opacity:flash*0.18}}/>
      <div style={{position:'absolute',left:x,top:PODY-18,transform:`translate(-50%,${up}px)`,opacity:op,textAlign:'center',whiteSpace:'nowrap'}}>
        <div style={{fontFamily:COL.mono,fontWeight:700,fontSize:34,color:color,textShadow:`0 0 16px ${pal.glow}, 0 2px 0 rgba(0,0,0,.4)`}}>{value}</div>
        <div style={{fontFamily:COL.ui,fontWeight:800,fontSize:11,letterSpacing:2,color:COL.text,marginTop:2,opacity:.9}}>{label}</div>
      </div>
    </div>
  );
}

// ---------- HUD ----------

function Hud() {
  const t = useTime();
  const cash = Math.round(CASH(t)).toLocaleString();
  const depth = Math.round(DEPTH(t)).toLocaleString();
  const fuel = FUEL(t);
  const lit = Math.round(fuel/100*8);
  const cargo = 18 + (t>=7?1:0) + (t>=14?1:0);
  const appear = clamp((t-0.4)/0.6,0,1);

  const segs = [];
  for (let i=0;i<8;i++){
    let c = 'rgba(255,255,255,.13)';
    if (i<lit) c = i===0 ? '#ff6b6b' : i===1 ? '#ffb33c' : '#ffd574';
    segs.push(<span key={i} style={{width:7,height:22,borderRadius:3,background:c,boxShadow:i<lit?`0 0 6px ${c}`:'none'}}/>);
  }

  const pill = {display:'flex',alignItems:'center',gap:8,padding:'9px 16px',borderRadius:20,background:'rgba(7,11,30,.66)',border:'1px solid rgba(150,170,255,.2)',backdropFilter:'blur(4px)'};

  return (
    <div style={{position:'absolute',inset:0,pointerEvents:'none',opacity:appear,transform:`translateY(${(1-appear)*-12}px)`}}>
      {/* top bar */}
      <div style={{position:'absolute',top:22,left:22,right:22,display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <div style={pill}>
          <div style={{width:26,height:26,borderRadius:'50%',background:'radial-gradient(circle at 36% 28%, #ffe89a,#f0a92e)',boxShadow:'inset 0 0 0 2.5px rgba(180,120,20,.5)',position:'relative'}}>
            <span style={{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',fontFamily:COL.disp,fontWeight:700,fontSize:14,color:'#9c5f12'}}>$</span>
          </div>
          <span style={{fontFamily:COL.mono,fontWeight:700,fontSize:20,color:'#ffd574'}}>{cash}</span>
        </div>
        <div style={pill}>
          <span style={{color:COL.cyan,fontSize:16,transform:'translateY(1px)'}}>▾</span>
          <span style={{fontFamily:COL.mono,fontWeight:700,fontSize:20,color:'#cfe0ff'}}>{depth}<span style={{fontFamily:COL.ui,fontSize:13,color:COL.mut}}>m</span></span>
        </div>
      </div>

      {/* bottom bar */}
      <div style={{position:'absolute',bottom:30,left:22,right:22,display:'flex',justifyContent:'space-between',alignItems:'flex-end'}}>
        <div style={{display:'flex',flexDirection:'column',gap:12}}>
          <div style={{display:'flex',alignItems:'center',gap:9}}>
            <span style={{fontFamily:COL.ui,fontWeight:800,fontSize:11,letterSpacing:2,color:COL.mut,width:46}}>FUEL</span>
            <div style={{display:'flex',gap:4}}>{segs}</div>
          </div>
          <div style={{display:'flex',alignItems:'center',gap:9}}>
            <span style={{fontFamily:COL.ui,fontWeight:800,fontSize:11,letterSpacing:2,color:COL.mut,width:46}}>CARGO</span>
            <div style={{width:128,height:11,borderRadius:6,background:'rgba(255,255,255,.13)',overflow:'hidden'}}>
              <div style={{width:`${cargo/24*100}%`,height:'100%',background:'linear-gradient(90deg,#5fe6ff,#46c8ee)',boxShadow:'0 0 8px rgba(95,230,255,.5)',transition:'width .4s ease'}}/>
            </div>
            <span style={{fontFamily:COL.mono,fontWeight:700,fontSize:12,color:COL.mut}}>{cargo}/24</span>
          </div>
        </div>
        {/* joystick */}
        <div style={{width:64,height:64,borderRadius:'50%',background:'rgba(7,11,30,.5)',border:'1px solid rgba(150,170,255,.2)',position:'relative'}}>
          <div style={{position:'absolute',left:'50%',top:'50%',transform:'translate(-50%,-50%)',width:28,height:28,borderRadius:'50%',background:'rgba(150,170,255,.22)',boxShadow:'inset 0 1px 0 rgba(255,255,255,.2)'}}/>
        </div>
      </div>
    </div>
  );
}

// ---------- root ----------

function DrillScene() {
  return (
    <Stage width={540} height={960} duration={20} background={COL.void} persistKey="deepdig-drill">
      <DigWorld/>
      <Vignette/>
      <Hud/>
      <Sprite start={7.0} end={8.9}><CollectFX x={0.31*W} pal={GEM.green} color={COL.green} value="+75" label="VERDIL"/></Sprite>
      <Sprite start={14.0} end={16.0}><CollectFX x={0.69*W} pal={GEM.purple} color={COL.purple} value="+$9.00" label="VOIDSTONE"/></Sprite>
    </Stage>
  );
}

window.DrillScene = DrillScene;
try { module.exports = { DrillScene }; } catch (e) {}
