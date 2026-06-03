// Lazy component loaders for every *.story.vue file under app/javascript.
const storyModules = import.meta.glob('../**/*.story.vue');

// Raw sources, eagerly loaded, so we can read each story's title without
// instantiating the (potentially heavy) component just to build the sidebar.
const storySources = import.meta.glob('../**/*.story.vue', {
  query: '?raw',
  import: 'default',
  eager: true,
});

function parseTitle(source) {
  const match = source.match(/<Story\b[^>]*?\btitle\s*=\s*"([^"]+)"/);
  return match ? match[1] : null;
}

export const stories = Object.keys(storyModules)
  .map(filePath => ({
    path: filePath,
    title: parseTitle(storySources[filePath] || ''),
    loader: storyModules[filePath],
  }))
  .filter(story => story.title)
  .sort((a, b) => a.title.localeCompare(b.title));

function insert(nodes, parts, story) {
  const [head, ...rest] = parts;
  if (rest.length === 0) {
    nodes.push({ type: 'story', name: head, path: story.path });
    return;
  }
  let group = nodes.find(node => node.type === 'group' && node.name === head);
  if (!group) {
    group = { type: 'group', name: head, children: [] };
    nodes.push(group);
  }
  insert(group.children, rest, story);
}

// Sorts each level so groups come before individual stories, both alphabetically.
function sortNodes(nodes) {
  nodes.sort((a, b) => {
    if (a.type !== b.type) return a.type === 'group' ? -1 : 1;
    return a.name.localeCompare(b.name);
  });
  nodes.forEach(node => {
    if (node.type === 'group') sortNodes(node.children);
  });
  return nodes;
}

// Builds a nested tree from the slash-delimited story titles
// (e.g. "Components/Button" -> group "Components" > story "Button").
export function buildTree(items) {
  const roots = [];
  items.forEach(story => {
    const parts = story.title.split('/').map(part => part.trim());
    insert(roots, parts, story);
  });
  return sortNodes(roots);
}
