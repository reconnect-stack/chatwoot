// Prefix that turns a stored icon name (e.g. "rocket-line") into a class.
// Swapping icon libraries means changing this and the curated set only.
export const ICON_PREFIX = 'i-ri-';

export const ICON_STYLE = {
  LINE: 'line',
  FILL: 'fill',
};

// Icon values are ascii names (e.g. "rocket-line"); emoji are non-ascii.
export const isIconValue = value =>
  typeof value === 'string' && /^[a-z][a-z0-9-]*$/.test(value);

export const iconClassFor = value =>
  value.startsWith(ICON_PREFIX) ? value : `${ICON_PREFIX}${value}`;

export const ICON_COLORS = [
  { name: 'Slate', value: '#64748B' },
  { name: 'Red', value: '#EF4444' },
  { name: 'Orange', value: '#F97316' },
  { name: 'Amber', value: '#F59E0B' },
  { name: 'Green', value: '#22C55E' },
  { name: 'Teal', value: '#14B8A6' },
  { name: 'Blue', value: '#3B82F6' },
  { name: 'Indigo', value: '#6366F1' },
  { name: 'Violet', value: '#8B5CF6' },
  { name: 'Pink', value: '#EC4899' },
];

export const DEFAULT_ICON_COLOR = '#3B82F6';

// Recently used emojis persisted in localStorage.
export const RECENT_EMOJI_KEY = 'emoji-icon-picker.recent-emojis';
export const MAX_RECENT_EMOJIS = 16;

export const PICKER_MODE = {
  BOTH: 'both',
  EMOJI: 'emoji',
};

export const PICKER_TAB = {
  ICONS: 'icons',
  EMOJIS: 'emojis',
};
