import emojiGroups from 'shared/components/emoji/emojisGroup.json';
import { MAX_RECENT_EMOJIS, RECENT_EMOJI_KEY } from './constants';

const matchesSearch = (emoji, term) =>
  emoji.slug.replaceAll('_', ' ').includes(term) ||
  emoji.name.toLowerCase().includes(term);

// Emoji sections for the search term; prepends "Frequently used" when idle.
export const buildEmojiSections = (search, recentEmojis, frequentLabel) => {
  const term = search.trim().toLowerCase();

  if (term) {
    return emojiGroups
      .map(group => ({
        name: group.name,
        emojis: group.emojis.filter(emoji => matchesSearch(emoji, term)),
      }))
      .filter(group => group.emojis.length > 0);
  }

  const sections = [];
  if (recentEmojis.length) {
    sections.push({ name: frequentLabel, emojis: recentEmojis });
  }
  emojiGroups.forEach(group =>
    sections.push({ name: group.name, emojis: group.emojis })
  );
  return sections;
};

// Samples an emoji's average color (via canvas) as a translucent hover tint.
// Cached per emoji; falls back to a neutral tint.
const emojiTintCache = new Map();
export const getEmojiTint = emoji => {
  if (emojiTintCache.has(emoji)) return emojiTintCache.get(emoji);

  let tint = 'rgb(var(--slate-9) / 0.12)';
  try {
    const canvas = document.createElement('canvas');
    canvas.width = 16;
    canvas.height = 16;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });
    ctx.font = '14px serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(emoji, 8, 9);

    const { data } = ctx.getImageData(0, 0, 16, 16);
    let r = 0;
    let g = 0;
    let b = 0;
    let count = 0;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] > 16) {
        r += data[i];
        g += data[i + 1];
        b += data[i + 2];
        count += 1;
      }
    }
    if (count) {
      tint = `rgba(${Math.round(r / count)}, ${Math.round(g / count)}, ${Math.round(b / count)}, 0.16)`;
    }
  } catch (error) {
    // Canvas unavailable; keep the neutral fallback tint.
  }

  emojiTintCache.set(emoji, tint);
  return tint;
};

export const getRecentEmojis = () => {
  try {
    const stored = JSON.parse(
      window.localStorage.getItem(RECENT_EMOJI_KEY) || '[]'
    );
    return Array.isArray(stored) ? stored : [];
  } catch (error) {
    return [];
  }
};

export const addRecentEmoji = emoji => {
  const existing = getRecentEmojis().filter(item => item.slug !== emoji.slug);
  const updated = [emoji, ...existing].slice(0, MAX_RECENT_EMOJIS);
  try {
    window.localStorage.setItem(RECENT_EMOJI_KEY, JSON.stringify(updated));
  } catch (error) {
    // localStorage may be unavailable (private mode); recents are best-effort.
  }
  return updated;
};
