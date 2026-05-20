# Viewport

### ✅ CSS Viewport Height Units – Use These Instead of `vh`

| Unit  | Meaning                     | Best Use Case                              |
| ----- | --------------------------- | ------------------------------------------ |
| `vh`  | 1% of **viewport height**   | ❌ Problematic on mobile (UI bars ignored) |
| `dvh` | **Dynamic** Viewport Height | ✅ Mobile apps, full-height menus          |
| `svh` | **Small** Viewport Height   | ✅ Landing pages, avoids layout shifts     |
| `lvh` | **Large** Viewport Height   | ❌ Like `vh`, ignores mobile UI changes    |

______________________________________________________________________

### 🔁 Fallback Strategy (for older browsers)

```css
height: 100vh;
height: 100dvh; /* Overrides if supported */
```

______________________________________________________________________

### ⚠️ Notes

- `dvh` adapts to UI bars (good, but may cause small layout shifts).
- `svh` avoids shifts but always assumes UI bars are present.
- `lvh` ignores UI bars entirely (similar to old `vh`).
- **Keyboard overlays are *not* considered** by any of these units.
